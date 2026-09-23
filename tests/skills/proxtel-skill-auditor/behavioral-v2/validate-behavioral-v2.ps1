param(
    [Parameter(Mandatory = $true)]
    [string]$AuditorRoot,

    [Parameter(Mandatory = $true)]
    [string]$SuiteRoot
)

$ErrorActionPreference = "Stop"

function Read-JsonStrict {
    param([string]$Path)

    $Text = [System.IO.File]::ReadAllText(
        $Path,
        [System.Text.UTF8Encoding]::new($false,$true)
    )

    return $Text | ConvertFrom-Json
}

function Test-ResponseSemantic {
    param($Response)

    $Errors = @()

    $ValidStatuses = @(
        "NOT-APPLICABLE",
        "PENDING",
        "FINAL"
    )

    $FinalDecisions = @(
        "APPROVED",
        "ADAPT",
        "REFERENCE-ONLY",
        "REJECTED"
    )

    if ($ValidStatuses -notcontains [string]$Response.audit_status) {
        $Errors += "invalid audit_status"
    }

    if ($Response.audit_status -eq "PENDING") {
        if ($null -ne $Response.final_decision) {
            $Errors += "PENDING requires final_decision=null"
        }
    }

    if ($Response.audit_status -eq "FINAL") {
        if ($FinalDecisions -notcontains [string]$Response.final_decision) {
            $Errors += "FINAL requires one valid final decision"
        }
    }

    if ($Response.audit_status -eq "NOT-APPLICABLE") {
        if ($null -ne $Response.final_decision) {
            $Errors += "NOT-APPLICABLE requires final_decision=null"
        }
    }

    if ([string]$Response.final_decision -eq "PENDING") {
        $Errors += "PENDING must never be a final_decision"
    }

    if ($Response.token_measurement -eq "actual") {
        if ($null -eq $Response.actual_tokens) {
            $Errors += "actual token measurement requires actual_tokens"
        }
    }
    else {
        if ($null -ne $Response.actual_tokens) {
            $Errors += "non-actual token measurement requires actual_tokens=null"
        }
    }

    return @($Errors)
}

$SkillPath = Join-Path $AuditorRoot "SKILL.md"
$MethodologyPath = Join-Path $AuditorRoot "references\audit-methodology.md"
$CasesPath = Join-Path $SuiteRoot "benchmark-cases-v2.json"
$SchemaPath = Join-Path $SuiteRoot "behavioral-response-v2.schema.json"
$FixtureRoot = Join-Path $SuiteRoot "fixtures\synthetic-safe-skill"

$Required = @(
    $SkillPath,
    $MethodologyPath,
    $CasesPath,
    $SchemaPath,
    (Join-Path $FixtureRoot "SKILL.md"),
    (Join-Path $FixtureRoot "fixture.json"),
    (Join-Path $FixtureRoot "evidence-incomplete.json"),
    (Join-Path $FixtureRoot "evidence-complete.json")
)

foreach ($Path in $Required) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing v2 artifact: $Path"
    }
}

$Skill = [System.IO.File]::ReadAllText(
    $SkillPath,
    [System.Text.Encoding]::UTF8
)

$Methodology = [System.IO.File]::ReadAllText(
    $MethodologyPath,
    [System.Text.Encoding]::UTF8
)

if ($Skill -notmatch "(?i)PENDING.*interim") {
    throw "SKILL.md does not define PENDING as interim."
}

if ($Methodology -notmatch "(?i)PENDING.*interim audit status") {
    throw "Methodology does not define PENDING as interim."
}

$Schema = Read-JsonStrict -Path $SchemaPath

$AuditStatuses = @(
    $Schema.properties.audit_status.enum
)

foreach ($Status in @("NOT-APPLICABLE","PENDING","FINAL")) {
    if ($AuditStatuses -notcontains $Status) {
        throw "Response schema missing audit status $Status"
    }
}

$FinalEnum = @(
    $Schema.properties.final_decision.enum
)

foreach ($Decision in @("APPROVED","ADAPT","REFERENCE-ONLY","REJECTED")) {
    if ($FinalEnum -notcontains $Decision) {
        throw "Response schema missing final decision $Decision"
    }
}

if ($FinalEnum -contains "PENDING") {
    throw "PENDING must not appear in final_decision enum."
}

$CasesParsed = Read-JsonStrict -Path $CasesPath
$Cases = @($CasesParsed)

if ($Cases.Count -ne 3) {
    throw "Expected exactly three v2 benchmark cases."
}

$Ids = @($Cases | ForEach-Object { $_.id })

if (@($Ids | Sort-Object -Unique).Count -ne 3) {
    throw "V2 benchmark case IDs must be unique."
}

$Layers = @($Cases | ForEach-Object { $_.layer })

foreach ($Layer in @("routing","evidence-request","full-audit")) {
    if ($Layers -notcontains $Layer) {
        throw "Missing benchmark layer: $Layer"
    }
}

$Routing = @(
    $Cases | Where-Object { $_.layer -eq "routing" }
)[0]

if ($null -ne $Routing.candidate_fixture) {
    throw "Routing case must not bind a candidate fixture."
}

if (@($Routing.graded_fields) -contains "final_decision") {
    throw "Routing case must not grade final_decision."
}

$EvidenceCase = @(
    $Cases | Where-Object { $_.layer -eq "evidence-request" }
)[0]

if ($EvidenceCase.expected.audit_status -ne "PENDING") {
    throw "Evidence-request case must be PENDING."
}

if ($null -ne $EvidenceCase.expected.final_decision) {
    throw "Evidence-request case must have no final decision."
}

$FullCase = @(
    $Cases | Where-Object { $_.layer -eq "full-audit" }
)[0]

if ($FullCase.expected.audit_status -ne "FINAL") {
    throw "Full-audit case must be FINAL."
}

if ($FullCase.expected.final_decision -ne "APPROVED") {
    throw "Synthetic full-audit fixture must expect APPROVED."
}

$Fixture = Read-JsonStrict -Path (Join-Path $FixtureRoot "fixture.json")

if ($Fixture.id -eq "proxtel-skill-auditor") {
    throw "Synthetic candidate must be distinct from Auditor."
}

if ($Fixture.auditor_under_test -ne $false) {
    throw "Fixture must not identify Auditor as candidate."
}

$Incomplete = Read-JsonStrict -Path (Join-Path $FixtureRoot "evidence-incomplete.json")
$Complete = Read-JsonStrict -Path (Join-Path $FixtureRoot "evidence-complete.json")

if ($Incomplete.evidence_state -ne "INCOMPLETE") {
    throw "Incomplete evidence fixture invalid."
}

if ($Incomplete.final_decision_supported -ne $false) {
    throw "Incomplete evidence must not support final decision."
}

if ($Incomplete.gates.safe_to_execute -ne "NOT-RUN") {
    throw "Incomplete evidence must leave safe-to-execute NOT-RUN."
}

if ($Complete.evidence_state -ne "COMPLETE") {
    throw "Complete evidence fixture invalid."
}

if ($Complete.final_decision_supported -ne $true) {
    throw "Complete evidence must support final decision."
}

foreach ($Gate in $Complete.gates.PSObject.Properties) {
    if (@("PASS","NOT-APPLICABLE") -notcontains [string]$Gate.Value) {
        throw "Complete fixture contains non-passing gate: $($Gate.Name)=$($Gate.Value)"
    }
}

$ResponseCases = @(
    @{ File = "valid-pending.json"; Expected = $true },
    @{ File = "valid-final.json"; Expected = $true },
    @{ File = "invalid-pending-with-final.json"; Expected = $false },
    @{ File = "invalid-final-without-decision.json"; Expected = $false }
)

$Passed = 0
$Failed = 0

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL AUDITOR BEHAVIORAL V2 VALIDATION"
Write-Host "============================================================"

foreach ($ResponseCase in $ResponseCases) {

    $ResponsePath = Join-Path $SuiteRoot ("contract-fixtures\" + $ResponseCase.File)
    $Response = Read-JsonStrict -Path $ResponsePath
    $Errors = @(Test-ResponseSemantic -Response $Response)
    $Actual = ($Errors.Count -eq 0)

    if ($Actual -eq [bool]$ResponseCase.Expected) {
        Write-Host "[PASS] $($ResponseCase.File) | expected=$($ResponseCase.Expected) actual=$Actual" -ForegroundColor Green
        $Passed++
    }
    else {
        Write-Host "[FAIL] $($ResponseCase.File) | expected=$($ResponseCase.Expected) actual=$Actual" -ForegroundColor Red

        foreach ($ErrorText in $Errors) {
            Write-Host "       $ErrorText"
        }

        $Failed++
    }
}

Write-Host ""
Write-Host "V2_BENCHMARK_CASES=3"
Write-Host "ROUTING_CASES=1"
Write-Host "EVIDENCE_REQUEST_CASES=1"
Write-Host "FULL_AUDIT_CASES=1"
Write-Host "V2_RESPONSE_CASES=4"
Write-Host "V2_RESPONSE_PASSED=$Passed"
Write-Host "V2_RESPONSE_FAILED=$Failed"
Write-Host "SYNTHETIC_CANDIDATE_DISTINCT=YES"
Write-Host "PENDING_INTERIM_STATUS=PASS"
Write-Host "FINAL_DECISIONS=4"

if ($Failed -gt 0) {
    throw "Behavioral v2 response contract validation failed."
}

Write-Host ""
Write-Host "[PASS] BEHAVIORAL V2 ARCHITECTURE VALID" -ForegroundColor Green