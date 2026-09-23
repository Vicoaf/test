param(
    [Parameter(Mandatory = $true)]
    [string]$AuditorRoot,

    [Parameter(Mandatory = $true)]
    [string]$TestsRoot
)

$ErrorActionPreference = "Stop"

function Read-Utf8Strict {

    param([string]$Path)

    return [System.IO.File]::ReadAllText(
        $Path,
        [System.Text.UTF8Encoding]::new($false,$true)
    )
}

$SkillPath = Join-Path $AuditorRoot "SKILL.md"
$ContractPath = Join-Path $AuditorRoot "skill.json"
$MethodPath = Join-Path $AuditorRoot "references\audit-methodology.md"
$CasesPath = Join-Path $TestsRoot "semantic-cases.json"

$SkillText = Read-Utf8Strict -Path $SkillPath
$MethodText = Read-Utf8Strict -Path $MethodPath
$ContractText = Read-Utf8Strict -Path $ContractPath
$CasesText = Read-Utf8Strict -Path $CasesPath

$Contract = $ContractText | ConvertFrom-Json
$CasesParsed = $CasesText | ConvertFrom-Json

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

if ($Cases.Count -ne 20) {
    throw "Expected 20 semantic cases. Found=$($Cases.Count)"
}

$UseWhenText = @($Contract.purpose.use_when) -join "`n"
$DoNotUseText = @($Contract.purpose.do_not_use_when) -join "`n"

$SourceMap = @{
    "skill"                    = $SkillText
    "methodology"              = $MethodText
    "contract.use_when"        = $UseWhenText
    "contract.do_not_use_when" = $DoNotUseText
}

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL AUDITOR SEMANTIC POLICY TESTS"
Write-Host "============================================================"

# Core authority invariants

if ($Contract.lifecycle.state -ne "approved") {
    throw "Auditor lifecycle must be approved."
}

if ($Contract.scope.provider_specific -ne $false) {
    throw "Auditor must remain provider-neutral."
}

if ($Contract.resources.scripts.Count -ne 0) {
    throw "Auditor v0.2.0 must have zero scripts."
}

if (@($Contract.purpose.use_when).Count -ne 4) {
    throw "Expected 4 positive trigger declarations."
}

if (@($Contract.purpose.do_not_use_when).Count -ne 4) {
    throw "Expected 4 non-trigger declarations."
}

Write-Host "[PASS] lifecycle=approved"
Write-Host "[PASS] provider-neutral=true"
Write-Host "[PASS] scripts=0"
Write-Host "[PASS] trigger declarations=4"
Write-Host "[PASS] non-trigger declarations=4"

$Passed = 0
$Failed = 0

foreach ($Case in $Cases) {

    $SourceName = [string]$Case.source

    if (-not $SourceMap.ContainsKey($SourceName)) {

        Write-Host "[FAIL] $($Case.id) | unknown source=$SourceName" -ForegroundColor Red
        $Failed++
        continue
    }

    $SourceText = [string]$SourceMap[$SourceName]
    $Missing = @()

    foreach ($Term in @($Case.required_terms)) {

        $TermString = [string]$Term

        if (
            $SourceText.IndexOf(
                $TermString,
                [System.StringComparison]::OrdinalIgnoreCase
            ) -lt 0
        ) {
            $Missing += $TermString
        }
    }

    if ($Missing.Count -eq 0) {

        Write-Host ("[PASS] {0} | category={1}" -f $Case.id,$Case.category) -ForegroundColor Green
        $Passed++
    }
    else {

        Write-Host ("[FAIL] {0} | category={1}" -f $Case.id,$Case.category) -ForegroundColor Red

        foreach ($Term in $Missing) {
            Write-Host "       missing: $Term"
        }

        $Failed++
    }
}

Write-Host ""
Write-Host "SEMANTIC_CASES=$($Cases.Count)"
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"

if ($Failed -gt 0) {
    throw "SEMANTIC POLICY TEST FAILURE"
}

Write-Host ""
Write-Host "[PASS] ALL SEMANTIC POLICY TESTS PASSED" -ForegroundColor Green