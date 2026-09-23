param(
    [Parameter(Mandatory = $true)]
    [string]$AgencyRoot,

    [Parameter(Mandatory = $true)]
    [string]$ResolverPath,

    [Parameter(Mandatory = $true)]
    [string]$RegistryPath,

    [Parameter(Mandatory = $true)]
    [string]$LegacySourceRoot,

    [Parameter(Mandatory = $true)]
    [string]$SyncScriptPath,

    [Parameter(Mandatory = $true)]
    [string]$InstallScriptPath
)

$ErrorActionPreference = "Stop"

foreach ($Path in @($ResolverPath,$RegistryPath,$SyncScriptPath,$InstallScriptPath)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ("Missing bridge test input: " + $Path)
    }
}

. $ResolverPath

$Ids = @(
    "auditor-web",
    "estratega-seo",
    "maestro-frontend"
)

$Passed = 0
$Failed = 0

function Check {
    param([string]$Name,[bool]$Condition)

    if ($Condition) {
        Write-Host ("[PASS] " + $Name)
        $script:Passed++
    }
    else {
        Write-Host ("[FAIL] " + $Name)
        $script:Failed++
    }
}

$SyncText = [System.IO.File]::ReadAllText($SyncScriptPath,[System.Text.Encoding]::UTF8)
$InstallText = [System.IO.File]::ReadAllText($InstallScriptPath,[System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL DISTRIBUTION BRIDGE TESTS"
Write-Host "============================================================"

Check "sync-loads-resolver" ($SyncText.Contains('skill-source-resolver.ps1'))
Check "sync-calls-resolver" ($SyncText.Contains('Get-ProxtelSkillSource'))
Check "install-loads-resolver" ($InstallText.Contains('skill-source-resolver.ps1'))
Check "install-calls-resolver" ($InstallText.Contains('Get-ProxtelSkillSource'))

foreach ($Id in $Ids) {
    $Resolved = Get-ProxtelSkillSource `
        -AgencyRoot $AgencyRoot `
        -SkillId $Id `
        -LegacySourceRoot $LegacySourceRoot `
        -RegistryPath $RegistryPath

    $ExpectedLegacy = Join-Path $LegacySourceRoot $Id

    Check ($Id + ":under-audit-uses-legacy") (
        [System.IO.Path]::GetFullPath($Resolved) -ceq
        [System.IO.Path]::GetFullPath($ExpectedLegacy)
    )
}

$TempApprovedRegistry = Join-Path ([System.IO.Path]::GetTempPath()) ("proxtel-approved-registry-" + [guid]::NewGuid().ToString("N") + ".json")

try {
    $Approved = Get-Content -LiteralPath $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json

    foreach ($Id in $Ids) {
        $Matches = @(
            @($Approved.skills) |
            Where-Object {
                [string]$_.id -ceq $Id
            }
        )

        if ($Matches.Count -ne 1) {
            throw ("Approved-registry test match count invalid: " + $Id)
        }

        $Matches[0].state = "approved"
    }

    [System.IO.File]::WriteAllText(
        $TempApprovedRegistry,
        (ConvertTo-Json -InputObject $Approved -Depth 100),
        (New-Object System.Text.UTF8Encoding($false))
    )

    foreach ($Id in $Ids) {
        $Resolved = Get-ProxtelSkillSource `
            -AgencyRoot $AgencyRoot `
            -SkillId $Id `
            -LegacySourceRoot $LegacySourceRoot `
            -RegistryPath $TempApprovedRegistry

        $Entry = @(
            @($Approved.skills) |
            Where-Object {
                [string]$_.id -ceq $Id
            }
        )[0]

        $ExpectedCanonical = Join-Path $AgencyRoot ([string]$Entry.source_path).Replace("/","\")

        Check ($Id + ":approved-uses-canonical") (
            [System.IO.Path]::GetFullPath($Resolved) -ceq
            [System.IO.Path]::GetFullPath($ExpectedCanonical)
        )
    }
}
finally {
    if (Test-Path -LiteralPath $TempApprovedRegistry -PathType Leaf) {
        Remove-Item -LiteralPath $TempApprovedRegistry -Force
    }
}

Write-Host ""
Write-Host ("BRIDGE_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)

if ($Failed -gt 0) {
    throw "DISTRIBUTION BRIDGE TEST FAILURE"
}

Write-Host "[PASS] ALL DISTRIBUTION BRIDGE TESTS PASSED" -ForegroundColor Green