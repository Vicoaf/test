& {
    $ErrorActionPreference = "Stop"

    $Agency = "C:\DEV\PROXTEL-AI-AGENCY"
    $PacketRoot = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\independent-audit-antigravity\fresh-governance-review-c37-v1"
    $PromptPath = Join-Path $PacketRoot "review-prompt.txt"
    $SchemaPath = Join-Path $PacketRoot "review-response.schema.json"
    $EvidencePath = Join-Path $PacketRoot "review-evidence.json"
    $ManifestPath = Join-Path $PacketRoot "packet-manifest.json"
    $CostGatePath = Join-Path $PacketRoot "zero-extra-cost-gate.json"
    $LockPath = Join-Path $PacketRoot "execution-lock.json"
    $RuntimeRoot = Join-Path $PacketRoot "runtime"
    $StdoutPath = Join-Path $RuntimeRoot "agy-stdout.txt"
    $StderrPath = Join-Path $RuntimeRoot "agy-stderr.txt"
    $ProviderResultPath = Join-Path $RuntimeRoot "provider-result.json"
    $AdapterPath = Join-Path $Agency "adapters\antigravity\adapter.json"
    $AuditorSkillJsonPath = Join-Path $Agency "skills\core\proxtel-skill-auditor\skill.json"
    $SkillsRegistryPath = Join-Path $Agency "skills\_registry\skills-registry.json"
    $HistoricalAdaptReportPath = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\independent-audit-antigravity\formal-reports\area-1.2\proxtel-skill-auditor-adapt-v1.json"
    $ClaudeSmokeReportPath = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\provider-smokes\claude\formal-reports\claude-native-live-smoke-c18-certification-v1.json"
    $AntigravitySmokeReportPath = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\provider-smokes\antigravity\formal-reports\antigravity-1.2.6-live-smoke-c31-certification-v1.json"

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

        if (Test-Path -LiteralPath $LockPath) { throw "STOP: packet already consumed." }
        if (Test-Path -LiteralPath $RuntimeRoot) { throw "STOP: packet runtime already exists." }

        if ((Get-Sha -Path $EvidencePath) -ne [string]$Manifest.packet_hashes.evidence_sha256) { throw "STOP: evidence hash mismatch." }
        if ((Get-Sha -Path $PromptPath) -ne [string]$Manifest.packet_hashes.prompt_sha256) { throw "STOP: prompt hash mismatch." }
        if ((Get-Sha -Path $SchemaPath) -ne [string]$Manifest.packet_hashes.schema_sha256) { throw "STOP: schema hash mismatch." }
        if ((Get-Sha -Path $AuditorSkillJsonPath) -ne [string]$Manifest.authoritative_hashes.auditor_skill_json_sha256) { throw "STOP: auditor skill hash drift." }
        if ((Get-Sha -Path $SkillsRegistryPath) -ne [string]$Manifest.authoritative_hashes.skills_registry_sha256) { throw "STOP: registry hash drift." }
        if ((Get-Sha -Path $HistoricalAdaptReportPath) -ne [string]$Manifest.authoritative_hashes.historical_adapt_report_sha256) { throw "STOP: historical ADAPT report hash drift." }
        if ((Get-Sha -Path $ClaudeSmokeReportPath) -ne [string]$Manifest.authoritative_hashes.claude_smoke_report_sha256) { throw "STOP: Claude smoke report hash drift." }
        if ((Get-Sha -Path $AntigravitySmokeReportPath) -ne [string]$Manifest.authoritative_hashes.antigravity_smoke_report_sha256) { throw "STOP: Antigravity smoke report hash drift." }
        if ((Get-Sha -Path $AdapterPath) -ne [string]$Manifest.authoritative_hashes.antigravity_adapter_sha256) { throw "STOP: Antigravity adapter hash drift." }

        $AgyExe = [string]$Manifest.cli_source.path
        $InitialAgyHash = Get-Sha -Path $AgyExe
        if ($InitialAgyHash -ne [string]$Manifest.cli_source.sha256) { throw "STOP: agy initial hash drift." }

        if (-not (Test-Path -LiteralPath $CostGatePath -PathType Leaf)) {
            throw "STOP: fresh zero-extra-cost route gate is missing. Live review is not authorized by packet state."
        }

        $CostGate = Get-Content -LiteralPath $CostGatePath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ([string]$CostGate.kind -ne "proxtel-zero-extra-cost-route-gate") { throw "STOP: zero-extra-cost gate kind mismatch." }
        if ([string]$CostGate.packet_id -ne [string]$Manifest.packet_id) { throw "STOP: zero-extra-cost gate packet binding mismatch." }
        if ([string]$CostGate.provider -ne "antigravity") { throw "STOP: zero-extra-cost gate provider mismatch." }
        if ([string]$CostGate.status -ne "PASS") { throw "STOP: zero-extra-cost gate status is not PASS." }
        if ([string]$CostGate.cli_sha256 -ne [string]$Manifest.cli_source.sha256) { throw "STOP: zero-extra-cost gate CLI hash mismatch." }
        if ([string]$CostGate.cli_version -ne [string]$Manifest.cli_source.version) { throw "STOP: zero-extra-cost gate CLI version mismatch." }
        if ([string]$CostGate.model_selection -ne "provider-default") { throw "STOP: zero-extra-cost gate model selection mismatch." }
        if ([bool]$CostGate.known_api_adc_custom_route_env_present) { throw "STOP: zero-extra-cost gate reports API/ADC/custom route env present." }
        if (-not [bool]$CostGate.subscription_route_evidence_verified) { throw "STOP: zero-extra-cost gate lacks verified subscription-route evidence." }
        if ([bool]$CostGate.extra_paid_api_route_required) { throw "STOP: zero-extra-cost gate reports extra paid API route required." }

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

        if ($Prompt.Length -gt 20000) { throw "STOP: prompt exceeds conservative argument budget." }

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
        if ($DangerousArgCount -ne 0) { throw "STOP: forbidden dangerous bypass argument present." }

        $ModelFlagName = "--mo" + "del"
        $ExplicitModelArgCount = @(
            $CliArgs |
            Where-Object {
                ([string]$_ -ieq $ModelFlagName) -or
                ([string]$_ -like ($ModelFlagName + "=*"))
            }
        ).Count
        if ($ExplicitModelArgCount -ne 0) { throw "STOP: explicit model argument present." }

        $AddDirFlag = "--add-" + "dir"
        $AddDirArgCount = @(
            $CliArgs |
            Where-Object {
                ([string]$_ -ieq $AddDirFlag) -or
                ([string]$_ -like ($AddDirFlag + "=*"))
            }
        ).Count
        if ($AddDirArgCount -ne 0) { throw "STOP: add-dir argument present." }

        $QuotedArgs = @(
            $CliArgs |
            ForEach-Object { Quote-WindowsArg -Value ([string]$_) }
        )

        $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("PROXTEL-C37-INDEPENDENT-REVIEW-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
        New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null

        $PreLockAgyHash = Get-Sha -Path $AgyExe
        if ($PreLockAgyHash -ne [string]$Manifest.cli_source.sha256) {
            Remove-Item -LiteralPath $RuntimeRoot -Recurse -Force -ErrorAction SilentlyContinue
            throw "STOP: agy hash drifted before execution lock."
        }

        $Lock = [ordered]@{
            packet_id = [string]$Manifest.packet_id
            subject_id = [string]$Manifest.subject_id
            reviewer_provider = [string]$Manifest.reviewer_provider
            review_nonce = [string]$Manifest.review_nonce
            transport = [string]$Manifest.transport
            evidence_sha256 = [string]$Manifest.packet_hashes.evidence_sha256
            prompt_sha256 = [string]$Manifest.packet_hashes.prompt_sha256
            schema_sha256 = [string]$Manifest.packet_hashes.schema_sha256
            cli_sha256 = [string]$Manifest.cli_source.sha256
            cli_version = [string]$Manifest.cli_source.version
            zero_extra_cost_gate_sha256 = Get-Sha -Path $CostGatePath
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
            throw "STOP: agy hash drifted after execution lock but before provider start. Packet consumed; never retry."
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
        if (Test-Path -LiteralPath $AgyExe -PathType Leaf) {
            $PostExitAgyHash = Get-Sha -Path $AgyExe
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
            completed_utc = [DateTime]::UtcNow.ToString("o")
            automatic_retry_performed = $false
        }

        $ProviderResultJson = $ProviderResult | ConvertTo-Json -Depth 30
        [System.IO.File]::WriteAllText($ProviderResultPath,$ProviderResultJson,(New-Object System.Text.UTF8Encoding($false)))

        Write-Host ("PROVIDER_PROCESS_STARTS=" + $ProviderProcessStarts)
        Write-Host "MODEL_CALLS_REQUESTED=1"
        Write-Host ("AGY_EXIT_CODE=" + $Process.ExitCode)
        Write-Host ("EXECUTION_LOCK_SHA256=" + (Get-Sha -Path $LockPath))
        Write-Host ("AGY_STDOUT_SHA256=" + (Get-Sha -Path $StdoutPath))
        Write-Host ("AGY_STDERR_SHA256=" + (Get-Sha -Path $StderrPath))
        Write-Host ("PROVIDER_RESULT_SHA256=" + (Get-Sha -Path $ProviderResultPath))
        Write-Host ("ZERO_EXTRA_COST_GATE_SHA256=" + (Get-Sha -Path $CostGatePath))
        Write-Host ("AGY_SHA256_INITIAL=" + $InitialAgyHash)
        Write-Host ("AGY_SHA256_PRELOCK=" + $PreLockAgyHash)
        Write-Host ("AGY_SHA256_PRESTART=" + $FinalPreStartAgyHash)
        Write-Host ("AGY_SHA256_POSTEXIT_OBSERVED=" + [string]$PostExitAgyHash)
        Write-Host "PACKET_C37_V1_CONSUMED=YES"
        Write-Host "AUTOMATIC_RETRY_PERFORMED=NO"
        Write-Host "NEXT_STAGE=1.2R-C41-OFFLINE-FRESH-INDEPENDENT-GOVERNANCE-REVIEW-VALIDATION"

        exit $Process.ExitCode
    }
    catch {
        Write-Host "PACKET_C37_V1_RETRY_ALLOWED=NO"
        Write-Host "AUTOMATIC_RETRY_PERFORMED=NO"
        if ($ProviderStarted) { Write-Host "PROVIDER_PROCESS_MAY_HAVE_STARTED=YES" }
        throw
    }
    finally {
        if ($null -ne $TempRoot -and (Test-Path -LiteralPath $TempRoot)) {
            Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}