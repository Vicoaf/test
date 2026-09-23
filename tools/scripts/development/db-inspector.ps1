[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$HostName,

    [ValidateRange(1,65535)]
    [int]$Port = 3306,

    [Parameter(Mandatory = $true)]
    [string]$Database,

    [Parameter(Mandatory = $true)]
    [string]$User,

    [Parameter(Mandatory = $true)]
    [Security.SecureString]$Password,

    [ValidateSet(
        'tables',
        'columns',
        'query'
    )]
    [string]$Operation = 'tables',

    [string]$Table,

    [string]$Query,

    [ValidateRange(1,1000)]
    [int]$MaxRows = 100,

    [ValidateRange(1,300)]
    [int]$TimeoutSeconds = 30,

    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

function Write-ProxtelResult {
    param($Value)

    $Value |
        ConvertTo-Json -Depth 20 -Compress |
        Write-Output
}

$Started = [DateTime]::UtcNow

$Result = [ordered]@{
    tool_id = 'db-inspector'
    status = 'preflight'
    connection_metadata_redacted = [ordered]@{
        host = $HostName
        port = $Port
        database = $Database
        user = $User
        password = '[REDACTED]'
    }
    operation = $Operation
    row_count = 0
    result = @()
    warnings = @()
    duration_ms = 0
}

try {

    $Php = Get-Command php -ErrorAction Stop

    $Helper = Join-Path `
        $PSScriptRoot `
        'helpers\db-inspector.php'

    if (-not (
        Test-Path `
            -LiteralPath $Helper `
            -PathType Leaf
    )) {
        throw 'db-inspector.php helper not found.'
    }

    if ($Operation -eq 'columns' -and
        [string]::IsNullOrWhiteSpace($Table)) {
        throw 'Table is required for columns operation.'
    }

    if ($Operation -eq 'query' -and
        [string]::IsNullOrWhiteSpace($Query)) {
        throw 'Query is required for query operation.'
    }

    if (-not $Execute) {

        $Result.status = 'dry-run'
        $Result.warnings = @(
            'Preflight only. No database connection was opened.'
        )

        $Result.duration_ms = [int](
            ([DateTime]::UtcNow - $Started).TotalMilliseconds
        )

        Write-ProxtelResult $Result
        exit 0
    }

    $Bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $Password
    )

    try {
        $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
            $Bstr
        )
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR(
            $Bstr
        )
    }

    $Request = [ordered]@{
        host = $HostName
        port = $Port
        database = $Database
        user = $User
        password = $PlainPassword
        operation = $Operation
        table = $Table
        query = $Query
        max_rows = $MaxRows
    }

    $RequestJson = $Request |
        ConvertTo-Json -Depth 10 -Compress

    $PlainPassword = $null
    $Request.password = $null

    $Psi = New-Object System.Diagnostics.ProcessStartInfo
    $Psi.FileName = $Php.Source
    $Psi.Arguments = '"' + $Helper + '"'
    $Psi.UseShellExecute = $false
    $Psi.CreateNoWindow = $true
    $Psi.RedirectStandardInput = $true
    $Psi.RedirectStandardOutput = $true
    $Psi.RedirectStandardError = $true

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $Psi

    if (-not $Process.Start()) {
        throw 'Unable to start PHP PDO helper.'
    }

    $Process.StandardInput.Write($RequestJson)
    $Process.StandardInput.Close()

    $StdoutTask = $Process.StandardOutput.ReadToEndAsync()
    $StderrTask = $Process.StandardError.ReadToEndAsync()

    if (-not $Process.WaitForExit($TimeoutSeconds * 1000)) {

        try {
            $Process.Kill()
        }
        catch {
        }

        throw "Database inspection timeout after $TimeoutSeconds seconds."
    }

    $Stdout = $StdoutTask.Result
    $Stderr = $StderrTask.Result

    if ($Process.ExitCode -ne 0) {
        throw (
            'PHP PDO helper failed: ' +
            $Stderr
        )
    }

    $HelperResult = $Stdout |
        ConvertFrom-Json

    $Result.status = [string]$HelperResult.status
    $Result.row_count = [int]$HelperResult.row_count
    $Result.result = @($HelperResult.result)
    $Result.warnings = @($HelperResult.warnings)
}
catch {

    $Result.status = 'error'
    $Result.warnings = @(
        $_.Exception.Message
    )
}
finally {

    $Result.duration_ms = [int](
        ([DateTime]::UtcNow - $Started).TotalMilliseconds
    )
}

Write-ProxtelResult $Result

if ($Result.status -eq 'error') {
    exit 1
}

exit 0
