param(
    [Parameter(Mandatory = $true)][string]$HarnessRoot,
    [Parameter(Mandatory = $true)][string]$Agency
)
$ErrorActionPreference = "Stop"
function Read-Json { param([string]$Path); return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json) }
function Get-Sha { param([string]$Path); return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
$ManifestPath = Join-Path $HarnessRoot "harness-manifest.json"
$PromptManifestPath = Join-Path $HarnessRoot "prompt-manifests.json"
$SchemaPath = Join-Path $HarnessRoot "behavioral-response-v2.schema.json"
$PromptRoot = Join-Path $HarnessRoot "prompts"
$ModelInputRoot = Join-Path $HarnessRoot "model-input"
$PlansRoot = Join-Path $HarnessRoot "plans"
$Required = @($ManifestPath,$PromptManifestPath,$SchemaPath,(Join-Path $HarnessRoot "README.md"),(Join-Path $PromptRoot "routing-internal-skill-audit.txt"),(Join-Path $PromptRoot "evidence-incomplete-candidate.txt"),(Join-Path $PromptRoot "full-audit-complete-safe-candidate.txt"),(Join-Path $ModelInputRoot "candidate-manifest.json"),(Join-Path $ModelInputRoot "evidence-incomplete.json"),(Join-Path $ModelInputRoot "evidence-complete.json"))
foreach ($Path in $Required) { if (-not (Test-Path -LiteralPath $Path)) { throw "Missing harness artifact: $Path" }; if ((Get-Item -LiteralPath $Path).Length -eq 0) { throw "Empty harness artifact: $Path" } }
$Manifest = Read-Json $ManifestPath
if ($Manifest.kind -ne "proxtel-provider-harness-v2") { throw "Invalid harness kind." }
if ($Manifest.status -ne "candidate") { throw "Harness must remain candidate." }
if ($Manifest.auditor.version -ne "0.2.0") { throw "Harness does not target Auditor v0.2.0." }
if ($Manifest.role_separation.operating_instructions -ne "proxtel-skill-auditor") { throw "Wrong operating instructions." }
if ($Manifest.role_separation.candidate_fixture -ne "fixture-safe-summarizer") { throw "Wrong candidate fixture." }
if ($Manifest.role_separation.auditor_may_be_candidate_implicitly -ne $false) { throw "Auditor/candidate separation broken." }
if ($Manifest.role_separation.auditor_skill_json_embedded_in_prompt -ne $false) { throw "Auditor skill.json must not be embedded." }
if ($Manifest.model_input_policy.benchmark_expected_values_embedded -ne $false) { throw "Expected values must not be model-facing." }
if ($Manifest.model_input_policy.grading_metadata_embedded -ne $false) { throw "Grading metadata must not be model-facing." }
if ($Manifest.safety.offline_only -ne $true) { throw "Harness must be offline-only." }
if ($Manifest.safety.provider_execution_authorized -ne $false) { throw "Provider execution must remain unauthorized." }
if ($Manifest.safety.model_calls_allowed -ne 0) { throw "Model calls must remain zero." }
if ($Manifest.safety.second_live_call_authorized -ne $false) { throw "Second live call must remain unauthorized." }
$PromptManifestsParsed = Read-Json $PromptManifestPath
$PromptManifests = @($PromptManifestsParsed)
if ($PromptManifests.Count -ne 3) { throw "Expected three prompt manifests." }
foreach ($Record in $PromptManifests) {
    $PromptPath = Join-Path $HarnessRoot ([string]$Record.prompt_file)
    if (-not (Test-Path -LiteralPath $PromptPath)) { throw "Prompt missing: $($Record.prompt_file)" }
    if ((Get-Sha $PromptPath) -ne [string]$Record.prompt_sha256) { throw "Prompt hash mismatch: $($Record.case_id)" }
    if ($Record.auditor_is_candidate -ne $false) { throw "Auditor became candidate." }
    if ($Record.grading_metadata_embedded -ne $false) { throw "Grading metadata flag invalid." }
    if ($Record.expected_values_embedded -ne $false) { throw "Expected-value flag invalid." }
    $PromptText = [System.IO.File]::ReadAllText($PromptPath,[System.Text.Encoding]::UTF8)
    if ($PromptText -notmatch "OPERATING ROLE: PROXTEL Skill Auditor") { throw "Operating role missing." }
    if ($PromptText -match "(?i)CANDIDATE UNDER AUDIT:\s*proxtel-skill-auditor") { throw "Auditor marked candidate." }
    if ($PromptText -match "(?i)synthetic_expected_disposition") { throw "Expected disposition leaked." }
    if ($PromptText -match "(?i)final_decision_supported") { throw "Decision-support metadata leaked." }
    if ($PromptText -match "(?i)benchmark-cases-v2\.json") { throw "Benchmark definition leaked." }
}
$Routing = @($PromptManifests | Where-Object { $_.layer -eq "routing" })
$Evidence = @($PromptManifests | Where-Object { $_.layer -eq "evidence-request" })
$Full = @($PromptManifests | Where-Object { $_.layer -eq "full-audit" })
if ($Routing.Count -ne 1 -or $Evidence.Count -ne 1 -or $Full.Count -ne 1) { throw "Prompt layer cardinality invalid." }
if ($null -ne $Routing[0].candidate_under_audit) { throw "Routing prompt must not bind candidate." }
if ($Evidence[0].candidate_under_audit -ne "fixture-safe-summarizer") { throw "Evidence candidate mismatch." }
if ($Full[0].candidate_under_audit -ne "fixture-safe-summarizer") { throw "Full-audit candidate mismatch." }
$ModelInputFiles = @((Join-Path $ModelInputRoot "candidate-manifest.json"),(Join-Path $ModelInputRoot "evidence-incomplete.json"),(Join-Path $ModelInputRoot "evidence-complete.json"))
foreach ($Path in $ModelInputFiles) { $Text = [System.IO.File]::ReadAllText($Path,[System.Text.Encoding]::UTF8); foreach ($Forbidden in @("synthetic_expected_disposition","final_decision_supported","candidate_under_test","auditor_under_test")) { if ($Text -match [regex]::Escape($Forbidden)) { throw "Forbidden metadata in model input: $Forbidden" } } }
$Plans = @(Get-ChildItem -LiteralPath $PlansRoot -Filter "*.json" -File -Recurse)
if ($Plans.Count -ne 9) { throw "Expected nine provider plans." }
$Seen = @{}
foreach ($PlanFile in $Plans) {
    $Plan = Read-Json $PlanFile.FullName
    if ($Plan.kind -ne "proxtel-provider-harness-v2-plan") { throw "Invalid plan kind." }
    if ($Plan.status -ne "OFFLINE-PLAN-ONLY") { throw "Plan is not offline-only." }
    if (@("claude","codex","antigravity") -notcontains [string]$Plan.provider) { throw "Unknown provider." }
    $Key = [string]$Plan.provider + "|" + [string]$Plan.case_id
    if ($Seen.ContainsKey($Key)) { throw "Duplicate provider/case plan: $Key" }
    $Seen[$Key] = $true
    if ($Plan.input.auditor_is_candidate -ne $false) { throw "Plan marks Auditor as candidate." }
    if ($Plan.input.expected_values_embedded -ne $false) { throw "Plan embeds expected values." }
    if ($Plan.input.grading_metadata_embedded -ne $false) { throw "Plan embeds grading metadata." }
    if ($Plan.runtime.working_directory_policy -ne "isolated-temp-required") { throw "Plan lacks isolated temp." }
    if ($Plan.runtime.model_selection -ne "provider-default") { throw "Plan forces model selection." }
    if ($Plan.safety.provider_execution_authorized -ne $false) { throw "Plan authorizes execution." }
    if ($Plan.safety.model_calls_allowed -ne 0) { throw "Plan allows model calls." }
    if ($Plan.safety.automatic_retry -ne $false) { throw "Plan allows retry." }
    if ($Plan.safety.production -ne $false) { throw "Plan allows production." }
    if ($Plan.safety.dangerous_bypass -ne $false) { throw "Plan allows dangerous bypass." }
    if ($Plan.safety.api_key_fallback -ne $false) { throw "Plan allows API fallback." }
    if ($Plan.execution.executed -ne $false -or $Plan.execution.provider_process_invocations -ne 0 -or $Plan.execution.model_calls -ne 0) { throw "Plan incorrectly records execution." }
    if ($Plan.provider -eq "codex" -and $Plan.runtime.sandbox_policy -ne "read-only") { throw "Codex plan must use read-only." }
    if ($Plan.provider -ne "codex" -and $Plan.runtime.sandbox_policy -ne "adapter-safe-mode-required-before-live") { throw "Non-Codex runtime must remain deferred." }
}
if ($Seen.Count -ne 9) { throw "Provider/case matrix incomplete." }
Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL PROVIDER HARNESS V2 VALIDATION"
Write-Host "============================================================"
Write-Host "PROMPTS=3"
Write-Host "ROUTING_PROMPTS=1"
Write-Host "EVIDENCE_REQUEST_PROMPTS=1"
Write-Host "FULL_AUDIT_PROMPTS=1"
Write-Host "PROVIDERS=3"
Write-Host "PLANS_PER_PROVIDER=3"
Write-Host "PROVIDER_PLANS=9"
Write-Host "OPERATING_INSTRUCTIONS_IS_AUDITOR=YES"
Write-Host "CANDIDATE_IS_AUDITOR=NO"
Write-Host "SYNTHETIC_CANDIDATE=fixture-safe-summarizer"
Write-Host "EXPECTED_VALUES_EMBEDDED=NO"
Write-Host "GRADING_METADATA_EMBEDDED=NO"
Write-Host "AUDITOR_SKILL_JSON_EMBEDDED=NO"
Write-Host "CODEX_SANDBOX_POLICY=read-only"
Write-Host "CLAUDE_RUNTIME_BINDING=DEFERRED"
Write-Host "ANTIGRAVITY_RUNTIME_BINDING=DEFERRED"
Write-Host "PROVIDER_EXECUTION_AUTHORIZED=NO"
Write-Host "MODEL_CALLS_ALLOWED=0"
Write-Host "SECOND_LIVE_CALL_AUTHORIZED=NO"
Write-Host "[PASS] PROVIDER HARNESS V2 VALID" -ForegroundColor Green