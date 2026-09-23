param(
    [Parameter(Mandatory = $true)]
    [string]$CandidatesRoot,

    [Parameter(Mandatory = $true)]
    [string]$RegistryPath,

    [Parameter(Mandatory = $true)]
    [string]$LegacySkillsRoot,

    [Parameter(Mandatory = $true)]
    [string]$CasesPath
)

$ErrorActionPreference = "Stop"

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

$Registry = Get-Content -LiteralPath $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json

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
Write-Host " PROXTEL DEVELOPMENT SKILL CANDIDATE TESTS"
Write-Host "============================================================"

foreach ($Case in $Cases) {
    $Id = [string]$Case.id
    $CandidateRoot = Join-Path $CandidatesRoot $Id
    $SkillMdPath = Join-Path $CandidateRoot "SKILL.md"
    $SkillJsonPath = Join-Path $CandidateRoot "skill.json"
    $LegacyReferencePath = Join-Path $CandidateRoot "references\legacy-baseline.md"
    $ModernizationNotesPath = Join-Path $CandidateRoot "references\modernization-notes.md"
    $LegacyPath = Join-Path $LegacySkillsRoot ($Id + "\SKILL.md")

    $Prefix = $Id + ":"

    Check ($Prefix + "candidate-root") (Test-Path -LiteralPath $CandidateRoot -PathType Container)
    Check ($Prefix + "skill-md") (Test-Path -LiteralPath $SkillMdPath -PathType Leaf)
    Check ($Prefix + "skill-json") (Test-Path -LiteralPath $SkillJsonPath -PathType Leaf)
    Check ($Prefix + "legacy-reference") (Test-Path -LiteralPath $LegacyReferencePath -PathType Leaf)
    Check ($Prefix + "modernization-notes") (Test-Path -LiteralPath $ModernizationNotesPath -PathType Leaf)

    $Skill = Get-Content -LiteralPath $SkillJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Manual = [System.IO.File]::ReadAllText($SkillMdPath,[System.Text.Encoding]::UTF8)

    Check ($Prefix + "id") ([string]$Skill.id -ceq $Id)
    Check ($Prefix + "area") ([string]$Skill.area -ceq "development")
    Check ($Prefix + "lifecycle-candidate") ([string]$Skill.lifecycle.state -ceq "candidate")
    Check ($Prefix + "version") ([string]$Skill.lifecycle.version -ceq "1.0.0")
    Check ($Prefix + "provider-neutral") (-not [bool]$Skill.scope.provider_specific)
    Check ($Prefix + "providers=3") (@($Skill.scope.providers).Count -eq 3)
    Check ($Prefix + "dependencies=0") (@($Skill.dependencies).Count -eq 0)
    Check ($Prefix + "scripts=0") (@($Skill.resources.scripts).Count -eq 0)
    Check ($Prefix + "testing-required") ([bool]$Skill.testing.required)
    Check ($Prefix + "trigger-tests") ([bool]$Skill.testing.trigger_tests)
    Check ($Prefix + "task-evals") ([bool]$Skill.testing.task_evals)
    Check ($Prefix + "baseline-comparison") ([bool]$Skill.testing.baseline_comparison)
    Check ($Prefix + "no-privilege") (-not [bool]$Skill.security.privilege_required)

    $RegistryMatches = @(
        @($Registry.skills) |
        Where-Object {
            [string]$_.id -ceq $Id
        }
    )

    Check ($Prefix + "registry-count=1") ($RegistryMatches.Count -eq 1)

    if ($RegistryMatches.Count -eq 1) {
        Check ($Prefix + "registry-under-audit") ([string]$RegistryMatches[0].state -ceq "under-audit")
        Check ($Prefix + "registry-canonical-path") ([string]$RegistryMatches[0].source_path -ceq [string]$Case.canonical_rel)
    }
    else {
        Check ($Prefix + "registry-under-audit") $false
        Check ($Prefix + "registry-canonical-path") $false
    }

    $LegacyHash = (Get-FileHash -LiteralPath $LegacyPath -Algorithm SHA256).Hash
    $ReferenceHash = (Get-FileHash -LiteralPath $LegacyReferencePath -Algorithm SHA256).Hash

    Check ($Prefix + "legacy-hash") ($LegacyHash -ceq [string]$Case.legacy_sha256)
    Check ($Prefix + "legacy-reference-hash") ($ReferenceHash -ceq [string]$Case.legacy_sha256)

    foreach ($Marker in @($Case.required_markers)) {
        Check ($Prefix + "marker:" + [string]$Marker) ($Manual.Contains([string]$Marker))
    }
}

Write-Host ""
Write-Host ("CANDIDATE_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)

if ($Failed -gt 0) {
    throw "DEVELOPMENT CANDIDATE TEST FAILURE"
}

Write-Host "[PASS] ALL DEVELOPMENT CANDIDATE TESTS PASSED" -ForegroundColor Green