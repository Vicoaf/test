[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Uri]$Url,

    [ValidateSet(
        'GET',
        'HEAD',
        'OPTIONS',
        'POST',
        'PUT',
        'PATCH',
        'DELETE'
    )]
    [string]$Method = 'GET',

    [hashtable]$Headers = @{},

    [AllowNull()]
    $Body,

    [ValidateRange(1,300)]
    [int]$TimeoutSeconds = 30,

    [switch]$AllowMutatingMethod,

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

function Get-RedactedUrl {

    param(
        [Parameter(Mandatory = $true)]
        [Uri]$InputUrl
    )

    $Builder = New-Object `
        System.UriBuilder($InputUrl)

    $Builder.UserName = ''
    $Builder.Password = ''

    if (
        -not [string]::IsNullOrWhiteSpace(
            $Builder.Query
        )
    ) {
        $Builder.Query = '[REDACTED]'
    }

    return $Builder.Uri.AbsoluteUri
}

function Get-RedactedHeaders {

    param(
        [hashtable]$InputHeaders
    )

    $Output = [ordered]@{}

    foreach ($Key in $InputHeaders.Keys) {

        if (
            [string]$Key -match
            '(?i)^(authorization|cookie|set-cookie|x-api-key|api-key)$'
        ) {

            $Output[[string]$Key] = '[REDACTED]'
        }
        else {

            $Output[[string]$Key] = `
                Protect-ProxtelText `
                    -Value (
                        [string]$InputHeaders[$Key]
                    )
        }
    }

    return $Output
}

$Started = [DateTime]::UtcNow

$Result = [ordered]@{
    tool_id = 'api-tester'
    status = 'preflight'
    method = $Method
    url_redacted = Get-RedactedUrl `
        -InputUrl $Url
    http_status = $null
    headers_redacted = Get-RedactedHeaders `
        -InputHeaders $Headers
    body_summary = ''
    duration_ms = 0
    warnings = @()
}

try {

    if (
        $Url.Scheme -notin @(
            'http',
            'https'
        )
    ) {
        throw 'Only HTTP and HTTPS URLs are allowed.'
    }

    $MutatingMethods = @(
        'POST',
        'PUT',
        'PATCH',
        'DELETE'
    )

    if (
        $MutatingMethods -contains $Method -and
        -not $AllowMutatingMethod
    ) {

        throw (
            "Mutating method [$Method] requires " +
            '-AllowMutatingMethod.'
        )
    }

    if (-not $Execute) {

        $Result.status = 'dry-run'

        $Result.body_summary = (
            'Preflight passed. ' +
            'No HTTP request was sent.'
        )

        $Result.duration_ms = [int](
            ([DateTime]::UtcNow - $Started).
            TotalMilliseconds
        )

        $Result |
            ConvertTo-Json -Depth 12 -Compress |
            Write-Output

        exit 0
    }

    $Parameters = @{
        Uri = $Url
        Method = $Method
        Headers = $Headers
        TimeoutSec = $TimeoutSeconds
        UseBasicParsing = $true
        ErrorAction = 'Stop'
    }

    if ($null -ne $Body) {
        $Parameters.Body = $Body
    }

    $Response = Invoke-WebRequest @Parameters

    $Result.status = 'pass'
    $Result.http_status = [int]$Response.StatusCode

    $Content = Protect-ProxtelText `
        -Value ([string]$Response.Content)

    if ($Content.Length -gt 2048) {

        $Content = $Content.Substring(
            0,
            2048
        )

        $Result.warnings = @(
            'Response body truncated to 2048 characters.'
        )
    }

    $Result.body_summary = $Content
}
catch {

    $Result.status = 'error'

    $Result.warnings = @(
        (
            Protect-ProxtelText `
                -Value (
                    [string]$_.Exception.Message
                )
        )
    )
}
finally {

    $Result.duration_ms = [int](
        ([DateTime]::UtcNow - $Started).
        TotalMilliseconds
    )
}

$Result |
    ConvertTo-Json -Depth 12 -Compress |
    Write-Output

if ($Result.status -eq 'error') {
    exit 1
}

exit 0
