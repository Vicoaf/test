[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$StageRoot
)

$ErrorActionPreference = 'Stop'

$ExpectedTools = [ordered]@{
    'artisan-runner' = 'tools/scripts/development/artisan-runner.ps1'
    'db-inspector'   = 'tools/scripts/development/db-inspector.ps1'
    'log-parser'     = 'tools/scripts/development/log-parser.ps1'
    'vite-builder'   = 'tools/scripts/development/vite-builder.ps1'
    'api-tester'     = 'tools/scripts/development/api-tester.ps1'
}

$RegistryPath = Join-Path `
    $StageRoot `
    'tools\registry\development-tools.json'

$Registry = Get-Content `
    -LiteralPath $RegistryPath `
    -Raw `
    -Encoding UTF8 |
    ConvertFrom-Json

if ([string]$Registry.status -cne 'candidate-staged') {
    throw 'Candidate Tool Registry lifecycle invalid.'
}

if (@($Registry.tools).Count -ne 5) {
    throw 'Candidate Tool count invalid.'
}

if ([bool]$Registry.execution.enabled) {
    throw 'Candidate Tool execution must remain disabled.'
}

foreach ($ToolId in $ExpectedTools.Keys) {

    $Tool = @(
        @($Registry.tools) |
        Where-Object {
            [string]$_.id -ceq $ToolId
        }
    )

    if ($Tool.Count -ne 1) {
        throw "Tool contract invalid [$ToolId]."
    }

    $ScriptPath = Join-Path `
        $StageRoot `
        (
            [string]$ExpectedTools[$ToolId]
        ).Replace('/','\')

    if (-not (
        Test-Path `
            -LiteralPath $ScriptPath `
            -PathType Leaf
    )) {
        throw "Tool script missing [$ToolId]."
    }

    $Tokens = $null
    $Errors = $null

    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $ScriptPath,
        [ref]$Tokens,
        [ref]$Errors
    )

    if (@($Errors).Count -ne 0) {
        throw "PowerShell parser failed [$ToolId]."
    }

    Write-Host "[PASS] TOOL_PARSE=[$ToolId]"
}

$ArtisanSource = Get-Content `
    -LiteralPath (
        Join-Path `
            $StageRoot `
            'tools\scripts\development\artisan-runner.ps1'
    ) `
    -Raw

$ViteSource = Get-Content `
    -LiteralPath (
        Join-Path `
            $StageRoot `
            'tools\scripts\development\vite-builder.ps1'
    ) `
    -Raw

$ApiSource = Get-Content `
    -LiteralPath (
        Join-Path `
            $StageRoot `
            'tools\scripts\development\api-tester.ps1'
    ) `
    -Raw

$LogSource = Get-Content `
    -LiteralPath (
        Join-Path `
            $StageRoot `
            'tools\scripts\development\log-parser.ps1'
    ) `
    -Raw

$DbHelperSource = Get-Content `
    -LiteralPath (
        Join-Path `
            $StageRoot `
            'tools\scripts\development\helpers\db-inspector.php'
    ) `
    -Raw

foreach ($Check in @(
    [PSCustomObject]@{
        Name = 'artisan-redactor'
        Pass = (
            $ArtisanSource -match
            'Protect-ProxtelText'
        )
    },
    [PSCustomObject]@{
        Name = 'vite-redactor'
        Pass = (
            $ViteSource -match
            'Protect-ProxtelText'
        )
    },
    [PSCustomObject]@{
        Name = 'api-redactor'
        Pass = (
            $ApiSource -match
            'Protect-ProxtelText'
        )
    },
    [PSCustomObject]@{
        Name = 'log-redactor'
        Pass = (
            $LogSource -match
            'Redact-ProxtelSecret'
        )
    },
    [PSCustomObject]@{
        Name = 'log-no-matches-list'
        Pass = (
            $LogSource -notmatch
            '\$Matches\.Add'
        )
    },
    [PSCustomObject]@{
        Name = 'db-row-redactor'
        Pass = (
            $DbHelperSource -match
            'redactRows'
        )
    }
)) {

    if (-not $Check.Pass) {
        throw "Security contract failed [$($Check.Name)]."
    }

    Write-Host "[PASS] SECURITY_CONTRACT=[$($Check.Name)]"
}

$DbGuardMarkers = @(
    'FOR\s+UPDATE',
    'FOR\s+SHARE',
    'LOCK\s+IN\s+SHARE',
    'GET_LOCK\s*',
    'RELEASE_LOCK\s*',
    'SLEEP\s*',
    'BENCHMARK\s*'
)

foreach ($Marker in $DbGuardMarkers) {

    if (
        $DbHelperSource.IndexOf(
            $Marker,
            [System.StringComparison]::Ordinal
        ) -lt 0
    ) {
        throw "DB guard marker missing [$Marker]."
    }

    Write-Host "[PASS] DB_GUARD_MARKER=[$Marker]"
}

Write-Host '[PASS] TOOL_CONTRACT_COUNT=5'
Write-Host '[PASS] TOOL_SECURITY_CONTRACTS=HARDENED'
Write-Host '[PASS] TOOL_EXECUTION_PERFORMED=NO'
