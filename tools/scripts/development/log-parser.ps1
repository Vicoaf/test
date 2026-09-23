[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [ValidateRange(1,10000)]
    [int]$Tail = 2000,

    [ValidateRange(1,1000)]
    [int]$MaxMatches = 200,

    [string]$Pattern = '(?i)(error|exception|fatal|critical|warning|warn)'
)

$ErrorActionPreference = 'Stop'

function Redact-ProxtelSecret {

    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return ''
    }

    $Redacted = [string]$Value

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
        }
    )

    foreach ($Rule in $Rules) {

        $Redacted = [regex]::Replace(
            $Redacted,
            [string]$Rule.Pattern,
            [string]$Rule.Replacement
        )
    }

    return $Redacted
}

$Result = [ordered]@{
    tool_id = 'log-parser'
    status = 'preflight'
    source = $Path
    entries_scanned = 0
    matches = @()
    severity_summary = [ordered]@{
        error = 0
        warning = 0
        other = 0
    }
    redactions = 'enabled'
    warnings = @()
}

try {

    $ResolvedPath = (
        Resolve-Path `
            -LiteralPath $Path `
            -ErrorAction Stop
    ).Path

    if (-not (
        Test-Path `
            -LiteralPath $ResolvedPath `
            -PathType Leaf
    )) {
        throw 'Log source is not a file.'
    }

    $Lines = @(
        Get-Content `
            -LiteralPath $ResolvedPath `
            -Tail $Tail `
            -ErrorAction Stop
    )

    $Result.entries_scanned = $Lines.Count

    # IMPORTANT:
    # Do NOT use $Matches here.
    # $Matches is a PowerShell automatic variable.
    $MatchItems = New-Object `
        'System.Collections.Generic.List[object]'

    $LineNumber = 0

    foreach ($Line in $Lines) {

        $LineNumber++

        if ([string]$Line -notmatch $Pattern) {
            continue
        }

        $Redacted = Redact-ProxtelSecret `
            -Value ([string]$Line)

        $Severity = 'other'

        if (
            $Redacted -match
            '(?i)(error|exception|fatal|critical)'
        ) {

            $Severity = 'error'

            $Result.severity_summary['error'] = (
                [int]$Result.severity_summary['error'] +
                1
            )
        }
        elseif (
            $Redacted -match
            '(?i)(warning|warn)'
        ) {

            $Severity = 'warning'

            $Result.severity_summary['warning'] = (
                [int]$Result.severity_summary['warning'] +
                1
            )
        }
        else {

            $Result.severity_summary['other'] = (
                [int]$Result.severity_summary['other'] +
                1
            )
        }

        $MatchItems.Add(
            [PSCustomObject][ordered]@{
                relative_line = $LineNumber
                severity = $Severity
                text = $Redacted
            }
        )

        if ($MatchItems.Count -ge $MaxMatches) {

            $Result.warnings = @(
                'Match limit reached.'
            )

            break
        }
    }

    $Result.source = $ResolvedPath

    $Result.matches = @(
        $MatchItems |
        ForEach-Object {
            $_
        }
    )

    $Result.status = 'pass'
}
catch {

    $Result.status = 'error'

    $Result.warnings = @(
        (
            Redact-ProxtelSecret `
                -Value (
                    [string]$_.Exception.Message
                )
        )
    )
}

$Result |
    ConvertTo-Json -Depth 15 -Compress |
    Write-Output

if ($Result.status -eq 'error') {
    exit 1
}

exit 0
