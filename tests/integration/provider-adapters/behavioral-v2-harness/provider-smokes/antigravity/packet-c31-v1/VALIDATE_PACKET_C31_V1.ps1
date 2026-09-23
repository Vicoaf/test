& {
    $ErrorActionPreference = "Stop"

    $Agency = "C:\DEV\PROXTEL-AI-AGENCY"
    $PacketRoot = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\provider-smokes\antigravity\packet-c31-v1"
    $AdapterPath = Join-Path $Agency "adapters\antigravity\adapter.json"
    $PromptPath = Join-Path $PacketRoot "smoke-prompt.txt"
    $SchemaPath = Join-Path $PacketRoot "smoke-response.schema.json"
    $ManifestPath = Join-Path $PacketRoot "packet-manifest.json"
    $RunOncePath = Join-Path $PacketRoot "RUN_ONCE_ANTIGRAVITY_1_2_6_ADAPTER_SMOKE_C31.ps1"
    $LockPath = Join-Path $PacketRoot "execution-lock.json"
    $RuntimeRoot = Join-Path $PacketRoot "runtime"

    function Get-Sha {
        param([Parameter(Mandatory = $true)][string]$Path)
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }

    $Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Adapter = Get-Content -LiteralPath $AdapterPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $RunText = [System.IO.File]::ReadAllText($RunOncePath,[System.Text.Encoding]::UTF8)

    if ((Get-Sha -Path $PromptPath) -ne [string]$Manifest.hashes.prompt_sha256) { throw "STOP: prompt hash mismatch." }
    if ((Get-Sha -Path $SchemaPath) -ne [string]$Manifest.hashes.schema_sha256) { throw "STOP: schema hash mismatch." }
    if ((Get-Sha -Path $AdapterPath) -ne [string]$Manifest.hashes.adapter_sha256) { throw "STOP: adapter hash mismatch." }
    if ((Get-Sha -Path ([string]$Manifest.cli_source.path)) -ne [string]$Manifest.cli_source.sha256) { throw "STOP: agy hash mismatch." }

    if ([string]$Manifest.provider -ne "antigravity") { throw "STOP: provider mismatch." }
    if ([string]$Manifest.adapter_id -ne "antigravity") { throw "STOP: adapter mismatch." }
    if ([string]$Manifest.transport -ne "agy-direct-sandbox-schema-file") { throw "STOP: transport mismatch." }
    if ([string]$Manifest.model_selection -ne "provider-default") { throw "STOP: model selection mismatch." }
    if ([bool]$Manifest.explicit_model_flag) { throw "STOP: explicit model flag forbidden." }
    if (-not [bool]$Manifest.one_model_call) { throw "STOP: one model call requirement missing." }
    if ([bool]$Manifest.automatic_retry) { throw "STOP: automatic retry forbidden." }
    if ([bool]$Manifest.dangerous_bypass) { throw "STOP: dangerous bypass forbidden." }
    if (-not [bool]$Manifest.sandbox) { throw "STOP: sandbox required." }
    if ([bool]$Manifest.add_dir) { throw "STOP: add-dir forbidden for this smoke." }
    if ([bool]$Manifest.permission_semantics_assumed) { throw "STOP: permission semantics must not be assumed." }
    if (-not [bool]$Manifest.isolated_temp_workdir) { throw "STOP: isolated TEMP workdir required." }
    if ([bool]$Manifest.repository_as_provider_workdir) { throw "STOP: repo provider workdir forbidden." }
    if ([string]$Manifest.schema_transport -ne "file") { throw "STOP: schema transport mismatch." }

    if ([string]$Manifest.cli_source.version -ne "1.2.6") { throw "STOP: manifest cli version mismatch." }
    if ([string]$Adapter.cli.observed_version -ne "1.2.6") { throw "STOP: adapter observed_version mismatch." }
    if ([string]$Adapter.cli.source -cne [string]$Manifest.cli_source.path) { throw "STOP: adapter agy source mismatch." }
    if ([string]$Adapter.lifecycle.execution_status -ne "not-executed") { throw "STOP: adapter execution status drift." }

    if (-not [bool]$Manifest.cli_drift_controls.initial_hash_gate) { throw "STOP: initial hash gate missing." }
    if (-not [bool]$Manifest.cli_drift_controls.prelock_hash_gate) { throw "STOP: prelock hash gate missing." }
    if (-not [bool]$Manifest.cli_drift_controls.prestart_hash_gate) { throw "STOP: prestart hash gate missing." }
    if (-not [bool]$Manifest.cli_drift_controls.postexit_hash_observation) { throw "STOP: postexit hash observation missing." }
    if ([bool]$Manifest.cli_drift_controls.in_memory_process_image_hash_proven) { throw "STOP: manifest must not claim in-memory image hash proof." }

    $DangerousFlag = "--dangerously-" + "skip-permissions"
    if ($RunText.Contains($DangerousFlag)) { throw "STOP: run-once contains literal dangerous bypass flag." }
    if ($RunText -notmatch '\$DangerousArgCount') { throw "STOP: dangerous argv guard missing." }
    if ($RunText -notmatch '\$ExplicitModelArgCount') { throw "STOP: explicit-model argv guard missing." }
    if ($RunText -notmatch '\$AddDirArgCount') { throw "STOP: add-dir argv guard missing." }
    if ($RunText -notmatch '\$InitialAgyHash') { throw "STOP: initial agy hash gate missing." }
    if ($RunText -notmatch '\$PreLockAgyHash') { throw "STOP: prelock agy hash gate missing." }
    if ($RunText -notmatch '\$FinalPreStartAgyHash') { throw "STOP: prestart agy hash gate missing." }
    if ($RunText -notmatch '\$PostExitAgyHash') { throw "STOP: postexit agy hash observation missing." }
    if ($RunText -notmatch '"--sandbox"') { throw "STOP: sandbox argv missing." }
    if ($RunText -notmatch '\$Psi\.FileName = \$AgyExe') { throw "STOP: direct agy invocation missing." }
    if ($RunText -notmatch 'provider-result\.json') { throw "STOP: provider-result evidence missing." }
    if ($RunText -notmatch 'exit \$Process\.ExitCode') { throw "STOP: provider exit-code propagation missing." }

    if (Test-Path -LiteralPath $LockPath) { throw "STOP: packet already consumed." }
    if (Test-Path -LiteralPath $RuntimeRoot) { throw "STOP: packet runtime already exists." }

    Write-Host "[PASS] PACKET_C31_V1_VALIDATION=PASS"
    Write-Host "PACKET_C31_V1_FRESH=YES"
    Write-Host "TRANSPORT=agy-direct-sandbox-schema-file"
    Write-Host "SCHEMA_TRANSPORT=file"
    Write-Host "ADAPTER_OBSERVED_VERSION=1.2.6"
    Write-Host "CLI_DRIFT_CONTROLS=INITIAL+PRELOCK+PRESTART+POSTEXIT"
    Write-Host "IN_MEMORY_PROCESS_IMAGE_HASH_PROVEN=NO"
    Write-Host "PERMISSION_SEMANTICS_ASSUMED=NO"
    Write-Host "PROVIDER_MODEL_EXECUTED_NOW=NO"
    Write-Host "MODEL_CALLS_REQUESTED_NOW=0"
    Write-Host "NEXT_STAGE=1.2R-C32-VALIDATE-FRESH-ANTIGRAVITY-1.2.6-SMOKE-PACKET"
}