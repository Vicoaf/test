param(
    [Parameter(Mandatory = $true)]
    [string]$TestsRoot
)

$ErrorActionPreference = "Stop"

$CasesPath = Join-Path $TestsRoot "behavioral-cases.json"
$SchemaPath = Join-Path $TestsRoot "behavioral-response.schema.json"
$RubricPath = Join-Path $TestsRoot "behavioral-rubric.md"

function Read-Utf8Strict {

    param([string]$Path)

    return [System.IO.File]::ReadAllText(
        $Path,
        [System.Text.UTF8Encoding]::new($false,$true)
    )
}

foreach ($Path in @($CasesPath,$SchemaPath,$RubricPath)) {

    if (-not (Test-Path $Path)) {
        throw "Missing benchmark file: $Path"
    }

    $Item = Get-Item -LiteralPath $Path -Force

    if ($Item.Length -eq 0) {
        throw "Empty benchmark file: $Path"
    }
}

$CasesRaw = Read-Utf8Strict -Path $CasesPath
$SchemaRaw = Read-Utf8Strict -Path $SchemaPath
$RubricRaw = Read-Utf8Strict -Path $RubricPath

$CasesParsed = $CasesRaw | ConvertFrom-Json
$Schema = $SchemaRaw | ConvertFrom-Json

$Cases = @()

foreach ($Item in @($CasesParsed)) {

    if ($Item -is [System.Array]) {

        foreach ($Nested in $Item) {
            $Cases += $Nested
        }
    }

    if ($Item -isnot [System.Array]) {
        $Cases += $Item
    }
}

if ($Cases.Count -ne 16) {
    throw "Expected 16 behavioral cases. Found=$($Cases.Count)"
}

$Ids = @($Cases | ForEach-Object { [string]$_.id })

if (@($Ids | Sort-Object -Unique).Count -ne $Ids.Count) {
    throw "Duplicate behavioral case ID."
}

$AllowedCategories = @(
    "trigger",
    "adversarial",
    "authority",
    "metrics",
    "evaluation",
    "non-trigger",
    "boundary"
)

$AllowedActions = @(
    "AUDIT",
    "REQUEST-EVIDENCE",
    "BLOCK",
    "ROUTE-CREATOR",
    "ROUTE-IMPLEMENTATION",
    "NOT-APPLICABLE"
)

$AllowedGates = @(
    "NOT-RUN",
    "NOT-APPLICABLE",
    "PASS",
    "WARN",
    "FAIL",
    "CRITICAL"
)

$AllowedDecisions = @(
    "PENDING",
    "APPROVED",
    "ADAPT",
    "REFERENCE-ONLY",
    "REJECTED",
    "NOT-APPLICABLE"
)

$Passed = 0
$Failed = 0

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL AUDITOR BEHAVIORAL SUITE VALIDATION"
Write-Host "============================================================"

foreach ($Case in $Cases) {

    $Errors = @()

    if ([string]::IsNullOrWhiteSpace([string]$Case.id)) {
        $Errors += "missing id"
    }

    if ($AllowedCategories -notcontains [string]$Case.category) {
        $Errors += "invalid category"
    }

    if ([string]::IsNullOrWhiteSpace([string]$Case.prompt)) {
        $Errors += "missing prompt"
    }

    if ($null -eq $Case.expected) {
        $Errors += "missing expected"
    }
    else {

        if ($Case.expected.auditor_should_engage -isnot [bool]) {
            $Errors += "auditor_should_engage must be bool"
        }

        if ($AllowedActions -notcontains [string]$Case.expected.primary_action) {
            $Errors += "invalid primary_action"
        }

        if ($Case.expected.execute_allowed -isnot [bool]) {
            $Errors += "execute_allowed must be bool"
        }

        foreach ($Gate in @($Case.expected.safe_to_execute_allowed)) {

            if ($AllowedGates -notcontains [string]$Gate) {
                $Errors += "invalid safe_to_execute_allowed=$Gate"
            }
        }

        foreach ($Decision in @($Case.expected.decision_allowed)) {

            if ($AllowedDecisions -notcontains [string]$Decision) {
                $Errors += "invalid decision_allowed=$Decision"
            }
        }

        foreach ($Decision in @($Case.expected.decision_forbidden)) {

            if ($AllowedDecisions -notcontains [string]$Decision) {
                $Errors += "invalid decision_forbidden=$Decision"
            }
        }

        if ($Case.expected.evidence_required -isnot [bool]) {
            $Errors += "evidence_required must be bool"
        }

        if ([int]$Case.expected.minimum_unknowns -lt 0) {
            $Errors += "minimum_unknowns cannot be negative"
        }

        if ($Case.expected.actual_tokens_must_be_null -isnot [bool]) {
            $Errors += "actual_tokens_must_be_null must be bool"
        }
    }

    if ($Errors.Count -eq 0) {

        Write-Host "[PASS] $($Case.id) | category=$($Case.category)" -ForegroundColor Green
        $Passed++
    }
    else {

        Write-Host "[FAIL] $($Case.id)" -ForegroundColor Red

        foreach ($ErrorText in $Errors) {
            Write-Host "       $ErrorText"
        }

        $Failed++
    }
}

if ($Schema.properties.primary_action.enum.Count -ne 6) {
    throw "Response schema primary_action enum mismatch."
}

if ($Schema.properties.decision.enum.Count -ne 6) {
    throw "Response schema decision enum mismatch."
}

if ($Schema.properties.safe_to_execute.enum.Count -ne 6) {
    throw "Response schema safe_to_execute enum mismatch."
}

if ($RubricRaw.IndexOf("Behavioral PASS != APPROVED",[System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
    throw "Rubric missing approval invariant."
}

Write-Host ""
Write-Host "BEHAVIORAL_CASES=$($Cases.Count)"
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"

if ($Failed -gt 0) {
    throw "BEHAVIORAL SUITE VALIDATION FAILURE"
}

Write-Host ""
Write-Host "[PASS] BEHAVIORAL SUITE STRUCTURE VALID" -ForegroundColor Green