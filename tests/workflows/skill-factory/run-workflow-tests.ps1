param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowRoot,

    [Parameter(Mandatory = $true)]
    [string]$TestsRoot,

    [Parameter(Mandatory = $true)]
    [string]$SchemaPath
)

$ErrorActionPreference = "Stop"

$WorkflowJsonPath = Join-Path $WorkflowRoot "workflow.json"
$WorkflowMdPath = Join-Path $WorkflowRoot "WORKFLOW.md"
$CasesPath = Join-Path $TestsRoot "workflow-cases.json"

foreach ($Path in @($WorkflowJsonPath,$WorkflowMdPath,$CasesPath,$SchemaPath)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ("Missing workflow test input: " + $Path)
    }
}

$Workflow = Get-Content -LiteralPath $WorkflowJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Schema = Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
$WorkflowText = [System.IO.File]::ReadAllText($WorkflowMdPath,[System.Text.Encoding]::UTF8)
$ParsedCases = Get-Content -LiteralPath $CasesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Cases = @()
foreach ($Item in @($ParsedCases)) {
    if ($Item -is [System.Array]) {
        foreach ($Nested in $Item) { $Cases += $Nested }
    }
    else { $Cases += $Item }
}

$Passed = 0
$Failed = 0

function Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][bool]$Condition
    )
    if ($Condition) {
        Write-Host ("[PASS] " + $Name)
        $script:Passed++
    }
    else {
        Write-Host ("[FAIL] " + $Name)
        $script:Failed++
    }
}

$StepIds = @($Workflow.steps | ForEach-Object { [string]$_.id })
$Decisions = @($Workflow.final_decisions | ForEach-Object { [string]$_.decision })
$CaseIds = @($Cases | ForEach-Object { [string]$_.id })
$ApprovedDecision = @($Workflow.final_decisions | Where-Object { [string]$_.decision -ceq "APPROVED" })
$AdaptDecision = @($Workflow.final_decisions | Where-Object { [string]$_.decision -ceq "ADAPT" })

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL SKILL FACTORY WORKFLOW TESTS"
Write-Host "============================================================"

Check -Name "schema-parse" -Condition ([string]$Schema.title -ceq "PROXTEL Workflow Contract")
Check -Name "kind=proxtel-workflow" -Condition ([string]$Workflow.kind -ceq "proxtel-workflow")
Check -Name "id=skill-factory-operational" -Condition ([string]$Workflow.id -ceq "skill-factory-operational")
Check -Name "area=core" -Condition ([string]$Workflow.area -ceq "core")
Check -Name "version=1.0.0" -Condition ([string]$Workflow.version -ceq "1.0.0")
Check -Name "status=approved" -Condition ([string]$Workflow.status -ceq "approved")
Check -Name "provider-neutral=true" -Condition ([bool]$Workflow.provider_neutral)
Check -Name "orchestration-only" -Condition ([string]$Workflow.execution_mode -ceq "orchestration-only")
Check -Name "steps=11" -Condition (@($Workflow.steps).Count -eq 11)
Check -Name "cases=16" -Condition ($Cases.Count -eq 16)
Check -Name "creator-step-present" -Condition ($StepIds -contains "creator-build-candidate")
Check -Name "auditor-step-present" -Condition ($StepIds -contains "auditor-static-review")
Check -Name "sandbox-step-present" -Condition ($StepIds -contains "sandbox-and-evaluation-if-applicable")
Check -Name "final-decision-step-present" -Condition ($StepIds -contains "independent-final-decision")
Check -Name "final-decisions=4" -Condition (@($Workflow.final_decisions).Count -eq 4)
Check -Name "approved-decision-present" -Condition ($Decisions -contains "APPROVED")
Check -Name "adapt-decision-present" -Condition ($Decisions -contains "ADAPT")
Check -Name "reference-only-decision-present" -Condition ($Decisions -contains "REFERENCE-ONLY")
Check -Name "rejected-decision-present" -Condition ($Decisions -contains "REJECTED")
Check -Name "approved-zero-blockers-rule" -Condition ($ApprovedDecision.Count -eq 1 -and [bool]$ApprovedDecision[0].promotion_allowed -and ([string]$ApprovedDecision[0].required_condition).Contains("blocking_issue_count=0"))
Check -Name "adapt-no-promotion" -Condition ($AdaptDecision.Count -eq 1 -and -not [bool]$AdaptDecision[0].promotion_allowed)
Check -Name "creator-self-approval-forbidden" -Condition ([bool]$Workflow.safety.creator_self_approval_forbidden)
Check -Name "external-direct-execution-forbidden" -Condition ([bool]$Workflow.safety.external_source_direct_execution_forbidden)
Check -Name "production-first-forbidden" -Condition ([bool]$Workflow.safety.production_first_forbidden)
Check -Name "silent-dependency-install-forbidden" -Condition ([bool]$Workflow.safety.silent_dependency_install_forbidden)
Check -Name "dangerous-bypass-forbidden" -Condition ([bool]$Workflow.safety.dangerous_permission_bypass_forbidden)
Check -Name "automatic-live-retry-forbidden" -Condition ([bool]$Workflow.safety.live_retry_automatic_forbidden)
Check -Name "static-pass-not-approved" -Condition ([bool]$Workflow.safety.static_pass_not_approved)
Check -Name "transaction-required" -Condition ([bool]$Workflow.transactionality.required)
Check -Name "transaction-pattern" -Condition ([string]$Workflow.transactionality.pattern -ceq "staging -> validation -> promote")
Check -Name "partial-init-invalid" -Condition (-not [bool]$Workflow.transactionality.partial_initialization_valid)
Check -Name "case-external-source" -Condition ($CaseIds -contains "external-source")
Check -Name "case-consumed-live-failure" -Condition ($CaseIds -contains "consumed-live-failure")
Check -Name "case-paid-api-route" -Condition ($CaseIds -contains "paid-api-route")
Check -Name "manual-creator-auditor-separation" -Condition ($WorkflowText.Contains("Creator != Auditor."))
Check -Name "manual-external-lifecycle" -Condition ($WorkflowText.Contains("SOURCE -> QUARANTINE -> STATIC AUDIT"))
Check -Name "manual-no-auto-retry" -Condition ($WorkflowText.Contains("Automatic retry of a consumed live model attempt is forbidden."))

Write-Host ""
Write-Host ("WORKFLOW_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)

if ($Failed -gt 0) {
    throw "SKILL FACTORY WORKFLOW TEST FAILURE"
}

Write-Host ""
Write-Host "[PASS] ALL SKILL FACTORY WORKFLOW TESTS PASSED" -ForegroundColor Green