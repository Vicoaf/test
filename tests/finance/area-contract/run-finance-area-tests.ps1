param([Parameter(Mandatory=$true)][string]$AgencyRoot)
$ErrorActionPreference = 'Stop'
$Passed = 0
$Failed = 0
function Read-J { param([string]$Rel); $Full = Join-Path $AgencyRoot ($Rel.Replace('/','\') ); if (-not (Test-Path -LiteralPath $Full -PathType Leaf)) { throw "Missing: $Rel" }; return Get-Content -LiteralPath $Full -Raw -Encoding UTF8 | ConvertFrom-Json }
function Check { param([string]$Name,[bool]$Condition); if ($Condition) { Write-Host "[PASS] $Name"; $script:Passed++ } else { Write-Host "[FAIL] $Name"; $script:Failed++ } }
function Exact-Array { param([object[]]$Actual,[object[]]$Expected); if (@($Actual).Count -ne @($Expected).Count) { return $false }; for ($i=0; $i -lt @($Expected).Count; $i++) { if ([string]$Actual[$i] -cne [string]$Expected[$i]) { return $false } }; return $true }
$Cases = Read-J 'tests/finance/area-contract/cases.json'
$Area = Read-J 'config/finance/area.json'
$Map = Read-J 'config/finance/capability-map.json'
$Runtime = Read-J 'config/finance/runtime-bindings.json'
$Bundle = Read-J 'config/finance/skill-bundle.json'
$Agent = Read-J 'agents/finance/proxtel-finance-orchestrator/agent.json'
$Workflow = Read-J 'workflows/finance/delivery/workflow.json'
$ExpectedSubs = @($Cases.expected.subagents)
$ExpectedSkills = @($Cases.expected.skills)
Check 'area-id' ([string]$Area.id -ceq 'finance')
Check 'area-lifecycle' ([string]$Area.lifecycle_status -ceq [string]$Cases.expected.area_lifecycle)
Check 'area-parent' ([string]$Area.parent_commit -ceq [string]$Cases.expected.parent_commit)
Check 'area-provider-neutral' ([bool]$Area.provider_neutral)
Check 'area-source-grounded' ([bool]$Area.safety.source_grounded_first)
Check 'area-no-auto-transactions' (-not [bool]$Area.safety.autonomous_financial_transactions)
Check 'area-no-auto-commit' (-not [bool]$Area.safety.automatic_commit)
Check 'area-no-auto-push' (-not [bool]$Area.safety.automatic_push)
Check 'agent-id' ([string]$Agent.id -ceq 'proxtel-finance-orchestrator')
Check 'agent-status' ([string]$Agent.status -ceq [string]$Cases.expected.agent_status)
Check 'agent-subs' (Exact-Array @($Agent.subagents | ForEach-Object { $_.id }) $ExpectedSubs)
Check 'agent-skills' (Exact-Array @($Agent.skills.candidate_domain) $ExpectedSkills)
Check 'agent-dev-delegation' ([bool]$Agent.delegation.code_changes_require_development)
Check 'agent-crm-delegation' ([bool]$Agent.delegation.crm_domain_changes_require_crm)
Check 'agent-sales-delegation' ([bool]$Agent.delegation.sales_domain_changes_require_sales)
Check 'agent-tools=0' (@($Agent.tools.finance_specific_tools).Count -eq 0)
Check 'agent-mcp=0' (@($Agent.mcp.finance_specific_servers).Count -eq 0)
Check 'map-lanes=7' (@($Map.lanes).Count -eq 7)
Check 'runtime-bindings=7' (@($Runtime.bindings).Count -eq 7)
Check 'runtime-tools=0' (@($Runtime.tool_policy.finance_specific_tools).Count -eq 0)
Check 'runtime-mcp=0' (@($Runtime.mcp_policy.finance_specific_servers).Count -eq 0)
Check 'bundle-skills' (Exact-Array @($Bundle.domain_skills) $ExpectedSkills)
Check 'bundle-auto=false' (-not [bool]$Bundle.activation.automatic_activation)
Check 'bundle-cert-required' ([bool]$Bundle.activation.certification_required_before_activation)
Check 'workflow-id' ([string]$Workflow.id -ceq 'finance-delivery')
Check 'workflow-status' ([string]$Workflow.status -ceq [string]$Cases.expected.workflow_status)
Check 'workflow-steps=12' (@($Workflow.steps).Count -eq 12)
Check 'workflow-decisions=4' (@($Workflow.final_decisions).Count -eq 4)
Check 'workflow-no-auto-transactions' ([bool]$Workflow.safety.autonomous_financial_transactions_forbidden)
Check 'workflow-no-auto-commit' ([bool]$Workflow.safety.automatic_commit_forbidden)
Check 'workflow-no-auto-push' ([bool]$Workflow.safety.automatic_push_forbidden)
foreach ($Id in $ExpectedSubs) { $S = Read-J ("agents/finance/subagents/" + $Id + "/subagent.json"); Check ("sub-" + $Id + "-id") ([string]$S.id -ceq [string]$Id); Check ("sub-" + $Id + "-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status); Check ("sub-" + $Id + "-ephemeral") (-not [bool]$S.persistent); Check ("sub-" + $Id + "-no-code") (-not [bool]$S.limits.repository_code_implementation); Check ("sub-" + $Id + "-no-transactions") (-not [bool]$S.limits.autonomous_financial_transactions) }
foreach ($Id in $ExpectedSkills) { $S = Read-J ("skills/finance/" + $Id + "/skill.json"); Check ("skill-" + $Id + "-id") ([string]$S.id -ceq [string]$Id); Check ("skill-" + $Id + "-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status); Check ("skill-" + $Id + "-provider-neutral") ([bool]$S.provider_neutral); Check ("skill-" + $Id + "-no-packages") (@($S.dependencies.direct_packages).Count -eq 0); Check ("skill-" + $Id + "-cert-required") ([bool]$S.lifecycle.certification_required_before_activation) }
Write-Host "FINANCE_ASSERTIONS=$($Passed+$Failed)"
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"
if ($Failed -gt 0) { throw 'FINANCE AREA CONTRACT TEST FAILURE' }
Write-Host '[PASS] ALL FINANCE AREA CONTRACT TESTS PASSED'
