param(
    [Parameter(Mandatory=$true)][string]$AgencyRoot
)

$ErrorActionPreference = 'Stop'

function Read-J {
    param([Parameter(Mandatory=$true)][string]$Rel)
    $Full = Join-Path $AgencyRoot ($Rel.Replace('/','\'))
    if (-not (Test-Path -LiteralPath $Full -PathType Leaf)) { throw "Missing: $Rel" }
    return Get-Content -LiteralPath $Full -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Exact-Array {
    param([object[]]$Actual,[object[]]$Expected)
    if (@($Actual).Count -ne @($Expected).Count) { return $false }
    for ($i=0; $i -lt @($Expected).Count; $i++) {
        if ([string]$Actual[$i] -cne [string]$Expected[$i]) { return $false }
    }
    return $true
}

$Passed = 0
$Failed = 0
function Check {
    param([string]$Name,[bool]$Condition)
    if ($Condition) {
        Write-Host "[PASS] $Name"
        $script:Passed++
    } else {
        Write-Host "[FAIL] $Name"
        $script:Failed++
    }
}

$Cases = Read-J 'tests/crm/area-contract/cases.json'
$Area = Read-J 'config/crm/area.json'
$Map = Read-J 'config/crm/capability-map.json'
$Runtime = Read-J 'config/crm/runtime-bindings.json'
$Bundle = Read-J 'config/crm/skill-bundle.json'
$Agent = Read-J 'agents/crm/proxtel-crm-orchestrator/agent.json'
$Workflow = Read-J 'workflows/crm/solution-delivery/workflow.json'

$ExpectedSkills = @($Cases.expected.skills)
$ExpectedSubagents = @($Cases.expected.subagents)
$ExpectedDevSkills = @($Cases.expected.inherited_development_skills)

Write-Host '============================================================'
Write-Host ' PROXTEL CRM AREA CONTRACT TESTS'
Write-Host '============================================================'

Check 'area-id' ([string]$Area.id -ceq 'crm')
Check 'area-certified' ([string]$Area.lifecycle_status -ceq 'certified')
Check 'area-provider-neutral' ([bool]$Area.provider_neutral)
Check 'parent-gold-master' ([string]$Area.parent_gold_master.commit -ceq [string]$Cases.expected.parent_gold_master)
Check 'no-auto-commit-area' (-not [bool]$Area.safety.automatic_commit)
Check 'no-auto-push-area' (-not [bool]$Area.safety.automatic_push)
Check 'no-auto-deploy-area' (-not [bool]$Area.safety.automatic_deploy)
Check 'pii-minimization-area' ([bool]$Area.safety.pii_minimization)

Check 'agent-id' ([string]$Agent.id -ceq [string]$Cases.expected.agent_id)
Check 'agent-area' ([string]$Agent.area -ceq 'crm')
Check 'agent-approved' ([string]$Agent.status -ceq [string]$Cases.expected.agent_status)
Check 'agent-provider-neutral' ([bool]$Agent.provider_neutral)
Check 'agent-workflow' (@($Agent.workflows) -contains 'crm-solution-delivery')
Check 'agent-dev-delegation' ([bool]$Agent.development_delegation.required_for_repository_code_changes)
Check 'agent-subagents-exact' (Exact-Array @($Agent.subagents | ForEach-Object {$_.id}) $ExpectedSubagents)
Check 'agent-domain-skills-exact' (Exact-Array @($Agent.skills.candidate_domain) $ExpectedSkills)
Check 'agent-dev-skills-exact' (Exact-Array @($Agent.skills.inherited_approved_development) $ExpectedDevSkills)
Check 'agent-crm-tools=0' (@($Agent.tools.crm_specific_tools).Count -eq 0)
Check 'agent-crm-mcp=0' (@($Agent.mcp.crm_specific_servers).Count -eq 0)

Check 'capability-lanes=6' (@($Map.lanes).Count -eq [int]$Cases.expected.capability_lane_count)
Check 'capability-domain-lanes=5' (@($Map.lanes | Where-Object {$_.id -like 'crm-*'}).Count -eq [int]$Cases.expected.domain_lane_count)
Check 'capability-dev-delegation' ([bool]$Map.development_delegation.required_for_code_changes)

Check 'runtime-agent' ([string]$Runtime.orchestrator.id -ceq 'proxtel-crm-orchestrator')
Check 'runtime-workflow' ([string]$Runtime.workflow.id -ceq 'crm-solution-delivery')
Check 'runtime-bindings=6' (@($Runtime.bindings).Count -eq 6)
Check 'runtime-crm-tools=0' (@($Runtime.tool_policy.crm_specific_tools_materialized).Count -eq 0)
Check 'runtime-crm-mcp=0' (@($Runtime.mcp_policy.crm_specific_servers_materialized).Count -eq 0)
Check 'runtime-auto-tool=false' (-not [bool]$Runtime.tool_policy.automatic_tool_execution)
Check 'runtime-auto-mcp=false' (-not [bool]$Runtime.mcp_policy.automatic_approval)

Check 'bundle-domain-skills-exact' (Exact-Array @($Bundle.domain_skills) $ExpectedSkills)
Check 'bundle-dev-skills-exact' (Exact-Array @($Bundle.inherited_development_skills) $ExpectedDevSkills)
Check 'bundle-auto-activation=false' (-not [bool]$Bundle.activation.automatic_activation)
Check 'bundle-certification-required' ([bool]$Bundle.activation.certification_required_before_activation)

Check 'workflow-id' ([string]$Workflow.id -ceq [string]$Cases.expected.workflow_id)
Check 'workflow-area' ([string]$Workflow.area -ceq 'crm')
Check 'workflow-approved' ([string]$Workflow.status -ceq [string]$Cases.expected.workflow_status)
Check 'workflow-provider-neutral' ([bool]$Workflow.provider_neutral)
Check 'workflow-steps=9' (@($Workflow.steps).Count -eq 9)
Check 'workflow-dev-handoff' (@($Workflow.steps | Where-Object {$_.id -ceq 'development-handoff'}).Count -eq 1)
Check 'workflow-domain-validation' (@($Workflow.steps | Where-Object {$_.id -ceq 'crm-domain-validation'}).Count -eq 1)
Check 'workflow-decisions=4' (@($Workflow.final_decisions).Count -eq 4)
Check 'workflow-auto-commit-forbidden' ([bool]$Workflow.safety.automatic_commit_forbidden)
Check 'workflow-auto-push-forbidden' ([bool]$Workflow.safety.automatic_push_forbidden)
Check 'workflow-auto-deploy-forbidden' ([bool]$Workflow.safety.automatic_deploy_forbidden)

foreach ($Id in $ExpectedSubagents) {
    $S = Read-J ("agents/crm/subagents/" + $Id + "/subagent.json")
    Check ("subagent-" + $Id + "-id") ([string]$S.id -ceq [string]$Id)
    Check ("subagent-" + $Id + "-approved") ([string]$S.status -ceq 'approved')
    Check ("subagent-" + $Id + "-ephemeral") (-not [bool]$S.persistent)
    Check ("subagent-" + $Id + "-no-code") (-not [bool]$S.limits.repository_code_implementation)
    Check ("subagent-" + $Id + "-handoff") ([string]$S.handoff.implementation_target -ceq 'proxtel-development-orchestrator')
}

foreach ($Id in $ExpectedSkills) {
    $S = Read-J ("skills/crm/" + $Id + "/skill.json")
    Check ("skill-" + $Id + "-id") ([string]$S.id -ceq [string]$Id)
    Check ("skill-" + $Id + "-area") ([string]$S.area -ceq 'crm')
    Check ("skill-" + $Id + "-approved") ([string]$S.status -ceq 'approved')
    Check ("skill-" + $Id + "-provider-neutral") ([bool]$S.provider_neutral)
    Check ("skill-" + $Id + "-no-direct-packages") (@($S.dependencies.direct_packages).Count -eq 0)
    Check ("skill-" + $Id + "-no-silent-install") (-not [bool]$S.dependencies.silent_installation_allowed)
    Check ("skill-" + $Id + "-certification-required") ([bool]$S.lifecycle.certification_required_before_activation)
}

$RequiredDocs = @(
    'agents/crm/proxtel-crm-orchestrator/AGENT.md',
    'workflows/crm/solution-delivery/WORKFLOW.md',
    'standards/crm/crm-standard.md',
    'docs/crm/architecture.md',
    'docs/crm/operating-model.md'
)

foreach ($Rel in $RequiredDocs) {
    Check ("doc-" + $Rel) (Test-Path -LiteralPath (Join-Path $AgencyRoot ($Rel.Replace('/','\'))) -PathType Leaf)
}

Write-Host ''
Write-Host ("CRM_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)

if ($Failed -gt 0) {
    throw 'CRM AREA CONTRACT TEST FAILURE'
}

Write-Host '[PASS] ALL CRM AREA CONTRACT TESTS PASSED'
