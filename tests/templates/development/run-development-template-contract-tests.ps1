[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$StageRoot,

    [Parameter(Mandatory = $true)]
    [string]$RuntimePath,

    [Parameter(Mandatory = $true)]
    [string]$BundlesPath
)

$ErrorActionPreference = 'Stop'

$TemplateIds = @(
    'website',
    'landing-page',
    'laravel',
    'crm',
    'saas'
)

$ExpectedSkills = @(
    'auditor-web',
    'maestro-frontend',
    'estratega-seo'
)

$Runtime = Get-Content `
    -LiteralPath $RuntimePath `
    -Raw `
    -Encoding UTF8 |
    ConvertFrom-Json

$Bundles = Get-Content `
    -LiteralPath $BundlesPath `
    -Raw `
    -Encoding UTF8 |
    ConvertFrom-Json

$Registry = Get-Content `
    -LiteralPath (
        Join-Path `
            $StageRoot `
            'tools\registry\development-tools.json'
    ) `
    -Raw `
    -Encoding UTF8 |
    ConvertFrom-Json

$RuntimeLanes = @(
    @($Runtime.bindings) |
    ForEach-Object {
        [string]$_.lane
    }
)

$ToolIds = @(
    @($Registry.tools) |
    ForEach-Object {
        [string]$_.id
    }
)

foreach ($TemplateId in $TemplateIds) {

    $ManifestPath = Join-Path `
        $StageRoot `
        "templates\$TemplateId\template.json"

    if (-not (
        Test-Path `
            -LiteralPath $ManifestPath `
            -PathType Leaf
    )) {
        throw "Template manifest missing [$TemplateId]."
    }

    $Manifest = Get-Content `
        -LiteralPath $ManifestPath `
        -Raw `
        -Encoding UTF8 |
        ConvertFrom-Json

    if ([string]$Manifest.kind -cne 'proxtel-development-template') {
        throw "Template kind invalid [$TemplateId]."
    }

    if ([string]$Manifest.id -cne $TemplateId) {
        throw "Template ID mismatch [$TemplateId]."
    }

    if ([string]$Manifest.status -cne 'candidate-staged') {
        throw "Template lifecycle invalid [$TemplateId]."
    }

    if (
        [string]$Manifest.required_skill_bundle -cne
        $TemplateId
    ) {
        throw "Template bundle ID mismatch [$TemplateId]."
    }

    $BundleProperty = `
        $Bundles.PSObject.Properties[$TemplateId]

    if ($null -eq $BundleProperty) {
        throw "Skill bundle missing [$TemplateId]."
    }

    $BundleSkills = @(
        $BundleProperty.Value
    )

    foreach ($SkillId in $ExpectedSkills) {

        if ($BundleSkills -cnotcontains $SkillId) {
            throw (
                "Template [$TemplateId] missing Skill " +
                "[$SkillId]."
            )
        }
    }

    foreach ($Lane in @($Manifest.primary_lanes)) {

        if ($RuntimeLanes -cnotcontains [string]$Lane) {
            throw (
                "Template [$TemplateId] references unknown " +
                "lane [$Lane]."
            )
        }
    }

    foreach ($ToolId in @($Manifest.compatible_tools)) {

        if ($ToolIds -cnotcontains [string]$ToolId) {
            throw (
                "Template [$TemplateId] references unknown " +
                "Tool [$ToolId]."
            )
        }
    }

    Write-Host "[PASS] TEMPLATE_CONTRACT=[$TemplateId]"
}

Write-Host '[PASS] TEMPLATE_CONTRACT_COUNT=5'
Write-Host '[PASS] TEMPLATE_RUNTIME_LANES=VALID'
Write-Host '[PASS] TEMPLATE_TOOL_REFERENCES=VALID'
Write-Host '[PASS] TEMPLATE_SKILL_BUNDLES=VALID'
