param(
    [Parameter(Mandatory = $true)]
    [string]$CreatorRoot,

    [Parameter(Mandatory = $true)]
    [string]$TestsRoot
)

$ErrorActionPreference = "Stop"

$SkillJsonPath = Join-Path $CreatorRoot "skill.json"
$SkillMdPath = Join-Path $CreatorRoot "SKILL.md"
$MethodPath = Join-Path $CreatorRoot "references\creator-methodology.md"
$CasesPath = Join-Path $TestsRoot "semantic-cases.json"

foreach ($Path in @($SkillJsonPath,$SkillMdPath,$MethodPath,$CasesPath)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ("Missing required Creator test input: " + $Path)
    }
}

$Contract = Get-Content -LiteralPath $SkillJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$SkillText = [System.IO.File]::ReadAllText($SkillMdPath,[System.Text.Encoding]::UTF8)
$MethodText = [System.IO.File]::ReadAllText($MethodPath,[System.Text.Encoding]::UTF8)
$ParsedCases = Get-Content -LiteralPath $CasesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Cases = @()
foreach ($Item in @($ParsedCases)) {
    if ($Item -is [System.Array]) {
        foreach ($Nested in $Item) {
            $Cases += $Nested
        }
    }
    else {
        $Cases += $Item
    }
}
Write-Host ("CASES_PARSED_TYPE=" + $(if ($null -eq $ParsedCases) { "<null>" } else { $ParsedCases.GetType().FullName }))
Write-Host ("CASES_NORMALIZED_COUNT=" + $Cases.Count)

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

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL SKILL CREATOR SEMANTIC TESTS"
Write-Host "============================================================"

Check -Name "id=proxtel-skill-creator" -Condition ([string]$Contract.id -ceq "proxtel-skill-creator")
Check -Name "lifecycle=approved" -Condition ([string]$Contract.lifecycle.state -ceq "approved")
Check -Name "version=0.1.0" -Condition ([string]$Contract.lifecycle.version -ceq "0.1.0")
Check -Name "provider-neutral=true" -Condition (-not [bool]$Contract.scope.provider_specific)
Check -Name "providers=3" -Condition (@($Contract.scope.providers).Count -eq 3)
Check -Name "scripts=0" -Condition (@($Contract.resources.scripts).Count -eq 0)
Check -Name "dependencies=0" -Condition (@($Contract.dependencies).Count -eq 0)
Check -Name "testing-required=true" -Condition ([bool]$Contract.testing.required)
Check -Name "semantic-cases=14" -Condition ($Cases.Count -eq 14)
Check -Name "mechanism-router-present" -Condition ($SkillText.Contains("## Phase 2 - Mechanism Router"))
Check -Name "candidate-only-present" -Condition ($SkillText.Contains("Toda Skill nueva producida por el Creator queda como candidate."))
Check -Name "self-approval-forbidden" -Condition ($SkillText.Contains("El Creator nunca puede convertir por si mismo una Skill en approved."))
Check -Name "dependency-install-forbidden" -Condition ($SkillText.Contains("No instalar dependencias automaticamente."))
Check -Name "external-code-forbidden" -Condition ($SkillText.Contains("No ejecutar codigo externo no auditado."))
Check -Name "auditor-handoff-present" -Condition ($SkillText.Contains("## Phase 9 - Auditor Handoff"))
Check -Name "registry-lifecycle-distinction" -Condition ($MethodText.Contains("Los vocabularios son distintos."))

$Ids = @($Cases | ForEach-Object { [string]$_.id })
Check -Name "case-self-approval-forbidden" -Condition ($Ids -contains "self-approval-forbidden")
Check -Name "case-provider-neutral" -Condition ($Ids -contains "provider-neutral-canonical")

Write-Host ""
Write-Host ("CREATOR_SEMANTIC_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)

if ($Failed -gt 0) {
    throw "CREATOR SEMANTIC TEST FAILURE"
}

Write-Host ""
Write-Host "[PASS] ALL CREATOR SEMANTIC TESTS PASSED" -ForegroundColor Green