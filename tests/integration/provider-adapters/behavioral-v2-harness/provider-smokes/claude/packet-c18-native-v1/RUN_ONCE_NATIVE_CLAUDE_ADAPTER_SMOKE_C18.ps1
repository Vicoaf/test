& {
    $ErrorActionPreference = "Stop"

    $Agency = "C:\DEV\PROXTEL-AI-AGENCY"
    $PacketRoot = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\provider-smokes\claude\packet-c18-native-v1"
    $AdapterPath = Join-Path $Agency "adapters\claude\adapter.json"
    $PromptPath = Join-Path $PacketRoot "smoke-prompt.txt"
    $SchemaPath = Join-Path $PacketRoot "smoke-response.schema.json"
    $ManifestPath = Join-Path $PacketRoot "packet-manifest.json"
    $RuntimeRoot = Join-Path $PacketRoot "runtime"
    $LockPath = Join-Path $PacketRoot "execution-lock.json"
    $StdoutPath = Join-Path $RuntimeRoot "claude-stdout.txt"
    $StderrPath = Join-Path $RuntimeRoot "claude-stderr.txt"
    $ResultPath = Join-Path $RuntimeRoot "provider-result.json"

    $TempRoot = $null
    $ProviderStarted = $false

    function Get-Sha {
        param([Parameter(Mandatory = $true)][string]$Path)
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }

    function Quote-WindowsArg {
        param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)
        if ($Value.Length -eq 0) { return '""' }
        if ($Value -notmatch '[\s"]') { return $Value }
        $Builder = New-Object System.Text.StringBuilder
        [void]$Builder.Append('"')
        $Backslashes = 0
        foreach ($Character in $Value.ToCharArray()) {
            if ($Character -eq '\') {
                $Backslashes++
                continue
            }
            if ($Character -eq '"') {
                [void]$Builder.Append(('\' * (($Backslashes * 2) + 1)))
                [void]$Builder.Append('"')
                $Backslashes = 0
                continue
            }
            if ($Backslashes -gt 0) {
                [void]$Builder.Append(('\' * $Backslashes))
                $Backslashes = 0
            }
            [void]$Builder.Append($Character)
        }
        if ($Backslashes -gt 0) {
            [void]$Builder.Append(('\' * ($Backslashes * 2)))
        }
        [void]$Builder.Append('"')
        return $Builder.ToString()
    }

    function Invoke-NativeReadOnly {
        param(
            [Parameter(Mandatory = $true)][string]$NativeExe,
            [Parameter(Mandatory = $true)][string[]]$ArgumentArray
        )
        $Quoted = @($ArgumentArray | ForEach-Object { Quote-WindowsArg -Value ([string]$_) })
        $Psi = New-Object System.Diagnostics.ProcessStartInfo
        $Psi.FileName = $NativeExe
        $Psi.Arguments = ($Quoted -join " ")
        $Psi.UseShellExecute = $false
        $Psi.RedirectStandardOutput = $true
        $Psi.RedirectStandardError = $true
        $Psi.CreateNoWindow = $true
        $Psi.WorkingDirectory = $Agency
        $P = New-Object System.Diagnostics.Process
        $P.StartInfo = $Psi
        [void]$P.Start()
        $Out = $P.StandardOutput.ReadToEnd()
        $Err = $P.StandardError.ReadToEnd()
        $P.WaitForExit()
        return [pscustomobject]@{ exit_code=$P.ExitCode; stdout=$Out; stderr=$Err }
    }

    try {
        $Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ((Get-Sha -Path $PromptPath) -ne [string]$Manifest.hashes.prompt_sha256) { throw "STOP: prompt hash mismatch." }
        if ((Get-Sha -Path $SchemaPath) -ne [string]$Manifest.hashes.schema_sha256) { throw "STOP: schema hash mismatch." }
        if ((Get-Sha -Path $AdapterPath) -ne [string]$Manifest.hashes.adapter_sha256) { throw "STOP: adapter hash mismatch." }

        if (Test-Path -LiteralPath $LockPath) { throw "STOP: packet already consumed." }
        if (Test-Path -LiteralPath $RuntimeRoot) { throw "STOP: packet runtime already exists." }

        $Adapter = Get-Content -LiteralPath $AdapterPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ([string]$Adapter.id -ne "claude" -or [string]$Adapter.provider -ne "claude") { throw "STOP: adapter identity mismatch." }
        if ([string]$Adapter.lifecycle.execution_status -ne "not-executed") { throw "STOP: adapter execution_status changed." }

        $NativeExe = [string]$Adapter.cli.source
        $PromptMechanism = [string]$Adapter.prompt_transport.mechanism
        $FormatMechanism = [string]$Adapter.structured_output.format_mechanism
        $SchemaMechanism = [string]$Adapter.structured_output.schema_mechanism

        if ($NativeExe -cne [string]$Manifest.native_source.path) { throw "STOP: native source path drift." }
        if ((Get-Sha -Path $NativeExe) -ne [string]$Manifest.native_source.sha256) { throw "STOP: native source hash drift." }
        if ($PromptMechanism -cne "--print") { throw "STOP: prompt mechanism drift." }
        if ($FormatMechanism -cne "--output-format json") { throw "STOP: format mechanism drift." }
        if ($SchemaMechanism -cne "--json-schema") { throw "STOP: schema mechanism drift." }
        if (-not [bool]$Adapter.safety.dangerous_bypass_forbidden) { throw "STOP: dangerous bypass policy drift." }

        $BlockedEnv = @("ANTHROPIC_API_KEY","ANTHROPIC_AUTH_TOKEN","ANTHROPIC_BASE_URL","CLAUDE_CODE_USE_BEDROCK","CLAUDE_CODE_USE_VERTEX","CLAUDE_CODE_USE_FOUNDRY")
        foreach ($Name in $BlockedEnv) {
            $Value = [Environment]::GetEnvironmentVariable($Name)
            if (-not [string]::IsNullOrWhiteSpace($Value)) {
                throw ("STOP: direct/external route environment variable present: " + $Name)
            }
        }

        $AuthResult = Invoke-NativeReadOnly -NativeExe $NativeExe -ArgumentArray @("auth","status")
        $AuthText = ([string]$AuthResult.stdout + [Environment]::NewLine + [string]$AuthResult.stderr).Trim()
        if ($AuthResult.exit_code -ne 0) { throw "STOP: native auth status failed." }
        $Auth = $AuthText | ConvertFrom-Json
        if (-not [bool]$Auth.loggedIn) { throw "STOP: Claude not logged in." }
        if ([string]$Auth.authMethod -ne "claude.ai") { throw "STOP: auth method drift." }
        if ([string]$Auth.apiProvider -ne "firstParty") { throw "STOP: API provider drift." }
        if ([string]$Auth.subscriptionType -ne "pro") { throw "STOP: subscription route drift." }

        $Prompt = [System.IO.File]::ReadAllText($PromptPath,[System.Text.Encoding]::UTF8)
        $SchemaObject = Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $SchemaJson = $SchemaObject | ConvertTo-Json -Depth 100 -Compress

        $CliArgs = @(
            $PromptMechanism,
            $Prompt,
            "--output-format",
            "json",
            $SchemaMechanism,
            $SchemaJson
        )

        $ForbiddenDangerousFlag = "--dangerously-" + "skip-permissions"
        $DangerousArgCount = @(
            $CliArgs |
            Where-Object { [string]$_ -ieq $ForbiddenDangerousFlag }
        ).Count

        if ($DangerousArgCount -ne 0) {
            throw "STOP: forbidden dangerous bypass argument present in actual argv."
        }

        $ModelFlagName = "--mo" + "del"
        $ExplicitModelArgCount = @(
            $CliArgs |
            Where-Object {
                ([string]$_ -ieq $ModelFlagName) -or
                ([string]$_ -like ($ModelFlagName + "=*"))
            }
        ).Count

        if ($ExplicitModelArgCount -ne 0) {
            throw "STOP: explicit model argument present in actual argv."
        }

        $QuotedArgs = @(
            $CliArgs |
            ForEach-Object { Quote-WindowsArg -Value ([string]$_) }
        )

        $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("PROXTEL-C18-NATIVE-CLAUDE-SMOKE-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
        New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null

        $Lock = [ordered]@{
            packet_id = [string]$Manifest.packet_id
            provider = "claude"
            adapter_id = "claude"
            transport = "native-executable-direct"
            adapter_sha256 = [string]$Manifest.hashes.adapter_sha256
            native_source_sha256 = [string]$Manifest.native_source.sha256
            model_selection = "provider-default"
            explicit_model_flag = $false
            automatic_retry = $false
            dangerous_bypass = $false
            consumed = $true
            started_utc = [DateTime]::UtcNow.ToString("o")
        }

        $LockJson = $Lock | ConvertTo-Json -Depth 30
        [System.IO.File]::WriteAllText($LockPath,$LockJson,(New-Object System.Text.UTF8Encoding($false)))

        $Psi = New-Object System.Diagnostics.ProcessStartInfo
        $Psi.FileName = $NativeExe
        $Psi.Arguments = ($QuotedArgs -join " ")
        $Psi.UseShellExecute = $false
        $Psi.RedirectStandardOutput = $true
        $Psi.RedirectStandardError = $true
        $Psi.CreateNoWindow = $true
        $Psi.WorkingDirectory = $TempRoot

        foreach ($Name in $BlockedEnv) {
            if ($Psi.EnvironmentVariables.ContainsKey($Name)) {
                $Psi.EnvironmentVariables.Remove($Name)
            }
        }

        $ProviderProcessStarts = 0
        $ProviderProcessStarts++

        $Process = New-Object System.Diagnostics.Process
        $Process.StartInfo = $Psi
        $ProviderStarted = $true
        [void]$Process.Start()

        $Stdout = $Process.StandardOutput.ReadToEnd()
        $Stderr = $Process.StandardError.ReadToEnd()
        $Process.WaitForExit()

        [System.IO.File]::WriteAllText($StdoutPath,$Stdout,(New-Object System.Text.UTF8Encoding($false)))
        [System.IO.File]::WriteAllText($StderrPath,$Stderr,(New-Object System.Text.UTF8Encoding($false)))

        $ProviderResult = [ordered]@{
            packet_id = [string]$Manifest.packet_id
            provider_process_starts = $ProviderProcessStarts
            model_calls_requested = 1
            provider_exit_code = $Process.ExitCode
            stdout_sha256 = Get-Sha -Path $StdoutPath
            stderr_sha256 = Get-Sha -Path $StderrPath
            completed_utc = [DateTime]::UtcNow.ToString("o")
            automatic_retry_performed = $false
        }

        $ProviderResultJson = $ProviderResult | ConvertTo-Json -Depth 30
        [System.IO.File]::WriteAllText($ResultPath,$ProviderResultJson,(New-Object System.Text.UTF8Encoding($false)))

        Write-Host ("PROVIDER_PROCESS_STARTS=" + $ProviderProcessStarts)
        Write-Host "MODEL_CALLS_REQUESTED=1"
        Write-Host ("CLAUDE_EXIT_CODE=" + $Process.ExitCode)
        Write-Host ("CLAUDE_STDOUT_SHA256=" + (Get-Sha -Path $StdoutPath))
        Write-Host ("CLAUDE_STDERR_SHA256=" + (Get-Sha -Path $StderrPath))
        Write-Host ("PROVIDER_RESULT_SHA256=" + (Get-Sha -Path $ResultPath))
        Write-Host ("EXECUTION_LOCK_SHA256=" + (Get-Sha -Path $LockPath))
        Write-Host "PACKET_C18_NATIVE_V1_CONSUMED=YES"
        Write-Host "AUTOMATIC_RETRY_PERFORMED=NO"
        Write-Host "NEXT_STAGE=1.2R-C21-OFFLINE-NATIVE-CLAUDE-SMOKE-VALIDATION"

        exit $Process.ExitCode
    }
    catch {
        Write-Host "PACKET_C18_NATIVE_V1_RETRY_ALLOWED=NO"
        Write-Host "AUTOMATIC_RETRY_PERFORMED=NO"
        if ($ProviderStarted) {
            Write-Host "PROVIDER_PROCESS_MAY_HAVE_STARTED=YES"
        }
        throw
    }
    finally {
        if ($null -ne $TempRoot -and (Test-Path -LiteralPath $TempRoot)) {
            Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}