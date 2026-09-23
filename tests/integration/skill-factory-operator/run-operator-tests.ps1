param(
    [Parameter(Mandatory = $true)][string]$AgencyRoot,
    [Parameter(Mandatory = $true)][string]$OperatorPath,
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [Parameter(Mandatory = $true)][string]$TestsRoot
)

$ErrorActionPreference = "Stop"

$CasesPath = Join-Path $TestsRoot "operator-cases.json"

foreach ($Path in @($OperatorPath,$ConfigPath,$CasesPath)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ("Missing operator test input: " + $Path)
    }
}

$ParsedCases = Get-Content -LiteralPath $CasesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Cases = @()
foreach ($Item in @($ParsedCases)) {
    if ($Item -is [System.Array]) {
        foreach ($Nested in $Item) { $Cases += $Nested }
    }
    else { $Cases += $Item }
}

$Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

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

function Invoke-Operator {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $PreviousPreference = $ErrorActionPreference

    try {
        $ErrorActionPreference = "Continue"

        $Output = @(
            & powershell.exe `
                -NoProfile `
                -NonInteractive `
                -ExecutionPolicy Bypass `
                -File $OperatorPath `
                @Arguments `
                2>&1
        )

        $ExitCode = [int]$LASTEXITCODE
        $Text = @(
            $Output |
            ForEach-Object { [string]$_ }
        ) -join [Environment]::NewLine

        return [pscustomobject]@{
            exit_code = $ExitCode
            stdout = [string]$Text
            stderr = ""
        }
    }
    finally {
        $ErrorActionPreference = $PreviousPreference
    }
}

$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("proxtel-operator-tests-" + [guid]::NewGuid().ToString("N"))
$Workspace = Join-Path $TempRoot "runs"
$ExternalFile = Join-Path $TempRoot "external-skill.txt"

New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
[System.IO.File]::WriteAllText($ExternalFile,"external test source",(New-Object System.Text.UTF8Encoding($false)))

try {
    $Common = @("-AgencyRoot",$AgencyRoot,"-ConfigPath",$ConfigPath,"-WorkspaceRoot",$Workspace)

    $Status = Invoke-Operator -Arguments (@("-Mode","Status") + $Common)
    Check -Name "status-exit-0" -Condition ($Status.exit_code -eq 0)
    Check -Name "status-ready" -Condition ($Status.stdout.Contains("OPERATOR_STATUS=READY"))
    Check -Name "status-workflow-approved" -Condition ($Status.stdout.Contains("WORKFLOW_STATE=approved"))
    Check -Name "status-creator-approved" -Condition ($Status.stdout.Contains("CREATOR_STATE=approved"))
    Check -Name "status-auditor-approved" -Condition ($Status.stdout.Contains("AUDITOR_STATE=approved"))
    Check -Name "status-no-workspace-write" -Condition ($Status.stdout.Contains("WORKSPACE_WRITE_PERFORMED=NO"))

    $PlanCreate = Invoke-Operator -Arguments (@("-Mode","Plan","-Action","Create","-Area","development","-Request","Create reusable Laravel audit skill.") + $Common)
    Check -Name "plan-create-exit-0" -Condition ($PlanCreate.exit_code -eq 0)
    Check -Name "plan-create-source-type" -Condition ($PlanCreate.stdout.Contains("PLAN_SOURCE_TYPE=internal-new"))
    Check -Name "plan-create-next-owner" -Condition ($PlanCreate.stdout.Contains("PLAN_NEXT_OWNER=proxtel-skill-creator"))
    Check -Name "plan-create-no-write" -Condition ($PlanCreate.stdout.Contains("WORKSPACE_WRITE_PERFORMED=NO"))

    $PlanUpdateBad = Invoke-Operator -Arguments (@("-Mode","Plan","-Action","Update","-Request","Update existing skill.") + $Common)
    Check -Name "plan-update-without-subject-fails" -Condition ($PlanUpdateBad.exit_code -ne 0)

    $PlanUpdate = Invoke-Operator -Arguments (@("-Mode","Plan","-Action","Update","-SubjectId","proxtel-skill-example","-Request","Update existing skill.") + $Common)
    Check -Name "plan-update-exit-0" -Condition ($PlanUpdate.exit_code -eq 0)
    Check -Name "plan-update-source-type" -Condition ($PlanUpdate.stdout.Contains("PLAN_SOURCE_TYPE=internal-update"))

    $PlanExternalBad = Invoke-Operator -Arguments (@("-Mode","Plan","-Action","AuditExternal","-Request","Audit external skill.") + $Common)
    Check -Name "plan-external-without-source-fails" -Condition ($PlanExternalBad.exit_code -ne 0)

    $PlanExternal = Invoke-Operator -Arguments (@("-Mode","Plan","-Action","AuditExternal","-Request","Audit external skill.","-SourcePath",$ExternalFile) + $Common)
    Check -Name "plan-external-exit-0" -Condition ($PlanExternal.exit_code -eq 0)
    Check -Name "plan-external-quarantine" -Condition ($PlanExternal.stdout.Contains("PLAN_QUARANTINE_REQUIRED=True"))

    $StartCreate = Invoke-Operator -Arguments (@("-Mode","Start","-Action","Create","-Area","development","-Request","Create reusable Laravel audit skill.","-RunId","test-create") + $Common)
    Check -Name "start-create-exit-0" -Condition ($StartCreate.exit_code -eq 0)
    Check -Name "start-create-marker" -Condition ($StartCreate.stdout.Contains("RUN_CREATED=True"))

    $CreateRunJson = Join-Path $Workspace "test-create\run.json"
    $CreateRequestMd = Join-Path $Workspace "test-create\request.md"
    Check -Name "start-create-run-json-exists" -Condition (Test-Path -LiteralPath $CreateRunJson -PathType Leaf)
    Check -Name "start-create-request-md-exists" -Condition (Test-Path -LiteralPath $CreateRequestMd -PathType Leaf)

    $CreateRun = Get-Content -LiteralPath $CreateRunJson -Raw -Encoding UTF8 | ConvertFrom-Json
    Check -Name "start-create-state-intake" -Condition ([string]$CreateRun.state -ceq "intake")
    Check -Name "start-create-action" -Condition ([string]$CreateRun.action -ceq "Create")
    Check -Name "start-create-workflow-hash" -Condition (-not [string]::IsNullOrWhiteSpace([string]$CreateRun.workflow.sha256))
    Check -Name "start-create-creator-hash" -Condition (-not [string]::IsNullOrWhiteSpace([string]$CreateRun.creator.sha256))
    Check -Name "start-create-auditor-hash" -Condition (-not [string]::IsNullOrWhiteSpace([string]$CreateRun.auditor.sha256))
    Check -Name "start-create-provider-disabled" -Condition (-not [bool]$CreateRun.provider_execution_allowed)
    Check -Name "start-create-auto-retry-disabled" -Condition (-not [bool]$CreateRun.automatic_live_retry_allowed)
    Check -Name "start-create-repo-mutation-disabled" -Condition (-not [bool]$CreateRun.repository_mutation_allowed)

    $Show = Invoke-Operator -Arguments (@("-Mode","Show","-RunId","test-create") + $Common)
    Check -Name "show-exit-0" -Condition ($Show.exit_code -eq 0)
    Check -Name "show-run-found" -Condition ($Show.stdout.Contains("RUN_FOUND=True"))
    Check -Name "show-run-id" -Condition ($Show.stdout.Contains("RUN_ID=test-create"))

    $Duplicate = Invoke-Operator -Arguments (@("-Mode","Start","-Action","Create","-Request","Duplicate.","-RunId","test-create") + $Common)
    Check -Name "duplicate-run-id-fails" -Condition ($Duplicate.exit_code -ne 0)

    $StartExternal = Invoke-Operator -Arguments (@("-Mode","Start","-Action","AuditExternal","-Request","Audit external skill.","-SourcePath",$ExternalFile,"-RunId","test-external") + $Common)
    Check -Name "start-external-exit-0" -Condition ($StartExternal.exit_code -eq 0)

    $ExternalRunJson = Join-Path $Workspace "test-external\run.json"
    $ExternalSnapshot = Join-Path $Workspace "test-external\quarantine\external-skill.txt"
    Check -Name "external-run-json-exists" -Condition (Test-Path -LiteralPath $ExternalRunJson -PathType Leaf)
    Check -Name "external-snapshot-exists" -Condition (Test-Path -LiteralPath $ExternalSnapshot -PathType Leaf)

    $ExternalRun = Get-Content -LiteralPath $ExternalRunJson -Raw -Encoding UTF8 | ConvertFrom-Json
    Check -Name "external-source-type" -Condition ([string]$ExternalRun.source_type -ceq "external-source")
    Check -Name "external-source-not-executed" -Condition (-not [bool]$ExternalRun.source_snapshot.executed)
    Check -Name "external-source-hash-present" -Condition (-not [string]::IsNullOrWhiteSpace([string]$ExternalRun.source_snapshot.sha256))

    $CaseIds = @($Cases | ForEach-Object { [string]$_.id })
    Check -Name "cases=12" -Condition ($Cases.Count -eq 12)
    Check -Name "case-no-provider-execution" -Condition ($CaseIds -contains "no-provider-execution")
    Check -Name "case-no-auto-live-retry" -Condition ($CaseIds -contains "no-auto-live-retry")
    Check -Name "config-provider-execution-false" -Condition (-not [bool]$Config.provider_execution)
    Check -Name "config-auto-live-retry-false" -Condition (-not [bool]$Config.automatic_live_retry)
}
finally {
    if (Test-Path -LiteralPath $TempRoot -PathType Container) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host ("OPERATOR_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)

if ($Failed -gt 0) {
    throw "SKILL FACTORY OPERATOR TEST FAILURE"
}

Write-Host ""
Write-Host "[PASS] ALL SKILL FACTORY OPERATOR TESTS PASSED" -ForegroundColor Green