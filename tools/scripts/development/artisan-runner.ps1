[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'about',
        'list',
        'route:list',
        'migrate:status',
        'event:list',
        'schedule:list'
    )]
    [string]$Command,

    [string[]]$Arguments = @(),

    [ValidateRange(1,900)]
    [int]$TimeoutSeconds = 120,

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
    tool_id = 'artisan-runner'
    status = 'preflight'
    project_root = $ProjectRoot
    command = $Command
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

    $ArtisanPath = Join-Path `
        $ResolvedRoot `
        'artisan'

    if (-not (
        Test-Path `
            -LiteralPath $ArtisanPath `
            -PathType Leaf
    )) {
        throw 'Laravel artisan file not found.'
    }

    $Php = Get-Command php -ErrorAction Stop

    if (-not $Execute) {

        $Result.status = 'dry-run'
        $Result.project_root = $ResolvedRoot

        $Result.stdout = (
            'Preflight passed. ' +
            'No Artisan process executed.'
        )

        $Result.duration_ms = [int](
            ([DateTime]::UtcNow - $Started).
            TotalMilliseconds
        )

        Write-ProxtelResult $Result

        exit 0
    }

    $ArgumentParts = @(
        'artisan',
        $Command
    ) + @($Arguments)

    $QuotedArguments = @(
        $ArgumentParts |
        ForEach-Object {

            $Item = [string]$_

            if ($Item -match '[\s"]') {

                '"' +
                ($Item -replace '"','\"') +
                '"'
            }
            else {
                $Item
            }
        }
    )

    $Psi = New-Object `
        System.Diagnostics.ProcessStartInfo

    $Psi.FileName = $Php.Source
    $Psi.WorkingDirectory = $ResolvedRoot
    $Psi.Arguments = ($QuotedArguments -join ' ')
    $Psi.UseShellExecute = $false
    $Psi.CreateNoWindow = $true
    $Psi.RedirectStandardOutput = $true
    $Psi.RedirectStandardError = $true

    $Process = New-Object `
        System.Diagnostics.Process

    $Process.StartInfo = $Psi

    if (-not $Process.Start()) {
        throw 'Unable to start PHP process.'
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
            "Artisan timeout after " +
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
