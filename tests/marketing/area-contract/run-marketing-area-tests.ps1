param([Parameter(Mandatory=$true)][string]$AgencyRoot)
$ErrorActionPreference = 'Stop'
$Passed = 0
$Failed = 0
function Read-J { param([string]$Rel); $Full = Join-Path $AgencyRoot ($Rel.Replace('/','\') ); if (-not (Test-Path -LiteralPath $Full -PathType Leaf)) { throw "Missing: $Rel" }; return Get-Content -LiteralPath $Full -Raw -Encoding UTF8 | ConvertFrom-Json }
function Check { param([string]$Name,[bool]$Condition); if ($Condition) { Write-Host "[PASS] $Name"; $script:Passed++ } else { Write-Host "[FAIL] $Name"; $script:Failed++ } }
function Exact-Array { param([object[]]$Actual,[object[]]$Expected); if (@($Actual).Count -ne @($Expected).Count) { return $false }; for ($i=0; $i -lt @($Expected).Count; $i++) { if ([string]$Actual[$i] -cne [string]$Expected[$i]) { return $false } }; return $true }
$Cases = Read-J 'tests/marketing/area-contract/cases.json'
$Area = Read-J 'config/marketing/area.json'
$Map = Read-J 'config/marketing/capability-map.json'
$Runtime = Read-J 'config/marketing/runtime-bindings.json'
$Bundle = Read-J 'config/marketing/skill-bundle.json'
$Agent = Read-J 'agents/marketing/proxtel-marketing-orchestrator/agent.json'
$Workflow = Read-J 'workflows/marketing/delivery/workflow.json'
$ExpectedSubs = @($Cases.expected.subagents)
$ExpectedSkills = @($Cases.expected.skills)
Check 'area-id' ([string]$Area.id -ceq 'marketing')
Check 'area-lifecycle' ([string]$Area.lifecycle_status -ceq [string]$Cases.expected.area_lifecycle)
Check 'area-parent' ([string]$Area.parent_commit -ceq [string]$Cases.expected.parent_commit)
Check 'area-provider-neutral' ([bool]$Area.provider_neutral)
Check 'area-source-grounded' ([bool]$Area.safety.source_grounded_first)
Check 'area-no-auto-publish' (-not [bool]$Area.safety.automatic_campaign_publishing)
Check 'area-no-auto-ad-spend' (-not [bool]$Area.safety.automatic_ad_spend)
Check 'area-no-sensitive-targeting' (-not [bool]$Area.safety.sensitive_attribute_targeting_allowed)
Check 'area-no-auto-commit' (-not [bool]$Area.safety.automatic_commit)
Check 'area-no-auto-push' (-not [bool]$Area.safety.automatic_push)
Check 'agent-id' ([string]$Agent.id -ceq 'proxtel-marketing-orchestrator')
Check 'agent-status' ([string]$Agent.status -ceq [string]$Cases.expected.agent_status)
Check 'agent-subs' (Exact-Array @($Agent.subagents | ForEach-Object { $_.id }) $ExpectedSubs)
Check 'agent-skills' (Exact-Array @($Agent.skills.candidate_domain) $ExpectedSkills)
Check 'agent-dev-delegation' ([bool]$Agent.delegation.code_changes_require_development)
Check 'agent-crm-delegation' ([bool]$Agent.delegation.crm_domain_changes_require_crm)
Check 'agent-sales-delegation' ([bool]$Agent.delegation.sales_domain_changes_require_sales)
Check 'agent-doc-delegation' ([bool]$Agent.delegation.reusable_documentation_requires_documentation)
Check 'agent-tools=0' (@($Agent.tools.marketing_specific_tools).Count -eq 0)
Check 'agent-mcp=0' (@($Agent.mcp.marketing_specific_servers).Count -eq 0)
Check 'agent-no-auto-publish' ([bool]$Agent.limits.no_automatic_campaign_publish)
Check 'agent-no-auto-spend' ([bool]$Agent.limits.no_automatic_ad_spend)
Check 'map-lanes=7' (@($Map.lanes).Count -eq 7)
Check 'runtime-bindings=7' (@($Runtime.bindings).Count -eq 7)
Check 'runtime-tools=0' (@($Runtime.tool_policy.marketing_specific_tools).Count -eq 0)
Check 'runtime-mcp=0' (@($Runtime.mcp_policy.marketing_specific_servers).Count -eq 0)
Check 'bundle-skills' (Exact-Array @($Bundle.domain_skills) $ExpectedSkills)
Check 'bundle-auto=false' (-not [bool]$Bundle.activation.automatic_activation)
Check 'bundle-cert-required' ([bool]$Bundle.activation.certification_required_before_activation)
Check 'workflow-id' ([string]$Workflow.id -ceq 'marketing-delivery')
Check 'workflow-status' ([string]$Workflow.status -ceq [string]$Cases.expected.workflow_status)
Check 'workflow-steps=12' (@($Workflow.steps).Count -eq 12)
Check 'workflow-decisions=4' (@($Workflow.final_decisions).Count -eq 4)
Check 'workflow-no-auto-publish' ([bool]$Workflow.safety.automatic_campaign_publishing_forbidden)
Check 'workflow-no-auto-spend' ([bool]$Workflow.safety.automatic_ad_spend_forbidden)
Check 'workflow-no-sensitive-targeting' ([bool]$Workflow.safety.sensitive_attribute_targeting_forbidden)
Check 'workflow-no-auto-commit' ([bool]$Workflow.safety.automatic_commit_forbidden)
Check 'workflow-no-auto-push' ([bool]$Workflow.safety.automatic_push_forbidden)
foreach ($Id in $ExpectedSubs) { $S = Read-J ("agents/marketing/subagents/" + $Id + "/subagent.json"); Check ("sub-" + $Id + "-id") ([string]$S.id -ceq [string]$Id); Check ("sub-" + $Id + "-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status); Check ("sub-" + $Id + "-ephemeral") (-not [bool]$S.persistent); Check ("sub-" + $Id + "-no-code") (-not [bool]$S.limits.repository_code_implementation); Check ("sub-" + $Id + "-no-publish") (-not [bool]$S.limits.automatic_campaign_publishing); Check ("sub-" + $Id + "-no-spend") (-not [bool]$S.limits.automatic_ad_spend) }
foreach ($Id in $ExpectedSkills) { $S = Read-J ("skills/marketing/" + $Id + "/skill.json"); Check ("skill-" + $Id + "-id") ([string]$S.id -ceq [string]$Id); Check ("skill-" + $Id + "-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status); Check ("skill-" + $Id + "-provider-neutral") ([bool]$S.provider_neutral); Check ("skill-" + $Id + "-no-packages") (@($S.dependencies.direct_packages).Count -eq 0); Check ("skill-" + $Id + "-no-publish") (-not [bool]$S.safety.automatic_campaign_publishing); Check ("skill-" + $Id + "-no-spend") (-not [bool]$S.safety.automatic_ad_spend); Check ("skill-" + $Id + "-cert-required") ([bool]$S.lifecycle.certification_required_before_activation) }
Write-Host "MARKETING_ASSERTIONS=$($Passed+$Failed)"
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"
if ($Failed -gt 0) { throw 'MARKETING AREA CONTRACT TEST FAILURE' }
Write-Host '[PASS] ALL MARKETING AREA CONTRACT TESTS PASSED'
