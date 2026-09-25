param([Parameter(Mandatory=$true)][string]$AgencyRoot)
$ErrorActionPreference = 'Stop'
$Passed = 0
$Failed = 0
function Read-J { param([string]$Rel); $Full = Join-Path $AgencyRoot ($Rel.Replace('/','\') ); if (-not (Test-Path -LiteralPath $Full -PathType Leaf)) { throw "Missing: $Rel" }; return Get-Content -LiteralPath $Full -Raw -Encoding UTF8 | ConvertFrom-Json }
function Check { param([string]$Name,[bool]$Condition); if ($Condition) { Write-Host "[PASS] $Name"; $script:Passed++ } else { Write-Host "[FAIL] $Name"; $script:Failed++ } }
function Exact-Array { param([object[]]$Actual,[object[]]$Expected); if (@($Actual).Count -ne @($Expected).Count) { return $false }; for ($i=0; $i -lt @($Expected).Count; $i++) { if ([string]$Actual[$i] -cne [string]$Expected[$i]) { return $false } }; return $true }
$Cases = Read-J 'tests/pbx/area-contract/cases.json'
$Area = Read-J 'config/pbx/area.json'
$Map = Read-J 'config/pbx/capability-map.json'
$Runtime = Read-J 'config/pbx/runtime-bindings.json'
$Bundle = Read-J 'config/pbx/skill-bundle.json'
$Agent = Read-J 'agents/pbx/proxtel-pbx-orchestrator/agent.json'
$Workflow = Read-J 'workflows/pbx/delivery/workflow.json'
$ExpectedSubs = @($Cases.expected.subagents)
$ExpectedSkills = @($Cases.expected.skills)
Check 'area-id' ([string]$Area.id -ceq 'pbx')
Check 'area-lifecycle' ([string]$Area.lifecycle_status -ceq [string]$Cases.expected.area_lifecycle)
Check 'area-parent' ([string]$Area.parent_commit -ceq [string]$Cases.expected.parent_commit)
Check 'area-provider-neutral' ([bool]$Area.provider_neutral)
Check 'area-readonly-first' ([bool]$Area.safety.read_only_discovery_first)
Check 'area-evidence-before-mutation' ([bool]$Area.safety.evidence_before_mutation)
Check 'area-no-live-mutation-default' (-not [bool]$Area.safety.production_pbx_mutation_default)
Check 'area-no-auto-restart' (-not [bool]$Area.safety.automatic_service_restart)
Check 'area-no-auto-firewall' (-not [bool]$Area.safety.automatic_firewall_reload)
Check 'area-no-auto-freepbx-apply' (-not [bool]$Area.safety.automatic_freepbx_apply)
Check 'area-explicit-live-auth' ([bool]$Area.safety.explicit_authorization_required_for_live_changes)
Check 'area-no-auto-commit' (-not [bool]$Area.safety.automatic_commit)
Check 'area-no-auto-push' (-not [bool]$Area.safety.automatic_push)
Check 'agent-id' ([string]$Agent.id -ceq 'proxtel-pbx-orchestrator')
Check 'agent-status' ([string]$Agent.status -ceq [string]$Cases.expected.agent_status)
Check 'agent-subs' (Exact-Array @($Agent.subagents | ForEach-Object { $_.id }) $ExpectedSubs)
Check 'agent-skills' (Exact-Array @($Agent.skills.candidate_domain) $ExpectedSkills)
Check 'agent-development-delegation' ([bool]$Agent.delegation.repository_changes_require_development)
Check 'agent-installer-delegation' ([bool]$Agent.delegation.installer_code_requires_development)
Check 'agent-crm-delegation' ([bool]$Agent.delegation.crm_domain_changes_require_crm)
Check 'agent-tools=0' (@($Agent.tools.pbx_specific_tools).Count -eq 0)
Check 'agent-mcp=0' (@($Agent.mcp.pbx_specific_servers).Count -eq 0)
Check 'agent-live-tool-exec=false' (-not [bool]$Agent.tools.live_server_execution)
Check 'agent-no-auto-restart' ([bool]$Agent.limits.no_automatic_service_restart)
Check 'agent-no-auto-firewall' ([bool]$Agent.limits.no_automatic_firewall_reload)
Check 'agent-no-auto-freepbx' ([bool]$Agent.limits.no_automatic_freepbx_apply)
Check 'map-lanes=7' (@($Map.lanes).Count -eq 7)
Check 'runtime-bindings=7' (@($Runtime.bindings).Count -eq 7)
Check 'runtime-tools=0' (@($Runtime.tool_policy.pbx_specific_tools).Count -eq 0)
Check 'runtime-live-server=false' (-not [bool]$Runtime.tool_policy.live_server_execution)
Check 'runtime-mcp=0' (@($Runtime.mcp_policy.pbx_specific_servers).Count -eq 0)
Check 'bundle-skills' (Exact-Array @($Bundle.domain_skills) $ExpectedSkills)
Check 'bundle-auto=false' (-not [bool]$Bundle.activation.automatic_activation)
Check 'bundle-cert-required' ([bool]$Bundle.activation.certification_required_before_activation)
Check 'workflow-id' ([string]$Workflow.id -ceq 'pbx-delivery')
Check 'workflow-status' ([string]$Workflow.status -ceq [string]$Cases.expected.workflow_status)
Check 'workflow-steps=13' (@($Workflow.steps).Count -eq 13)
Check 'workflow-decisions=4' (@($Workflow.final_decisions).Count -eq 4)
Check 'workflow-live-auth' ([bool]$Workflow.safety.live_mutation_requires_explicit_authorization)
Check 'workflow-no-auto-restart' ([bool]$Workflow.safety.automatic_service_restart_forbidden)
Check 'workflow-no-auto-firewall' ([bool]$Workflow.safety.automatic_firewall_reload_forbidden)
Check 'workflow-no-auto-freepbx' ([bool]$Workflow.safety.automatic_freepbx_apply_forbidden)
Check 'workflow-no-auto-commit' ([bool]$Workflow.safety.automatic_commit_forbidden)
Check 'workflow-no-auto-push' ([bool]$Workflow.safety.automatic_push_forbidden)
foreach ($Id in $ExpectedSubs) { $S = Read-J ("agents/pbx/subagents/" + $Id + "/subagent.json"); Check ("sub-" + $Id + "-id") ([string]$S.id -ceq [string]$Id); Check ("sub-" + $Id + "-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status); Check ("sub-" + $Id + "-ephemeral") (-not [bool]$S.persistent); Check ("sub-" + $Id + "-no-code") (-not [bool]$S.limits.repository_code_implementation); Check ("sub-" + $Id + "-no-live-mutation") (-not [bool]$S.limits.production_pbx_mutation); Check ("sub-" + $Id + "-no-restart") (-not [bool]$S.limits.service_restart); Check ("sub-" + $Id + "-no-firewall") (-not [bool]$S.limits.firewall_reload); Check ("sub-" + $Id + "-no-freepbx-apply") (-not [bool]$S.limits.freepbx_apply) }
foreach ($Id in $ExpectedSkills) { $S = Read-J ("skills/pbx/" + $Id + "/skill.json"); Check ("skill-" + $Id + "-id") ([string]$S.id -ceq [string]$Id); Check ("skill-" + $Id + "-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status); Check ("skill-" + $Id + "-provider-neutral") ([bool]$S.provider_neutral); Check ("skill-" + $Id + "-no-packages") (@($S.dependencies.direct_packages).Count -eq 0); Check ("skill-" + $Id + "-readonly") ([bool]$S.safety.read_only_discovery_first); Check ("skill-" + $Id + "-no-live-default") (-not [bool]$S.safety.production_pbx_mutation_default); Check ("skill-" + $Id + "-no-restart") (-not [bool]$S.safety.automatic_service_restart); Check ("skill-" + $Id + "-no-firewall") (-not [bool]$S.safety.automatic_firewall_reload); Check ("skill-" + $Id + "-cert-required") ([bool]$S.lifecycle.certification_required_before_activation) }
Write-Host "PBX_ASSERTIONS=$($Passed+$Failed)"
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"
if ($Failed -gt 0) { throw 'PBX AREA CONTRACT TEST FAILURE' }
Write-Host '[PASS] ALL PBX AREA CONTRACT TESTS PASSED'
