& {
    $ErrorActionPreference = "Stop"

    $Agency = "C:\DEV\PROXTEL-AI-AGENCY"
    $PacketRoot = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\provider-smokes\antigravity\packet-c31-v1"
    $AdapterPath = Join-Path $Agency "adapters\antigravity\adapter.json"
    $PromptPath = Join-Path $PacketRoot "smoke-prompt.txt"
    $SchemaPath = Join-Path $PacketRoot "smoke-response.schema.json"
    $ManifestPath = Join-Path $PacketRoot "packet-manifest.json"
    $RuntimeRoot = Join-Path $PacketRoot "runtime"
    $LockPath = Join-Path $PacketRoot "execution-lock.json"
    $StdoutPath = Join-Path $RuntimeRoot "agy-stdout.txt"
    $StderrPath = Join-Path $RuntimeRoot "agy-stderr.txt"
    $ProviderResultPath = Join-Path $RuntimeRoot "provider-result.json"

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

    try {
        $Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ((Get-Sha -Path $PromptPath) -ne [string]$Manifest.hashes.prompt_sha256) { throw "STOP: prompt hash mismatch." }
        if ((Get-Sha -Path $SchemaPath) -ne [string]$Manifest.hashes.schema_sha256) { throw "STOP: schema hash mismatch." }
        if ((Get-Sha -Path $AdapterPath) -ne [string]$Manifest.hashes.adapter_sha256) { throw "STOP: adapter hash mismatch." }

        if (Test-Path -LiteralPath $LockPath) { throw "STOP: packet already consumed." }
        if (Test-Path -LiteralPath $RuntimeRoot) { throw "STOP: packet runtime already exists." }

        $Adapter = Get-Content -LiteralPath $AdapterPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ([string]$Adapter.id -ne "antigravity" -or [string]$Adapter.provider -ne "antigravity") { throw "STOP: adapter identity mismatch." }
        if ([string]$Adapter.lifecycle.execution_status -ne "not-executed") { throw "STOP: adapter execution_status changed." }
        if ([string]$Adapter.cli.observed_version -ne "1.2.6") { throw "STOP: adapter observed_version drift." }
        if (-not [bool]$Adapter.prompt_transport.non_interactive) { throw "STOP: adapter non-interactive contract drift." }
        if ([string]$Adapter.prompt_transport.mechanism -cne "--print") { throw "STOP: prompt mechanism drift." }
        if (-not [bool]$Adapter.prompt_transport.positional_prompt) { throw "STOP: positional prompt contract drift." }
        if ([bool]$Adapter.prompt_transport.stdin_prompt) { throw "STOP: stdin prompt contract drift." }
        if ([string]$Adapter.structured_output.format_mechanism -cne "--output-format json") { throw "STOP: output-format mechanism drift." }
        if ([string]$Adapter.structured_output.schema_mechanism -cne "--json-schema") { throw "STOP: schema mechanism drift." }
        if ([string]$Adapter.structured_output.schema_transport -cne "inline-or-file") { throw "STOP: schema transport drift." }
        if ([string]$Adapter.structured_output.final_output_capture -cne "stdout") { throw "STOP: final output capture drift." }
        if (-not [bool]$Adapter.safety.dangerous_bypass_forbidden) { throw "STOP: dangerous bypass policy drift." }

        $AgyExe = [string]$Adapter.cli.source
        if ($AgyExe -cne [string]$Manifest.cli_source.path) { throw "STOP: agy path drift." }

        $InitialAgyHash = Get-Sha -Path $AgyExe
        if ($InitialAgyHash -ne [string]$Manifest.cli_source.sha256) { throw "STOP: agy initial hash drift." }

        $BlockedEnv = @(
            "GEMINI_API_KEY",
            "GOOGLE_API_KEY",
            "GOOGLE_APPLICATION_CREDENTIALS",
            "GOOGLE_GENAI_USE_VERTEXAI",
            "GOOGLE_CLOUD_PROJECT",
            "GOOGLE_CLOUD_LOCATION",
            "ANTIGRAVITY_API_KEY",
            "AGY_API_KEY",
            "AGY_BASE_URL"
        )

        foreach ($Name in $BlockedEnv) {
            $Value = [Environment]::GetEnvironmentVariable($Name)
            if (-not [string]::IsNullOrWhiteSpace($Value)) {
                throw ("STOP: known API/ADC/custom route environment variable present: " + $Name)
            }
        }

        $Prompt = [System.IO.File]::ReadAllText($PromptPath,[System.Text.Encoding]::UTF8)

        $CliArgs = @(
            "--print",
            $Prompt,
            "--output-format",
            "json",
            "--json-schema",
            $SchemaPath,
            "--sandbox"
        )

        $DangerousFlag = "--dangerously-" + "skip-permissions"
        $DangerousArgCount = @(
            $CliArgs |
            Where-Object { [string]$_ -ieq $DangerousFlag }
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

        $AddDirFlag = "--add-" + "dir"
        $AddDirArgCount = @(
            $CliArgs |
            Where-Object {
                ([string]$_ -ieq $AddDirFlag) -or
                ([string]$_ -like ($AddDirFlag + "=*"))
            }
        ).Count

        if ($AddDirArgCount -ne 0) {
            throw "STOP: --add-dir is not part of this no-file/no-tool smoke."
        }

        $QuotedArgs = @(
            $CliArgs |
            ForEach-Object { Quote-WindowsArg -Value ([string]$_) }
        )

        $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("PROXTEL-C31-ANTIGRAVITY-1.2.6-SMOKE-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
        New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null

        $PreLockAgyHash = Get-Sha -Path $AgyExe
        if ($PreLockAgyHash -ne [string]$Manifest.cli_source.sha256) {
            Remove-Item -LiteralPath $RuntimeRoot -Recurse -Force -ErrorAction SilentlyContinue
            throw "STOP: agy hash drifted before execution lock."
        }

        $PreLockItem = Get-Item -LiteralPath $AgyExe

        $Lock = [ordered]@{
            packet_id = [string]$Manifest.packet_id
            provider = "antigravity"
            adapter_id = "antigravity"
            transport = "agy-direct-sandbox-schema-file"
            adapter_sha256 = [string]$Manifest.hashes.adapter_sha256
            cli_sha256 = [string]$Manifest.cli_source.sha256
            cli_observed_version = "1.2.6"
            cli_source_last_write_utc_prestart = $PreLockItem.LastWriteTimeUtc.ToString("o")
            model_selection = "provider-default"
            explicit_model_flag = $false
            automatic_retry = $false
            dangerous_bypass = $false
            sandbox = $true
            add_dir = $false
            permission_semantics_assumed = $false
            consumed = $true
            started_utc = [DateTime]::UtcNow.ToString("o")
        }

        $LockJson = $Lock | ConvertTo-Json -Depth 30
        [System.IO.File]::WriteAllText($LockPath,$LockJson,(New-Object System.Text.UTF8Encoding($false)))

        $FinalPreStartAgyHash = Get-Sha -Path $AgyExe
        if ($FinalPreStartAgyHash -ne [string]$Manifest.cli_source.sha256) {
            throw "STOP: agy hash drifted after execution lock but before provider start. Packet is consumed; never retry."
        }

        $Psi = New-Object System.Diagnostics.ProcessStartInfo
        $Psi.FileName = $AgyExe
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

        $PostExitAgyHash = $null
        $PostExitLastWriteUtc = $null

        if (Test-Path -LiteralPath $AgyExe -PathType Leaf) {
            $PostExitAgyHash = Get-Sha -Path $AgyExe
            $PostExitLastWriteUtc = (Get-Item -LiteralPath $AgyExe).LastWriteTimeUtc.ToString("o")
        }

        $ProviderResult = [ordered]@{
            packet_id = [string]$Manifest.packet_id
            provider_process_starts = $ProviderProcessStarts
            model_calls_requested = 1
            provider_exit_code = $Process.ExitCode
            stdout_sha256 = Get-Sha -Path $StdoutPath
            stderr_sha256 = Get-Sha -Path $StderrPath
            cli_sha256_initial = $InitialAgyHash
            cli_sha256_prelock = $PreLockAgyHash
            cli_sha256_prestart = $FinalPreStartAgyHash
            cli_sha256_postexit_observed = $PostExitAgyHash
            cli_source_last_write_utc_postexit = $PostExitLastWriteUtc
            completed_utc = [DateTime]::UtcNow.ToString("o")
            automatic_retry_performed = $false
        }

        $ProviderResultJson = $ProviderResult | ConvertTo-Json -Depth 30
        [System.IO.File]::WriteAllText($ProviderResultPath,$ProviderResultJson,(New-Object System.Text.UTF8Encoding($false)))

        Write-Host ("PROVIDER_PROCESS_STARTS=" + $ProviderProcessStarts)
        Write-Host "MODEL_CALLS_REQUESTED=1"
        Write-Host ("AGY_EXIT_CODE=" + $Process.ExitCode)
        Write-Host ("AGY_STDOUT_SHA256=" + (Get-Sha -Path $StdoutPath))
        Write-Host ("AGY_STDERR_SHA256=" + (Get-Sha -Path $StderrPath))
        Write-Host ("PROVIDER_RESULT_SHA256=" + (Get-Sha -Path $ProviderResultPath))
        Write-Host ("EXECUTION_LOCK_SHA256=" + (Get-Sha -Path $LockPath))
        Write-Host ("AGY_SHA256_INITIAL=" + $InitialAgyHash)
        Write-Host ("AGY_SHA256_PRELOCK=" + $PreLockAgyHash)
        Write-Host ("AGY_SHA256_PRESTART=" + $FinalPreStartAgyHash)
        Write-Host ("AGY_SHA256_POSTEXIT_OBSERVED=" + [string]$PostExitAgyHash)
        Write-Host "PACKET_C31_V1_CONSUMED=YES"
        Write-Host "AUTOMATIC_RETRY_PERFORMED=NO"
        Write-Host "NEXT_STAGE=1.2R-C34-OFFLINE-ANTIGRAVITY-1.2.6-SMOKE-VALIDATION"

        exit $Process.ExitCode
    }
    catch {
        Write-Host "PACKET_C31_V1_RETRY_ALLOWED=NO"
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