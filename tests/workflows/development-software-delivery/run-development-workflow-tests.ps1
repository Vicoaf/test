param(
    [Parameter(Mandatory = $true)][string]$WorkflowRoot,
    [Parameter(Mandatory = $true)][string]$SchemaPath,
    [Parameter(Mandatory = $true)][string]$TestsRoot
)

$ErrorActionPreference = "Stop"
$WorkflowPath = Join-Path $WorkflowRoot "workflow.json"
$ManualPath = Join-Path $WorkflowRoot "WORKFLOW.md"
$CasesPath = Join-Path $TestsRoot "workflow-cases.json"

foreach ($Path in @($WorkflowPath,$ManualPath,$SchemaPath,$CasesPath)) { if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw ("Missing: " + $Path) } }

$Workflow = Get-Content -LiteralPath $WorkflowPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Schema = Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Manual = [System.IO.File]::ReadAllText($ManualPath,[System.Text.Encoding]::UTF8)
$ParsedCases = Get-Content -LiteralPath $CasesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Cases = @()
foreach ($Item in @($ParsedCases)) { if ($Item -is [System.Array]) { foreach ($Nested in $Item) { $Cases += $Nested } } else { $Cases += $Item } }

$Passed = 0
$Failed = 0
function Check { param([string]$Name,[bool]$Condition) if ($Condition) { Write-Host ("[PASS] " + $Name); $script:Passed++ } else { Write-Host ("[FAIL] " + $Name); $script:Failed++ } }

$StepIds = @($Workflow.steps | ForEach-Object { [string]$_.id })
$Decisions = @($Workflow.final_decisions | ForEach-Object { [string]$_.decision })

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL DEVELOPMENT WORKFLOW TESTS"
Write-Host "============================================================"

Check "schema-kind" ([string]$Schema.properties.kind.const -ceq "proxtel-workflow")
Check "workflow-kind" ([string]$Workflow.kind -ceq "proxtel-workflow")
Check "workflow-id" ([string]$Workflow.id -ceq "development-software-delivery")
Check "workflow-area" ([string]$Workflow.area -ceq "development")
Check "workflow-version" ([string]$Workflow.version -ceq "1.0.0")
Check "workflow-approved" ([string]$Workflow.status -ceq "approved")
Check "workflow-provider-neutral" ([bool]$Workflow.provider_neutral)
Check "workflow-with-tools" ([string]$Workflow.execution_mode -ceq "orchestration-with-tools")
Check "steps=10" (@($Workflow.steps).Count -eq 10)
Check "step-intake" ($StepIds -contains "intake-and-scope")
Check "step-readonly-discovery" ($StepIds -contains "read-only-project-discovery")
Check "step-risk" ($StepIds -contains "risk-and-change-classification")
Check "step-design" ($StepIds -contains "design-and-plan")
Check "step-local-implementation" ($StepIds -contains "local-implementation")
Check "step-deterministic-validation" ($StepIds -contains "deterministic-validation")
Check "step-web-quality" ($StepIds -contains "web-quality-validation")
Check "step-independent-review" ($StepIds -contains "independent-review-if-needed")
Check "step-documentation" ($StepIds -contains "documentation-and-handoff")
Check "step-release-gate" ($StepIds -contains "release-readiness-gate")
Check "decisions=4" (@($Workflow.final_decisions).Count -eq 4)
Check "decision-ready" ($Decisions -contains "READY")
Check "decision-changes-required" ($Decisions -contains "CHANGES-REQUIRED")
Check "decision-blocked" ($Decisions -contains "BLOCKED")
Check "decision-deferred" ($Decisions -contains "DEFERRED")
Check "discovery-first" ([bool]$Workflow.safety.discovery_first)
Check "local-first" ([bool]$Workflow.safety.local_first)
Check "production-first-forbidden" ([bool]$Workflow.safety.production_first_forbidden)
Check "auto-commit-forbidden" ([bool]$Workflow.safety.automatic_commit_forbidden)
Check "auto-push-forbidden" ([bool]$Workflow.safety.automatic_push_forbidden)
Check "auto-deploy-forbidden" ([bool]$Workflow.safety.automatic_deploy_forbidden)
Check "destructive-prod-db-forbidden" ([bool]$Workflow.safety.destructive_production_db_forbidden)
Check "silent-dependency-forbidden" ([bool]$Workflow.safety.silent_dependency_install_forbidden)
Check "secrets-forbidden" ([bool]$Workflow.safety.secrets_in_artifacts_forbidden)
Check "auto-live-retry-forbidden" ([bool]$Workflow.safety.automatic_live_retry_forbidden)
Check "external-code-forbidden" ([bool]$Workflow.safety.unreviewed_external_code_execution_forbidden)
Check "transaction-required" ([bool]$Workflow.transactionality.required)
Check "partial-init-invalid" (-not [bool]$Workflow.transactionality.partial_initialization_valid)
Check "manual-ready-not-deploy" ($Manual.Contains("READY does not mean automatic deployment."))
Check "cases=12" ($Cases.Count -eq 12)

Write-Host ""
Write-Host ("WORKFLOW_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)
if ($Failed -gt 0) { throw "DEVELOPMENT WORKFLOW TEST FAILURE" }
Write-Host "[PASS] ALL DEVELOPMENT WORKFLOW TESTS PASSED" -ForegroundColor Green