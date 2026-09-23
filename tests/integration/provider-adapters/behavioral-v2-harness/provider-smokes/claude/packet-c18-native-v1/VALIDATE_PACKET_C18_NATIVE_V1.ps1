& {
    $ErrorActionPreference = "Stop"

    $Agency = "C:\DEV\PROXTEL-AI-AGENCY"
    $PacketRoot = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\provider-smokes\claude\packet-c18-native-v1"
    $AdapterPath = Join-Path $Agency "adapters\claude\adapter.json"
    $PromptPath = Join-Path $PacketRoot "smoke-prompt.txt"
    $SchemaPath = Join-Path $PacketRoot "smoke-response.schema.json"
    $ManifestPath = Join-Path $PacketRoot "packet-manifest.json"
    $RunOncePath = Join-Path $PacketRoot "RUN_ONCE_NATIVE_CLAUDE_ADAPTER_SMOKE_C18.ps1"
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
    if ((Get-Sha -Path ([string]$Manifest.native_source.path)) -ne [string]$Manifest.native_source.sha256) { throw "STOP: native source hash mismatch." }

    if ([string]$Manifest.provider -ne "claude") { throw "STOP: provider mismatch." }
    if ([string]$Manifest.adapter_id -ne "claude") { throw "STOP: adapter id mismatch." }
    if ([string]$Manifest.transport -ne "native-executable-direct") { throw "STOP: transport mismatch." }
    if ([string]$Manifest.model_selection -ne "provider-default") { throw "STOP: model selection mismatch." }
    if ([bool]$Manifest.explicit_model_flag) { throw "STOP: explicit model flag forbidden." }
    if (-not [bool]$Manifest.one_model_call) { throw "STOP: one model call requirement missing." }
    if ([bool]$Manifest.automatic_retry) { throw "STOP: automatic retry forbidden." }
    if ([bool]$Manifest.dangerous_bypass) { throw "STOP: dangerous bypass forbidden." }
    if (-not [bool]$Manifest.isolated_temp_workdir) { throw "STOP: isolated TEMP workdir required." }
    if ([bool]$Manifest.repository_as_provider_workdir) { throw "STOP: repo provider workdir forbidden." }

    if ([string]$Adapter.cli.source -cne [string]$Manifest.native_source.path) { throw "STOP: adapter native source mismatch." }
    if ([string]$Adapter.lifecycle.execution_status -ne "not-executed") { throw "STOP: adapter execution_status drift." }
    if ([string]$Adapter.prompt_transport.mechanism -cne "--print") { throw "STOP: prompt mechanism mismatch." }
    if ([string]$Adapter.structured_output.format_mechanism -cne "--output-format json") { throw "STOP: format mechanism mismatch." }
    if ([string]$Adapter.structured_output.schema_mechanism -cne "--json-schema") { throw "STOP: schema mechanism mismatch." }

    $ForbiddenDangerousFlag = "--dangerously-" + "skip-permissions"
    if ($RunText.Contains($ForbiddenDangerousFlag)) { throw "STOP: run-once contains literal dangerous bypass flag." }
    if ($RunText -notmatch '\$DangerousArgCount') { throw "STOP: runtime dangerous-argv guard missing." }
    if ($RunText -notmatch '\$ExplicitModelArgCount') { throw "STOP: runtime explicit-model guard missing." }
    if ($RunText -notmatch '\$Psi\.FileName = \$NativeExe') { throw "STOP: direct native invocation missing." }
    if ($RunText -match 'powershell\.exe') { throw "STOP: run-once unexpectedly references powershell.exe provider launcher." }
    if ($RunText -notmatch 'exit \$Process\.ExitCode') { throw "STOP: provider exit-code propagation missing." }
    if ($RunText -notmatch 'provider-result\.json') { throw "STOP: provider-result evidence missing." }

    if (Test-Path -LiteralPath $LockPath) { throw "STOP: packet already consumed." }
    if (Test-Path -LiteralPath $RuntimeRoot) { throw "STOP: packet runtime already exists." }

    Write-Host "[PASS] PACKET_C18_NATIVE_V1_VALIDATION=PASS"
    Write-Host "PACKET_C18_NATIVE_V1_FRESH=YES"
    Write-Host "TRANSPORT=native-executable-direct"
    Write-Host "PROVIDER_MODEL_EXECUTED_NOW=NO"
    Write-Host "MODEL_CALLS_REQUESTED_NOW=0"
    Write-Host "NEXT_STAGE=1.2R-C19-VALIDATE-FRESH-NATIVE-CLAUDE-SMOKE-PACKET"
}