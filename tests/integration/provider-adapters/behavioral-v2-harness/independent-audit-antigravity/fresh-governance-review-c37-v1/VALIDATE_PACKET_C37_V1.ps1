& {
    $ErrorActionPreference = "Stop"

    $Agency = "C:\DEV\PROXTEL-AI-AGENCY"
    $PacketRoot = Join-Path $Agency "tests\integration\provider-adapters\behavioral-v2-harness\independent-audit-antigravity\fresh-governance-review-c37-v1"
    $EvidencePath = Join-Path $PacketRoot "review-evidence.json"
    $PromptPath = Join-Path $PacketRoot "review-prompt.txt"
    $SchemaPath = Join-Path $PacketRoot "review-response.schema.json"
    $ManifestPath = Join-Path $PacketRoot "packet-manifest.json"
    $RunOncePath = Join-Path $PacketRoot "RUN_ONCE_FRESH_INDEPENDENT_GOVERNANCE_REVIEW_C37.ps1"
    $CostGatePath = Join-Path $PacketRoot "zero-extra-cost-gate.json"
    $LockPath = Join-Path $PacketRoot "execution-lock.json"
    $RuntimeRoot = Join-Path $PacketRoot "runtime"

    function Get-Sha {
        param([Parameter(Mandatory = $true)][string]$Path)
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }

    $Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Evidence = Get-Content -LiteralPath $EvidencePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Schema = Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Prompt = [System.IO.File]::ReadAllText($PromptPath,[System.Text.Encoding]::UTF8)
    $RunText = [System.IO.File]::ReadAllText($RunOncePath,[System.Text.Encoding]::UTF8)

    if ((Get-Sha -Path $EvidencePath) -ne [string]$Manifest.packet_hashes.evidence_sha256) { throw "STOP: evidence hash mismatch." }
    if ((Get-Sha -Path $PromptPath) -ne [string]$Manifest.packet_hashes.prompt_sha256) { throw "STOP: prompt hash mismatch." }
    if ((Get-Sha -Path $SchemaPath) -ne [string]$Manifest.packet_hashes.schema_sha256) { throw "STOP: schema hash mismatch." }

    if ([string]$Manifest.packet_id -ne "PROXTEL-AREA-1.2-AUDITOR-FRESH-INDEPENDENT-GOVERNANCE-REVIEW-C37-V1") { throw "STOP: packet id mismatch." }
    if ([string]$Manifest.subject_id -ne "proxtel-skill-auditor") { throw "STOP: subject mismatch." }
    if ([string]$Manifest.reviewer_provider -ne "antigravity") { throw "STOP: reviewer provider mismatch." }
    if ([string]$Manifest.review_nonce -ne "PROXTEL-C37-AUDITOR-FRESH-INDEPENDENT-GOVERNANCE-REVIEW-V1") { throw "STOP: nonce mismatch." }
    if ([string]$Manifest.input_mode -ne "self-contained-evidence-prompt") { throw "STOP: input mode mismatch." }
    if ([bool]$Manifest.tools_required) { throw "STOP: tools_required must be false." }
    if ([bool]$Manifest.read_file_required) { throw "STOP: read_file_required must be false." }
    if ([bool]$Manifest.mcp_required) { throw "STOP: mcp_required must be false." }
    if ([bool]$Manifest.web_required) { throw "STOP: web_required must be false." }
    if ([string]$Manifest.model_selection -ne "provider-default") { throw "STOP: model selection mismatch." }
    if ([bool]$Manifest.explicit_model_flag) { throw "STOP: explicit model flag forbidden." }
    if (-not [bool]$Manifest.one_model_call) { throw "STOP: one model call requirement missing." }
    if ([bool]$Manifest.automatic_retry) { throw "STOP: automatic retry forbidden." }
    if ([bool]$Manifest.dangerous_bypass) { throw "STOP: dangerous bypass forbidden." }
    if (-not [bool]$Manifest.sandbox) { throw "STOP: sandbox required." }
    if ([bool]$Manifest.add_dir) { throw "STOP: add-dir forbidden." }
    if ([bool]$Manifest.permission_semantics_assumed) { throw "STOP: permission semantics must not be assumed." }
    if (-not [bool]$Manifest.zero_extra_cost_route_gate_required_before_live) { throw "STOP: zero-extra-cost gate requirement missing." }
    if ([string]$Manifest.zero_extra_cost_gate_status_at_build -ne "PENDING") { throw "STOP: build-time cost gate status must be PENDING." }

    if ([string]$Evidence.subject.id -ne "proxtel-skill-auditor") { throw "STOP: evidence subject mismatch." }
    if ([string]$Evidence.historical_independent_review.decision -ne "ADAPT") { throw "STOP: historical decision mismatch." }
    if ([string]$Evidence.remediation_evidence.action_0.status -ne "SATISFIED") { throw "STOP: action 0 evidence mismatch." }
    if ([string]$Evidence.remediation_evidence.action_1.status -ne "SATISFIED") { throw "STOP: action 1 evidence mismatch." }
    if ([string]$Evidence.remediation_evidence.action_2.status -ne "DEFERRED") { throw "STOP: action 2 evidence mismatch." }
    if ([string]$Evidence.remediation_evidence.action_3.status -ne "SATISFIED") { throw "STOP: action 3 evidence mismatch." }

    if (-not $Prompt.Contains("BEGIN_SELF_CONTAINED_EVIDENCE_JSON")) { throw "STOP: evidence begin marker missing." }
    if (-not $Prompt.Contains("END_SELF_CONTAINED_EVIDENCE_JSON")) { throw "STOP: evidence end marker missing." }
    $EvidenceRaw = [System.IO.File]::ReadAllText($EvidencePath,[System.Text.Encoding]::UTF8)
    if (-not $Prompt.Contains($EvidenceRaw)) { throw "STOP: prompt does not contain byte-decoded self-contained evidence text." }
    if ($Prompt.Length -gt 20000) { throw "STOP: prompt exceeds conservative argument budget." }

    if ([string]$Schema.properties.review_nonce.enum[0] -ne "PROXTEL-C37-AUDITOR-FRESH-INDEPENDENT-GOVERNANCE-REVIEW-V1") { throw "STOP: response schema nonce mismatch." }
    if ([string]$Schema.properties.audit_status.enum[0] -ne "FINAL") { throw "STOP: response schema audit_status mismatch." }

    $DecisionEnums = @($Schema.properties.final_decision.enum)
    foreach ($Decision in @("APPROVED","ADAPT","REFERENCE-ONLY","REJECTED")) {
        if ($DecisionEnums -notcontains $Decision) { throw ("STOP: response schema missing decision enum " + $Decision) }
    }

    $DangerousFlag = "--dangerously-" + "skip-permissions"
    if ($RunText.Contains($DangerousFlag)) { throw "STOP: run-once contains literal dangerous bypass flag." }
    if ($RunText -notmatch '\$DangerousArgCount') { throw "STOP: dangerous argv guard missing." }
    if ($RunText -notmatch '\$ExplicitModelArgCount') { throw "STOP: explicit-model argv guard missing." }
    if ($RunText -notmatch '\$AddDirArgCount') { throw "STOP: add-dir argv guard missing." }
    if ($RunText -notmatch 'zero-extra-cost-gate\.json') { throw "STOP: cost gate runtime precondition missing." }
    if ($RunText -notmatch 'subscription_route_evidence_verified') { throw "STOP: subscription-route evidence gate missing." }
    if ($RunText -notmatch 'extra_paid_api_route_required') { throw "STOP: paid-route exclusion gate missing." }
    if ($RunText -notmatch '\$Psi\.FileName = \$AgyExe') { throw "STOP: direct agy invocation missing." }
    if ($RunText -notmatch '\$Psi\.WorkingDirectory = \$TempRoot') { throw "STOP: isolated TEMP workdir missing." }
    if ($RunText -notmatch '"--sandbox"') { throw "STOP: sandbox argv missing." }
    if ($RunText -notmatch 'exit \$Process\.ExitCode') { throw "STOP: provider exit propagation missing." }

    if (Test-Path -LiteralPath $CostGatePath) { throw "STOP: cost gate must not exist at C37 build validation stage." }
    if (Test-Path -LiteralPath $LockPath) { throw "STOP: packet already consumed." }
    if (Test-Path -LiteralPath $RuntimeRoot) { throw "STOP: packet runtime already exists." }

    Write-Host "[PASS] PACKET_C37_V1_VALIDATION=PASS"
    Write-Host "PACKET_C37_V1_FRESH=YES"
    Write-Host "SELF_CONTAINED_EVIDENCE=True"
    Write-Host "TOOLS_REQUIRED=NO"
    Write-Host "READ_FILE_REQUIRED=NO"
    Write-Host "MCP_REQUIRED=NO"
    Write-Host "WEB_REQUIRED=NO"
    Write-Host "ZERO_EXTRA_COST_ROUTE_GATE_STATUS=PENDING"
    Write-Host "LIVE_EXECUTION_READY=NO"
    Write-Host "PROVIDER_MODEL_EXECUTED_NOW=NO"
    Write-Host "MODEL_CALLS_REQUESTED_NOW=0"
    Write-Host "NEXT_STAGE=1.2R-C38-VALIDATE-FRESH-INDEPENDENT-GOVERNANCE-REVIEW-PACKET"
}