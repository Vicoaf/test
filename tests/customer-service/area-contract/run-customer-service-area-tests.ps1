param(
    [Parameter(Mandatory=$true)][string]$AgencyRoot
)

$ErrorActionPreference = 'Stop'
$Passed = 0
$Failed = 0

function Read-J {
    param([string]$Rel)
    $Full = Join-Path $AgencyRoot ($Rel.Replace('/','\'))
    if (-not (Test-Path -LiteralPath $Full -PathType Leaf)) { throw "Missing: $Rel" }
    return Get-Content -LiteralPath $Full -Raw -Encoding UTF8 | ConvertFrom-Json
}

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

function Exact-Array {
    param([object[]]$Actual,[object[]]$Expected)
    if (@($Actual).Count -ne @($Expected).Count) { return $false }
    for ($i=0; $i -lt @($Expected).Count; $i++) {
        if ([string]$Actual[$i] -cne [string]$Expected[$i]) { return $false }
    }
    return $true
}

$Cases = Read-J 'tests/customer-service/area-contract/cases.json'
$Area = Read-J 'config/customer-service/area.json'
$Map = Read-J 'config/customer-service/capability-map.json'
$Runtime = Read-J 'config/customer-service/runtime-bindings.json'
$Bundle = Read-J 'config/customer-service/skill-bundle.json'
$Agent = Read-J 'agents/customer-service/proxtel-customer-service-orchestrator/agent.json'
$Workflow = Read-J 'workflows/customer-service/delivery/workflow.json'

$ExpectedSubagents = @($Cases.expected.subagents)
$ExpectedSkills = @($Cases.expected.skills)

Write-Host '============================================================'
Write-Host ' PROXTEL CUSTOMER SERVICE AREA CONTRACT TESTS'
Write-Host '============================================================'

Check 'area-id' ([string]$Area.id -ceq 'customer-service')
Check 'area-lifecycle' ([string]$Area.lifecycle_status -ceq [string]$Cases.expected.area_lifecycle)
Check 'area-provider-neutral' ([bool]$Area.provider_neutral)
Check 'parent-commit' ([string]$Area.parent_commit -ceq [string]$Cases.expected.parent_commit)
Check 'area-no-auto-commit' (-not [bool]$Area.safety.automatic_commit)
Check 'area-no-auto-push' (-not [bool]$Area.safety.automatic_push)
Check 'area-pii-minimization' ([bool]$Area.safety.pii_minimization)

Check 'agent-id' ([string]$Agent.id -ceq 'proxtel-customer-service-orchestrator')
Check 'agent-status' ([string]$Agent.status -ceq [string]$Cases.expected.agent_status)
Check 'agent-area' ([string]$Agent.area -ceq 'customer-service')
Check 'agent-provider-neutral' ([bool]$Agent.provider_neutral)
Check 'agent-subagents-exact' (Exact-Array @($Agent.subagents | ForEach-Object {$_.id}) $ExpectedSubagents)
Check 'agent-skills-exact' (Exact-Array @($Agent.skills.candidate_domain) $ExpectedSkills)
Check 'agent-code-delegation' ([bool]$Agent.delegation.code_changes_require_development)
Check 'agent-crm-coordination' ([bool]$Agent.delegation.crm_domain_changes_require_crm_coordination)
Check 'agent-specific-tools=0' (@($Agent.tools.customer_service_specific_tools).Count -eq 0)
Check 'agent-specific-mcp=0' (@($Agent.mcp.customer_service_specific_servers).Count -eq 0)

Check 'capability-lanes' (@($Map.lanes).Count -eq [int]$Cases.expected.lane_count)
Check 'capability-dev-delegation' ([bool]$Map.delegation.development_required_for_code_changes)
Check 'capability-crm-delegation' ([bool]$Map.delegation.crm_required_when_crm_domain_contract_changes)

Check 'runtime-bindings=7' (@($Runtime.bindings).Count -eq 7)
Check 'runtime-specific-tools=0' (@($Runtime.tool_policy.customer_service_specific_tools).Count -eq 0)
Check 'runtime-specific-mcp=0' (@($Runtime.mcp_policy.customer_service_specific_servers).Count -eq 0)
Check 'runtime-auto-tool=false' (-not [bool]$Runtime.tool_policy.automatic_tool_execution)
Check 'runtime-auto-mcp=false' (-not [bool]$Runtime.mcp_policy.automatic_approval)

Check 'bundle-domain-skills-exact' (Exact-Array @($Bundle.domain_skills) $ExpectedSkills)
Check 'bundle-auto-activation=false' (-not [bool]$Bundle.activation.automatic_activation)
Check 'bundle-certification-required' ([bool]$Bundle.activation.certification_required_before_activation)

Check 'workflow-id' ([string]$Workflow.id -ceq 'customer-service-delivery')
Check 'workflow-status' ([string]$Workflow.status -ceq [string]$Cases.expected.workflow_status)
Check 'workflow-area' ([string]$Workflow.area -ceq 'customer-service')
Check 'workflow-steps=10' (@($Workflow.steps).Count -eq 10)
Check 'workflow-crm-coordination' (@($Workflow.steps | Where-Object {$_.id -ceq 'crm-coordination'}).Count -eq 1)
Check 'workflow-development-handoff' (@($Workflow.steps | Where-Object {$_.id -ceq 'development-handoff'}).Count -eq 1)
Check 'workflow-service-quality' (@($Workflow.steps | Where-Object {$_.id -ceq 'service-quality-review'}).Count -eq 1)
Check 'workflow-decisions=4' (@($Workflow.final_decisions).Count -eq 4)
Check 'workflow-no-auto-commit' ([bool]$Workflow.safety.automatic_commit_forbidden)
Check 'workflow-no-auto-push' ([bool]$Workflow.safety.automatic_push_forbidden)

foreach ($Id in $ExpectedSubagents) {
    $S = Read-J ("agents/customer-service/subagents/" + $Id + "/subagent.json")
    Check ("subagent-" + $Id + "-id") ([string]$S.id -ceq [string]$Id)
    Check ("subagent-" + $Id + "-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status)
    Check ("subagent-" + $Id + "-ephemeral") (-not [bool]$S.persistent)
    Check ("subagent-" + $Id + "-no-code") (-not [bool]$S.limits.repository_code_implementation)
}

foreach ($Id in $ExpectedSkills) {
    $S = Read-J ("skills/customer-service/" + $Id + "/skill.json")
    Check ("skill-" + $Id + "-id") ([string]$S.id -ceq [string]$Id)
    Check ("skill-" + $Id + "-area") ([string]$S.area -ceq 'customer-service')
    Check ("skill-" + $Id + "-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status)
    Check ("skill-" + $Id + "-provider-neutral") ([bool]$S.provider_neutral)
    Check ("skill-" + $Id + "-no-packages") (@($S.dependencies.direct_packages).Count -eq 0)
    Check ("skill-" + $Id + "-cert-required") ([bool]$S.lifecycle.certification_required_before_activation)
}

$Docs = @(
    'agents/customer-service/proxtel-customer-service-orchestrator/AGENT.md',
    'workflows/customer-service/delivery/WORKFLOW.md',
    'standards/customer-service/customer-service-standard.md',
    'docs/customer-service/architecture.md',
    'docs/customer-service/operating-model.md'
)

foreach ($Rel in $Docs) {
    Check ("doc-" + $Rel) (Test-Path -LiteralPath (Join-Path $AgencyRoot ($Rel.Replace('/','\'))) -PathType Leaf)
}

Write-Host ''
Write-Host ("CUSTOMER_SERVICE_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)

if ($Failed -gt 0) {
    throw 'CUSTOMER SERVICE AREA CONTRACT TEST FAILURE'
}

Write-Host '[PASS] ALL CUSTOMER SERVICE AREA CONTRACT TESTS PASSED'
