param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'architecture',
        'backend-laravel-php',
        'frontend-web',
        'database-mysql',
        'api-integrations',
        'qa-browser',
        'accessibility',
        'performance',
        'seo-web-quality',
        'security',
        'documentation-release'
    )]
    [string]$Lane,

    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [string]$ProjectPath = (Get-Location).Path,

    [ValidateSet('auto','claude','codex','antigravity')]
    [string]$Provider = 'auto',

    [switch]$AllowWorkspaceWrite
)

$ErrorActionPreference = 'Stop'

$AgencyRoot =
    Split-Path -Parent (
        Split-Path -Parent $PSCommandPath
    )

$ActivationPath =
    Join-Path `
        $AgencyRoot `
        'config\development-execution-activation.json'

$BindingsPath =
    Join-Path `
        $AgencyRoot `
        'config\development-runtime-bindings.json'

$AdapterMap =
    @{
        claude =
            'adapters\claude\adapter.json'

        codex =
            'adapters\codex\adapter.json'

        antigravity =
            'adapters\antigravity\adapter.json'
    }

$KnownApiKeyNames =
    @(
        'ANTHROPIC_API_KEY',
        'OPENAI_API_KEY',
        'GOOGLE_API_KEY',
        'GEMINI_API_KEY'
    )

$Utf8NoBom =
    New-Object System.Text.UTF8Encoding($false)


function Read-JsonStrict {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (
        Test-Path `
            -LiteralPath $Path `
            -PathType Leaf
    )) {
        throw "PROXTEL STOP: missing file [$Path]."
    }

    $Raw =
        [string](
            Get-Content `
                -LiteralPath $Path `
                -Raw `
                -Encoding UTF8
        )

    if ([string]::IsNullOrWhiteSpace($Raw)) {
        throw "PROXTEL STOP: empty JSON [$Path]."
    }

    return (
        $Raw |
        ConvertFrom-Json `
            -ErrorAction Stop
    )
}


function Write-JsonNoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 100
    )

    $Text =
        $Object |
        ConvertTo-Json `
            -Depth $Depth

    [System.IO.File]::WriteAllText(
        $Path,
        ($Text + "`n"),
        $Utf8NoBom
    )
}


function Quote-Argument {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }

    return (
        '"' +
        $Value.Replace('"','\"') +
        '"'
    )
}


function Invoke-ProxtelProvider {
    param(
        [Parameter(Mandatory = $true)][string]$ProviderId,
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )

    $Executable = $Source
    $EffectiveArguments = @($Arguments)

    if (
        [System.IO.Path]::GetExtension($Source) -ieq
        '.ps1'
    ) {
        $Executable =
            Join-Path $PSHOME 'powershell.exe'

        $EffectiveArguments =
            @(
                '-NoProfile',
                '-NonInteractive',
                '-ExecutionPolicy',
                'Bypass',
                '-File',
                $Source
            ) + @($Arguments)
    }

    if (-not (
        Test-Path `
            -LiteralPath $Executable `
            -PathType Leaf
    )) {
        throw (
            "PROXTEL STOP: provider executable missing " +
            "[$ProviderId][$Executable]."
        )
    }

    $StartInfo =
        New-Object System.Diagnostics.ProcessStartInfo

    $StartInfo.FileName =
        $Executable

    $StartInfo.Arguments =
        (
            @(
                $EffectiveArguments |
                ForEach-Object {
                    Quote-Argument -Value ([string]$_)
                }
            ) -join ' '
        )

    $StartInfo.WorkingDirectory =
        $WorkingDirectory

    $StartInfo.UseShellExecute = $false
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $StartInfo.CreateNoWindow = $true

    foreach ($Name in $KnownApiKeyNames) {
        if (
            $StartInfo.EnvironmentVariables.ContainsKey($Name)
        ) {
            $StartInfo.EnvironmentVariables.Remove($Name)
        }
    }

    $Process =
        New-Object System.Diagnostics.Process

    $Process.StartInfo =
        $StartInfo

    if (-not $Process.Start()) {
        throw "PROXTEL STOP: could not start provider [$ProviderId]."
    }

    $StdoutTask =
        $Process.StandardOutput.ReadToEndAsync()

    $StderrTask =
        $Process.StandardError.ReadToEndAsync()

    $Completed =
        $Process.WaitForExit(300000)

    if (-not $Completed) {
        try {
            $Process.Kill()
        }
        catch {
        }

        throw (
            "PROXTEL STOP: provider timeout [$ProviderId]. " +
            'No automatic retry was performed.'
        )
    }

    $Process.WaitForExit()

    return [PSCustomObject]@{
        provider = $ProviderId
        exit_code = [int]$Process.ExitCode
        stdout = [string]$StdoutTask.Result
        stderr = [string]$StderrTask.Result
    }
}


function Test-IsSensitiveRelativePath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $Path =
        $RelativePath.Replace('\','/').ToLowerInvariant()

    $Leaf =
        [System.IO.Path]::GetFileName($Path)

    if (
        $Path.StartsWith('.git/') -or
        $Path.StartsWith('node_modules/') -or
        $Path.StartsWith('vendor/') -or
        $Path.StartsWith('storage/logs/') -or
        $Path.StartsWith('bootstrap/cache/')
    ) {
        return $true
    }

    if (
        $Leaf -eq '.env' -or
        $Leaf.StartsWith('.env.') -or
        $Leaf.EndsWith('.pem') -or
        $Leaf.EndsWith('.key') -or
        $Leaf.EndsWith('.pfx') -or
        $Leaf.EndsWith('.p12') -or
        $Leaf.StartsWith('id_rsa') -or
        $Leaf.Contains('credential') -or
        $Leaf.Contains('secret')
    ) {
        return $true
    }

    return $false
}


function Test-IsSnapshotTextFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $Leaf =
        [System.IO.Path]::GetFileName($Path).ToLowerInvariant()

    if (
        $Leaf -eq '.gitignore' -or
        $Leaf -eq '.editorconfig' -or
        $Leaf -eq 'dockerfile' -or
        $Leaf -eq 'makefile'
    ) {
        return $true
    }

    $Extension =
        [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    return (
        $Extension -in @(
            '.php',
            '.js',
            '.mjs',
            '.cjs',
            '.ts',
            '.tsx',
            '.jsx',
            '.vue',
            '.html',
            '.htm',
            '.css',
            '.scss',
            '.sass',
            '.less',
            '.json',
            '.md',
            '.txt',
            '.yml',
            '.yaml',
            '.xml',
            '.sql',
            '.sh',
            '.ps1',
            '.bat',
            '.cmd',
            '.ini',
            '.conf'
        )
    )
}


function Get-ProxtelSafeSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [int]$MaxFiles = 40,
        [int]$MaxPerFileChars = 12000,
        [int]$MaxTotalChars = 120000
    )

    $Root =
        [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')

    $Rows =
        @()

    $Files =
        @(
            Get-ChildItem `
                -LiteralPath $Root `
                -File `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue |
            Sort-Object FullName
        )

    $Total =
        0

    foreach ($File in $Files) {

        if ($Rows.Count -ge $MaxFiles) {
            break
        }

        $Relative =
            $File.FullName.
            Substring($Root.Length + 1).
            Replace('\','/')

        if (
            Test-IsSensitiveRelativePath `
                -RelativePath $Relative
        ) {
            continue
        }

        if (-not (
            Test-IsSnapshotTextFile `
                -Path $File.FullName
        )) {
            continue
        }

        try {
            $Content =
                [string](
                    Get-Content `
                        -LiteralPath $File.FullName `
                        -Raw `
                        -Encoding UTF8 `
                        -ErrorAction Stop
                )
        }
        catch {
            continue
        }

        if ($Content.Length -gt $MaxPerFileChars) {
            $Content =
                $Content.Substring(0,$MaxPerFileChars) +
                "`n[PROXTEL SNAPSHOT TRUNCATED FILE]"
        }

        $Entry = @"
===== FILE: $Relative =====
$Content
===== END FILE: $Relative =====
"@

        if (
            ($Total + $Entry.Length) -gt
            $MaxTotalChars
        ) {
            break
        }

        $Rows += $Entry
        $Total += $Entry.Length
    }

    if ($Rows.Count -eq 0) {
        throw (
            'PROXTEL STOP: no safe text files available for Antigravity snapshot.'
        )
    }

    return (
        [PSCustomObject]@{
            text = ($Rows -join "`n")
            file_count = $Rows.Count
            char_count = $Total
        }
    )
}


function New-CodexChangeSchema {
    param([Parameter(Mandatory = $true)][string]$Path)

    $Schema =
        [PSCustomObject][ordered]@{
            type = 'object'
            additionalProperties = $false
            required = @('status','summary','changes')

            properties =
                [PSCustomObject][ordered]@{
                    status =
                        [PSCustomObject][ordered]@{
                            type = 'string'
                            enum = @('READY','BLOCKED')
                        }

                    summary =
                        [PSCustomObject][ordered]@{
                            type = 'string'
                        }

                    changes =
                        [PSCustomObject][ordered]@{
                            type = 'array'
                            maxItems = 25

                            items =
                                [PSCustomObject][ordered]@{
                                    type = 'object'
                                    additionalProperties = $false
                                    required = @('path','content')

                                    properties =
                                        [PSCustomObject][ordered]@{
                                            path =
                                                [PSCustomObject][ordered]@{
                                                    type = 'string'
                                                    minLength = 1
                                                }

                                            content =
                                                [PSCustomObject][ordered]@{
                                                    type = 'string'
                                                }
                                        }
                                }
                        }
                }
        }

    Write-JsonNoBom `
        -Path $Path `
        -Object $Schema `
        -Depth 100
}


function Apply-CodexChangesTransactional {
    param(
        [Parameter(Mandatory = $true)]$ChangePlan,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if ([string]$ChangePlan.status -cne 'READY') {
        throw (
            'PROXTEL STOP: Codex returned BLOCKED; ' +
            [string]$ChangePlan.summary
        )
    }

    $Changes =
        @($ChangePlan.changes)

    if ($Changes.Count -eq 0) {
        throw 'PROXTEL STOP: Codex returned no changes.'
    }

    if ($Changes.Count -gt 25) {
        throw 'PROXTEL STOP: Codex returned more than 25 changes.'
    }

    $ProjectFull =
        [System.IO.Path]::GetFullPath(
            $ProjectRoot
        ).TrimEnd('\')

    $RequiredPrefix =
        $ProjectFull +
        [System.IO.Path]::DirectorySeparatorChar

    $TransactionRoot =
        Join-Path `
            ([System.IO.Path]::GetTempPath()) `
            (
                'proxtel-write-' +
                [guid]::NewGuid().ToString('N')
            )

    New-Item `
        -ItemType Directory `
        -Path $TransactionRoot `
        -Force |
        Out-Null

    $Prepared = @()

    try {

        $Seen = @{}

        foreach ($Change in $Changes) {

            $Relative =
                ([string]$Change.path).
                Replace('/','\').
                TrimStart('\')

            if (
                [string]::IsNullOrWhiteSpace($Relative) -or
                [System.IO.Path]::IsPathRooted($Relative)
            ) {
                throw "PROXTEL STOP: invalid Codex path [$Relative]."
            }

            $Target =
                [System.IO.Path]::GetFullPath(
                    (Join-Path $ProjectFull $Relative)
                )

            if (
                -not $Target.StartsWith(
                    $RequiredPrefix,
                    [System.StringComparison]::OrdinalIgnoreCase
                )
            ) {
                throw (
                    "PROXTEL STOP: Codex path escaped project [$Relative]."
                )
            }

            $ProjectRelative =
                $Target.
                Substring($RequiredPrefix.Length).
                Replace('\','/')

            if (
                $ProjectRelative -ieq '.git' -or
                $ProjectRelative.StartsWith(
                    '.git/',
                    [System.StringComparison]::OrdinalIgnoreCase
                )
            ) {
                throw 'PROXTEL STOP: Codex may not modify .git.'
            }

            if (
                Test-IsSensitiveRelativePath `
                    -RelativePath $ProjectRelative
            ) {
                throw (
                    "PROXTEL STOP: Codex attempted sensitive path " +
                    "[$ProjectRelative]."
                )
            }

            if ($Seen.ContainsKey($ProjectRelative)) {
                throw (
                    "PROXTEL STOP: duplicate Codex change [$ProjectRelative]."
                )
            }

            $Seen[$ProjectRelative] = $true

            $Existed =
                Test-Path `
                    -LiteralPath $Target `
                    -PathType Leaf

            $Backup =
                Join-Path `
                    $TransactionRoot `
                    (
                        [guid]::NewGuid().ToString('N') +
                        '.bak'
                    )

            if ($Existed) {
                [System.IO.File]::Copy(
                    $Target,
                    $Backup,
                    $true
                )
            }

            $Prepared +=
                [PSCustomObject]@{
                    relative = $ProjectRelative
                    target = $Target
                    existed = $Existed
                    backup = $Backup
                    content = [string]$Change.content
                }
        }

        foreach ($Item in $Prepared) {

            $Parent =
                Split-Path -Parent $Item.target

            if (-not (
                Test-Path `
                    -LiteralPath $Parent `
                    -PathType Container
            )) {
                New-Item `
                    -ItemType Directory `
                    -Path $Parent `
                    -Force |
                    Out-Null
            }

            [System.IO.File]::WriteAllText(
                $Item.target,
                [string]$Item.content,
                $Utf8NoBom
            )
        }

        return @(
            $Prepared |
            ForEach-Object {
                [string]$_.relative
            }
        )
    }
    catch {

        foreach (
            $Item in
            @($Prepared | Select-Object -Reverse)
        ) {
            try {
                if ([bool]$Item.existed) {
                    [System.IO.File]::Copy(
                        [string]$Item.backup,
                        [string]$Item.target,
                        $true
                    )
                }
                else {
                    $Exists =
                        Test-Path `
                            -LiteralPath ([string]$Item.target)

                    if ($Exists) {
                        Remove-Item `
                            -LiteralPath ([string]$Item.target) `
                            -Force `
                            -ErrorAction SilentlyContinue
                    }
                }
            }
            catch {
            }
        }

        throw
    }
    finally {
        $TransactionExists =
            Test-Path `
                -LiteralPath $TransactionRoot

        if ($TransactionExists) {
            Remove-Item `
                -LiteralPath $TransactionRoot `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}


$Activation =
    Read-JsonStrict `
        -Path $ActivationPath

if ([string]$Activation.status -cne 'active') {
    throw (
        'PROXTEL STOP: Development execution layer is not active.'
    )
}

if (
    $Activation.execution.provider_execution -ne $true -or
    $Activation.execution.model_execution -ne $true
) {
    throw (
        'PROXTEL STOP: provider/model execution is not authorized.'
    )
}

if (
    $Activation.safety.automatic_live_retry -ne $false -or
    $Activation.safety.automatic_commit -ne $false -or
    $Activation.safety.automatic_push -ne $false -or
    $Activation.safety.automatic_deploy -ne $false
) {
    throw 'PROXTEL STOP: execution safety contract is invalid.'
}

$ResolvedProject =
    [System.IO.Path]::GetFullPath($ProjectPath)

if (-not (
    Test-Path `
        -LiteralPath $ResolvedProject `
        -PathType Container
)) {
    throw (
        "PROXTEL STOP: project path does not exist " +
        "[$ResolvedProject]."
    )
}

$Bindings =
    Read-JsonStrict `
        -Path $BindingsPath

$Binding =
    @(
        $Bindings.bindings |
        Where-Object {
            [string]$_.lane -ceq $Lane
        }
    ) |
    Select-Object -First 1

if ($null -eq $Binding) {
    throw "PROXTEL STOP: lane not found [$Lane]."
}

$SelectedProvider = $Provider

if ($SelectedProvider -ceq 'auto') {
    $SelectedProvider =
        [string]$Binding.preferred_provider
}

if (
    $SelectedProvider -notin
    @('claude','codex','antigravity')
) {
    throw (
        "PROXTEL STOP: unsupported provider " +
        "[$SelectedProvider]."
    )
}

if (
    $AllowWorkspaceWrite -and
    $SelectedProvider -cne 'codex'
) {
    throw (
        'PROXTEL STOP: -AllowWorkspaceWrite is only supported for Codex.'
    )
}

$AdapterPath =
    Join-Path `
        $AgencyRoot `
        $AdapterMap[$SelectedProvider]

$Adapter =
    Read-JsonStrict `
        -Path $AdapterPath

$ProviderSource =
    [string]$Adapter.cli.source

$ExecutorId =
    [string]$Binding.executor_id

$AgencyPrompt = @"
PROXTEL AI AGENCY - DEVELOPMENT EXECUTION

LANE: $Lane
EXECUTOR: $ExecutorId
PROVIDER: $SelectedProvider
PROJECT: $ResolvedProject

OPERATING RULES:
- Work only on the explicit user task below.
- Inspect before modifying.
- Local-first.
- Do not install dependencies unless explicitly requested.
- Do not use external paid APIs.
- Do not run git add, git commit, git push or deploy.
- Do not perform production mutations.
- Do not retry provider/model execution automatically after failure.
- Preserve existing project conventions.

USER TASK:
$Prompt
"@

$Arguments = @()
$TemporaryOutput = $null
$TemporarySchema = $null
$TemporaryWorkingDirectory = $null

switch ($SelectedProvider) {

    'claude' {

        if ($AllowWorkspaceWrite) {
            throw (
                'PROXTEL STOP: Claude launcher mode is planning/review only.'
            )
        }

        $Arguments =
            @(
                '--print',
                $AgencyPrompt,
                '--output-format',
                'json',
                '--permission-mode',
                'plan',
                '--max-turns',
                '6'
            )
    }

    'codex' {

        $TemporaryOutput =
            Join-Path `
                ([System.IO.Path]::GetTempPath()) `
                (
                    'proxtel-codex-result-' +
                    [guid]::NewGuid().ToString('N') +
                    '.json'
                )

        if ($AllowWorkspaceWrite) {

            $TemporarySchema =
                Join-Path `
                    ([System.IO.Path]::GetTempPath()) `
                    (
                        'proxtel-codex-schema-' +
                        [guid]::NewGuid().ToString('N') +
                        '.json'
                    )

            New-CodexChangeSchema `
                -Path $TemporarySchema

            $WritePrompt = @"
$AgencyPrompt

CONTROLLED WRITE MODE:
Do NOT write to the filesystem yourself.
Inspect the project read-only.
Return a structured change plan matching the supplied JSON schema.

For every file to create or replace, return:
- path: project-relative path only
- content: COMPLETE final UTF-8 text

Do not request deletions.
Do not include .git paths.
Do not include secrets or credential files.
If unsafe, return status BLOCKED and an empty changes array.
"@

            $Arguments =
                @(
                    'exec',
                    $WritePrompt,
                    '--output-schema',
                    $TemporarySchema,
                    '--output-last-message',
                    $TemporaryOutput,
                    '--sandbox',
                    'read-only',
                    '-C',
                    $ResolvedProject
                )
        }
        else {

            $Arguments =
                @(
                    'exec',
                    $AgencyPrompt,
                    '--output-last-message',
                    $TemporaryOutput,
                    '--sandbox',
                    'read-only',
                    '-C',
                    $ResolvedProject
                )
        }
    }

    'antigravity' {

        if ($AllowWorkspaceWrite) {
            throw (
                'PROXTEL STOP: Antigravity launcher mode is audit/review only.'
            )
        }

        $Snapshot =
            Get-ProxtelSafeSnapshot `
                -ProjectRoot $ResolvedProject

        $AgyPrompt = @"
$AgencyPrompt

PROXTEL SAFE LOCAL SNAPSHOT
The following project context was collected locally by PROXTEL.
Do NOT call file-reading, shell, browser, URL, or write tools.
Audit ONLY the supplied snapshot.
Sensitive files, .git, dependencies, and log/cache directories are excluded.

SNAPSHOT_FILE_COUNT=$($Snapshot.file_count)
SNAPSHOT_CHAR_COUNT=$($Snapshot.char_count)

$($Snapshot.text)
"@

        $TemporaryWorkingDirectory =
            Join-Path `
                ([System.IO.Path]::GetTempPath()) `
                (
                    'proxtel-agy-' +
                    [guid]::NewGuid().ToString('N')
                )

        New-Item `
            -ItemType Directory `
            -Path $TemporaryWorkingDirectory `
            -Force |
            Out-Null

        $Arguments =
            @(
                '--print',
                $AgyPrompt,
                '--output-format',
                'json',
                '--sandbox',
                '--mode',
                'plan'
            )
    }
}

$ProviderWorkingDirectory =
    $ResolvedProject

if (
    $SelectedProvider -ceq 'antigravity'
) {
    $ProviderWorkingDirectory =
        $TemporaryWorkingDirectory
}

Write-Host
Write-Host '============================================================'
Write-Host ' PROXTEL AI AGENCY - DEVELOPMENT'
Write-Host '============================================================'
Write-Host "LANE=$Lane"
Write-Host "EXECUTOR=$ExecutorId"
Write-Host "PROVIDER=$SelectedProvider"
Write-Host "PROJECT=$ResolvedProject"
Write-Host (
    'WORKSPACE_WRITE=' +
    $(if ($AllowWorkspaceWrite) {
        'YES-CONTROLLED-TRANSACTIONAL'
    }
    else {
        'NO'
    })
)
Write-Host 'AUTOMATIC_RETRY=NO'
Write-Host 'AUTOMATIC_COMMIT=NO'
Write-Host 'AUTOMATIC_PUSH=NO'
Write-Host 'AUTOMATIC_DEPLOY=NO'
Write-Host '============================================================'
Write-Host

try {

    $Result =
        Invoke-ProxtelProvider `
            -ProviderId $SelectedProvider `
            -Source $ProviderSource `
            -Arguments $Arguments `
            -WorkingDirectory $ProviderWorkingDirectory

    if ([int]$Result.exit_code -ne 0) {
        Write-Host $Result.stderr

        throw (
            "PROXTEL STOP: provider [$SelectedProvider] " +
            "returned exit [$($Result.exit_code)]. " +
            'No automatic retry was performed.'
        )
    }

    if ($SelectedProvider -ceq 'antigravity') {

        $AgyJson =
            ([string]$Result.stdout) |
            ConvertFrom-Json `
                -ErrorAction Stop

        if ([string]$AgyJson.status -cne 'SUCCESS') {
            throw (
                'PROXTEL STOP: Antigravity status is not SUCCESS.'
            )
        }

        $ActionableDenied =
            @(
                @($AgyJson.denied_actions) |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$_.action
                    ) -or
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$_.display_name
                    )
                }
            )

        if ($ActionableDenied.Count -ne 0) {

            foreach ($Denied in $ActionableDenied) {
                Write-Host (
                    "ANTIGRAVITY_DENIED_ACTION " +
                    "action=[$([string]$Denied.action)] " +
                    "display=[$([string]$Denied.display_name)]"
                )
            }

            throw (
                'PROXTEL STOP: Antigravity attempted an actionable denied ' +
                'tool action. Snapshot-only mode forbids tool access.'
            )
        }

        Write-Output ([string]$AgyJson.response)
    }
    elseif (
        $SelectedProvider -ceq 'codex' -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$TemporaryOutput
        )
    ) {

        if (-not (
            Test-Path `
                -LiteralPath $TemporaryOutput `
                -PathType Leaf
        )) {
            throw 'PROXTEL STOP: Codex final output file is missing.'
        }

        $CodexRaw =
            [string](
                Get-Content `
                    -LiteralPath $TemporaryOutput `
                    -Raw `
                    -Encoding UTF8
            )

        if ($AllowWorkspaceWrite) {

            $WritePlan =
                $CodexRaw |
                ConvertFrom-Json `
                    -ErrorAction Stop

            $Applied =
                @(
                    Apply-CodexChangesTransactional `
                        -ChangePlan $WritePlan `
                        -ProjectRoot $ResolvedProject
                )

            Write-Host "CODEX_APPLIED_FILE_COUNT=$($Applied.Count)"

            foreach ($Path in $Applied) {
                Write-Host "CODEX_APPLIED_FILE=[$Path]"
            }

            Write-Host
            Write-Host (
                'CODEX_SUMMARY=' +
                [string]$WritePlan.summary
            )
        }
        else {
            Write-Output $CodexRaw
        }
    }
    else {
        Write-Output $Result.stdout
    }

    Write-Host
    Write-Host '[PASS] PROXTEL AGENCY TASK COMPLETE'
}
finally {

    foreach ($Path in @(
        $TemporaryOutput,
        $TemporarySchema
    )) {
        if (
            -not [string]::IsNullOrWhiteSpace(
                [string]$Path
            )
        ) {
            $Exists =
                Test-Path `
                    -LiteralPath $Path

            if ($Exists) {
                Remove-Item `
                    -LiteralPath $Path `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$TemporaryWorkingDirectory
        )
    ) {
        $TempDirExists =
            Test-Path `
                -LiteralPath $TemporaryWorkingDirectory `
                -PathType Container

        if ($TempDirExists) {
            Remove-Item `
                -LiteralPath $TemporaryWorkingDirectory `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}
