param(
    [Parameter(Mandatory = $true)][string]$AgentRoot,
    [Parameter(Mandatory = $true)][string]$SchemaPath,
    [Parameter(Mandatory = $true)][string]$CapabilityMapPath,
    [Parameter(Mandatory = $true)][string]$TestsRoot
)

$ErrorActionPreference = "Stop"

$AgentPath = Join-Path $AgentRoot "agent.json"
$AgentMdPath = Join-Path $AgentRoot "AGENT.md"
$CasesPath = Join-Path $TestsRoot "agent-cases.json"

foreach ($Path in @($AgentPath,$AgentMdPath,$SchemaPath,$CapabilityMapPath,$CasesPath)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw ("Missing: " + $Path) }
}

$Agent = Get-Content -LiteralPath $AgentPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Schema = Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Map = Get-Content -LiteralPath $CapabilityMapPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Manual = [System.IO.File]::ReadAllText($AgentMdPath,[System.Text.Encoding]::UTF8)
$ParsedCases = Get-Content -LiteralPath $CasesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Cases = @()
foreach ($Item in @($ParsedCases)) { if ($Item -is [System.Array]) { foreach ($Nested in $Item) { $Cases += $Nested } } else { $Cases += $Item } }

$Passed = 0
$Failed = 0
function Check { param([string]$Name,[bool]$Condition) if ($Condition) { Write-Host ("[PASS] " + $Name); $script:Passed++ } else { Write-Host ("[FAIL] " + $Name); $script:Failed++ } }

$BaselineRefs = @($Agent.skills.legacy_baseline_reference_only)
$Subagents = @($Agent.subagents)
$Lanes = @($Map.lanes)
$LegacyMap = @($Map.legacy_baseline_skills)

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL DEVELOPMENT AGENT TESTS"
Write-Host "============================================================"

Check "schema-title" ([string]$Schema.title -ceq "PROXTEL Agent Contract")
Check "schema-kind-const" ([string]$Schema.properties.kind.const -ceq "proxtel-agent")
Check "agent-kind" ([string]$Agent.kind -ceq "proxtel-agent")
Check "agent-id" ([string]$Agent.id -ceq "proxtel-development-orchestrator")
Check "agent-area" ([string]$Agent.area -ceq "development")
Check "agent-version" ([string]$Agent.version -ceq "1.0.0")
Check "agent-approved" ([string]$Agent.status -ceq "approved")
Check "agent-provider-neutral" ([bool]$Agent.provider_neutral)
Check "agent-role" ([string]$Agent.role -ceq "Main Development Agent")
Check "responsibilities>=8" (@($Agent.responsibilities).Count -ge 8)
Check "no-auto-commit" ([bool]$Agent.limits.no_automatic_commit)
Check "no-auto-push" ([bool]$Agent.limits.no_automatic_push)
Check "no-auto-deploy" ([bool]$Agent.limits.no_production_deploy_without_explicit_instruction)
Check "no-destructive-prod-db" ([bool]$Agent.limits.no_destructive_production_database_operation)
Check "no-silent-dependency" ([bool]$Agent.limits.no_silent_dependency_install)
Check "no-silent-paid-api" ([bool]$Agent.limits.no_silent_paid_api_consumption)
Check "no-external-code-execution" ([bool]$Agent.limits.no_unreviewed_external_code_execution)
Check "no-auto-live-retry" ([bool]$Agent.limits.no_automatic_retry_of_consumed_live_attempt)
Check "canonical-active-skills=0" (@($Agent.skills.canonical_active).Count -eq 0)
Check "legacy-baseline-refs=3" ($BaselineRefs.Count -eq 3)
Check "baseline-auditor-web" ($BaselineRefs -contains "auditor-web")
Check "baseline-estratega-seo" ($BaselineRefs -contains "estratega-seo")
Check "baseline-maestro-frontend" ($BaselineRefs -contains "maestro-frontend")
Check "workflow-linked" (@($Agent.workflows) -contains "development-software-delivery")
Check "subagents=6" ($Subagents.Count -eq 6)
Check "subagents-ephemeral" (@($Subagents | Where-Object { [bool]$_.persistent }).Count -eq 0)
Check "independent-review-preferred" ([bool]$Agent.provider_routing.independent_review_preferred)
Check "fallback-preserves-controls" ([bool]$Agent.provider_routing.fallback_must_preserve_controls)
Check "read-only-discovery-first" ([bool]$Agent.safety.read_only_discovery_first)
Check "local-first" ([bool]$Agent.safety.local_first)
Check "subagent-authority-bounded" ([bool]$Agent.safety.subagent_authority_cannot_exceed_parent)
Check "capability-lanes=11" ($Lanes.Count -eq 11)
Check "legacy-map=3" ($LegacyMap.Count -eq 3)
Check "legacy-map-not-trusted" (@($LegacyMap | Where-Object { [bool]$_.trusted_activation }).Count -eq 0)
Check "manual-baseline-warning" ($Manual.Contains("They are NOT canonical active Skills yet."))
Check "cases=10" ($Cases.Count -eq 10)

Write-Host ""
Write-Host ("AGENT_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)
if ($Failed -gt 0) { throw "DEVELOPMENT AGENT TEST FAILURE" }
Write-Host "[PASS] ALL DEVELOPMENT AGENT TESTS PASSED" -ForegroundColor Green