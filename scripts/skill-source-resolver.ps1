function Get-ProxtelSkillSource {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgencyRoot,

        [Parameter(Mandatory = $true)]
        [string]$SkillId,

        [Parameter(Mandatory = $true)]
        [string]$LegacySourceRoot,

        [string]$RegistryPath = ""
    )

    if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
        $RegistryPath = Join-Path $AgencyRoot "skills\_registry\skills-registry.json"
    }

    $LegacyPath = Join-Path $LegacySourceRoot $SkillId

    if (-not (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) {
        if (Test-Path -LiteralPath $LegacyPath -PathType Container) {
            return $LegacyPath
        }

        throw ("Skill Registry missing and legacy Skill unavailable: " + $SkillId)
    }

    $Registry = Get-Content -LiteralPath $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $Matches = @(
        @($Registry.skills) |
        Where-Object {
            [string]$_.id -ceq $SkillId
        }
    )

    if ($Matches.Count -eq 0) {
        if (Test-Path -LiteralPath $LegacyPath -PathType Container) {
            return $LegacyPath
        }

        throw ("Skill is not registered and no legacy source exists: " + $SkillId)
    }

    if ($Matches.Count -ne 1) {
        throw ("Skill Registry contains duplicate id: " + $SkillId)
    }

    $Entry = $Matches[0]

    if ([string]$Entry.state -ceq "approved") {
        $RelativeSource = [string]$Entry.source_path

        if ([string]::IsNullOrWhiteSpace($RelativeSource)) {
            throw ("Approved Skill has empty source_path: " + $SkillId)
        }

        $CanonicalPath = Join-Path $AgencyRoot ($RelativeSource.Replace("/","\"))

        if (-not (Test-Path -LiteralPath $CanonicalPath -PathType Container)) {
            throw ("Approved canonical Skill source missing: " + $CanonicalPath)
        }

        $SkillMd = Join-Path $CanonicalPath "SKILL.md"

        if (-not (Test-Path -LiteralPath $SkillMd -PathType Leaf)) {
            throw ("Approved canonical Skill missing SKILL.md: " + $CanonicalPath)
        }

        return $CanonicalPath
    }

    if (Test-Path -LiteralPath $LegacyPath -PathType Container) {
        return $LegacyPath
    }

    throw (
        "Skill is not approved and no legacy fallback exists: " +
        $SkillId +
        " state=" +
        [string]$Entry.state
    )
}