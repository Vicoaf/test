param(
    [Parameter(Mandatory = $true)]
    [string]$HarnessRoot
)

$ErrorActionPreference = "Stop"

function Read-JsonStrict {

    param([string]$Path)

    $Raw = [System.IO.File]::ReadAllText(
        $Path,
        [System.Text.UTF8Encoding]::new($false,$true)
    )

    return $Raw | ConvertFrom-Json
}

$CanonicalPath = Join-Path $HarnessRoot "canonical-smoke-request.json"

$PlanPaths = @(
    (Join-Path $HarnessRoot "claude-plan.json"),
    (Join-Path $HarnessRoot "codex-plan.json"),
    (Join-Path $HarnessRoot "antigravity-plan.json")
)

$Canonical = Read-JsonStrict -Path $CanonicalPath

if ($Canonical.case_id -ne "audit-internal-candidate") {
    throw "Unexpected canonical case."
}

if ($Canonical.safety.dry_run_only -ne $true) {
    throw "Canonical request is not dry-run only."
}

if ($Canonical.safety.provider_execution_allowed -ne $false) {
    throw "Provider execution unexpectedly allowed."
}

if ($Canonical.safety.prompt_sent -ne $false) {
    throw "Canonical request indicates prompt sent."
}

if ($Canonical.safety.model_call_requested -ne $false) {
    throw "Canonical request indicates model call."
}

$ExpectedProviders = @(
    "claude",
    "codex",
    "antigravity"
)

$SeenProviders = @()
$Passed = 0
$Failed = 0

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL PROVIDER DRY-RUN PLAN VALIDATION"
Write-Host "============================================================"

foreach ($PlanPath in $PlanPaths) {

    $Plan = Read-JsonStrict -Path $PlanPath
    $Errors = @()

    if ($ExpectedProviders -notcontains [string]$Plan.provider) {
        $Errors += "unexpected provider"
    }

    if ($Plan.adapter_execution_status -ne "not-executed") {
        $Errors += "adapter execution status is not not-executed"
    }

    if ($Plan.dry_run.only -ne $true) {
        $Errors += "dry_run.only must be true"
    }

    if ($Plan.dry_run.execute_allowed -ne $false) {
        $Errors += "execute_allowed must be false"
    }

    if ($Plan.dry_run.prompt_sent -ne $false) {
        $Errors += "prompt_sent must be false"
    }

    if ($Plan.dry_run.model_call_requested -ne $false) {
        $Errors += "model_call_requested must be false"
    }

    if ([string]::IsNullOrWhiteSpace([string]$Plan.executable)) {
        $Errors += "missing executable"
    }

    if (@($Plan.argv_template).Count -lt 1) {
        $Errors += "empty argv_template"
    }

    $ArgText = @($Plan.argv_template) -join " "

    foreach ($Dangerous in @($Plan.dangerous_flags_forbidden)) {

        if (
            -not [string]::IsNullOrWhiteSpace([string]$Dangerous) -and
            $ArgText.IndexOf(
                [string]$Dangerous,
                [System.StringComparison]::OrdinalIgnoreCase
            ) -ge 0
        ) {
            $Errors += "dangerous flag present: $Dangerous"
        }
    }

    if (
        $ArgText.IndexOf(
            "PRODUCTION",
            [System.StringComparison]::OrdinalIgnoreCase
        ) -ge 0
    ) {
        $Errors += "production marker found in invocation"
    }

    if ($Errors.Count -eq 0) {

        Write-Host "[PASS] $($Plan.provider) dry-run plan" -ForegroundColor Green
        $Passed++
    }
    else {

        Write-Host "[FAIL] $($Plan.provider) dry-run plan" -ForegroundColor Red

        foreach ($ErrorText in $Errors) {
            Write-Host "       $ErrorText"
        }

        $Failed++
    }

    $SeenProviders += [string]$Plan.provider
}

if (@($SeenProviders | Sort-Object -Unique).Count -ne 3) {
    throw "Expected three unique provider plans."
}

Write-Host ""
Write-Host "DRY_RUN_PLANS=3"
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"

if ($Failed -gt 0) {
    throw "DRY-RUN PLAN VALIDATION FAILURE"
}

Write-Host ""
Write-Host "[PASS] ALL DRY-RUN PLANS VALID" -ForegroundColor Green