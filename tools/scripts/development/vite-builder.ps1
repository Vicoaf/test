[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$BuildScript = 'build',

    [ValidateRange(1,1800)]
    [int]$TimeoutSeconds = 300,

    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

function Protect-ProxtelText {

    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return ''
    }

    $Protected = [string]$Value

    $Rules = @(
        [PSCustomObject]@{
            Pattern = '(?i)((?:password|passwd|pwd|secret|token|api[_-]?key|client[_-]?secret)\s*[:=]\s*)[^\s,;]+'
            Replacement = '$1[REDACTED]'
        },
        [PSCustomObject]@{
            Pattern = '(?i)("(?:password|passwd|pwd|secret|token|api[_-]?key|client[_-]?secret)"\s*:\s*")[^"]*(")'
            Replacement = '$1[REDACTED]$2'
        },
        [PSCustomObject]@{
            Pattern = '(?i)(authorization\s*:\s*(?:bearer|basic)\s+)[^\s]+'
            Replacement = '$1[REDACTED]'
        },
        [PSCustomObject]@{
            Pattern = '(?i)([?&](?:token|access_token|api_key|key|secret|password)=)[^&\s]+'
            Replacement = '$1[REDACTED]'
        },
        [PSCustomObject]@{
            Pattern = '\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b'
            Replacement = '[REDACTED-JWT]'
        }
    )

    foreach ($Rule in $Rules) {

        $Protected = [regex]::Replace(
            $Protected,
            [string]$Rule.Pattern,
            [string]$Rule.Replacement
        )
    }

    return $Protected
}

function Write-ProxtelResult {

    param($Value)

    $Value |
        ConvertTo-Json -Depth 12 -Compress |
        Write-Output
}

$Started = [DateTime]::UtcNow

$Result = [ordered]@{
    tool_id = 'vite-builder'
    status = 'preflight'
    project_root = $ProjectRoot
    package_manager = 'npm'
    build_script = $BuildScript
    exit_code = $null
    stdout = ''
    stderr = ''
    duration_ms = 0
}

try {

    $ResolvedRoot = (
        Resolve-Path `
            -LiteralPath $ProjectRoot `
            -ErrorAction Stop
    ).Path

    $PackageJsonPath = Join-Path `
        $ResolvedRoot `
        'package.json'

    if (-not (
        Test-Path `
            -LiteralPath $PackageJsonPath `
            -PathType Leaf
    )) {
        throw 'package.json not found.'
    }

    $PackageJson = Get-Content `
        -LiteralPath $PackageJsonPath `
        -Raw `
        -Encoding UTF8 |
        ConvertFrom-Json

    $ScriptProperty = `
        $PackageJson.scripts.
        PSObject.Properties[$BuildScript]

    if ($null -eq $ScriptProperty) {
        throw "npm script [$BuildScript] not found."
    }

    $NodeModules = Join-Path `
        $ResolvedRoot `
        'node_modules'

    if (-not (
        Test-Path `
            -LiteralPath $NodeModules `
            -PathType Container
    )) {

        throw (
            'node_modules not present. ' +
            'Automatic npm install is forbidden.'
        )
    }

    $Npm = Get-Command `
        npm.cmd `
        -ErrorAction SilentlyContinue

    if ($null -eq $Npm) {

        $Npm = Get-Command `
            npm `
            -ErrorAction Stop
    }

    if (-not $Execute) {

        $Result.status = 'dry-run'
        $Result.project_root = $ResolvedRoot

        $Result.stdout = (
            'Preflight passed. ' +
            'No npm build process executed.'
        )

        $Result.duration_ms = [int](
            ([DateTime]::UtcNow - $Started).
            TotalMilliseconds
        )

        Write-ProxtelResult $Result

        exit 0
    }

    $Psi = New-Object `
        System.Diagnostics.ProcessStartInfo

    $Psi.FileName = $Npm.Source
    $Psi.WorkingDirectory = $ResolvedRoot

    $Psi.Arguments = (
        'run "' +
        $BuildScript +
        '"'
    )

    $Psi.UseShellExecute = $false
    $Psi.CreateNoWindow = $true
    $Psi.RedirectStandardOutput = $true
    $Psi.RedirectStandardError = $true

    $Process = New-Object `
        System.Diagnostics.Process

    $Process.StartInfo = $Psi

    if (-not $Process.Start()) {
        throw 'Unable to start npm.'
    }

    $StdoutTask = `
        $Process.StandardOutput.ReadToEndAsync()

    $StderrTask = `
        $Process.StandardError.ReadToEndAsync()

    if (-not $Process.WaitForExit(
        $TimeoutSeconds * 1000
    )) {

        try {
            $Process.Kill()
        }
        catch {
        }

        throw (
            "Vite build timeout after " +
            "$TimeoutSeconds seconds."
        )
    }

    $Result.exit_code = $Process.ExitCode

    $Result.stdout = Protect-ProxtelText `
        -Value ([string]$StdoutTask.Result)

    $Result.stderr = Protect-ProxtelText `
        -Value ([string]$StderrTask.Result)

    $Result.project_root = $ResolvedRoot

    if ($Process.ExitCode -eq 0) {
        $Result.status = 'pass'
    }
    else {
        $Result.status = 'fail'
    }
}
catch {

    $Result.status = 'error'

    $Result.stderr = Protect-ProxtelText `
        -Value ([string]$_.Exception.Message)
}
finally {

    $Result.duration_ms = [int](
        ([DateTime]::UtcNow - $Started).
        TotalMilliseconds
    )
}

Write-ProxtelResult $Result

if (
    $Result.status -eq 'fail' -or
    $Result.status -eq 'error'
) {
    exit 1
}

exit 0
