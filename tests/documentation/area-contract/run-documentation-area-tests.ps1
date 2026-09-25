param([Parameter(Mandatory=$true)][string]$AgencyRoot)
$ErrorActionPreference='Stop'
$Passed=0
$Failed=0

function Read-J {
    param([string]$Rel)
    $Full=Join-Path $AgencyRoot ($Rel.Replace('/','\'))
    if(-not(Test-Path -LiteralPath $Full -PathType Leaf)){throw "Missing: $Rel"}
    Get-Content -LiteralPath $Full -Raw -Encoding UTF8 | ConvertFrom-Json
}
function Check {
    param([string]$Name,[bool]$Condition)
    if($Condition){Write-Host "[PASS] $Name";$script:Passed++}
    else{Write-Host "[FAIL] $Name";$script:Failed++}
}
function Exact-Array {
    param([object[]]$Actual,[object[]]$Expected)
    if(@($Actual).Count -ne @($Expected).Count){return $false}
    for($i=0;$i -lt @($Expected).Count;$i++){
        if([string]$Actual[$i] -cne [string]$Expected[$i]){return $false}
    }
    return $true
}

$Cases=Read-J 'tests/documentation/area-contract/cases.json'
$Area=Read-J 'config/documentation/area.json'
$Map=Read-J 'config/documentation/capability-map.json'
$Runtime=Read-J 'config/documentation/runtime-bindings.json'
$Bundle=Read-J 'config/documentation/skill-bundle.json'
$Agent=Read-J 'agents/documentation/proxtel-documentation-orchestrator/agent.json'
$Workflow=Read-J 'workflows/documentation/delivery/workflow.json'

$Subs=@($Cases.expected.subagents)
$Skills=@($Cases.expected.skills)

Check 'area-id' ([string]$Area.id -ceq 'documentation')
Check 'area-lifecycle' ([string]$Area.lifecycle_status -ceq [string]$Cases.expected.area_lifecycle)
Check 'area-provider-neutral' ([bool]$Area.provider_neutral)
Check 'area-parent' ([string]$Area.parent_commit -ceq [string]$Cases.expected.parent_commit)
Check 'area-source-grounded' ([bool]$Area.safety.source_grounded_first)
Check 'area-no-auto-commit' (-not [bool]$Area.safety.automatic_commit)
Check 'area-no-auto-push' (-not [bool]$Area.safety.automatic_push)

Check 'agent-id' ([string]$Agent.id -ceq 'proxtel-documentation-orchestrator')
Check 'agent-status' ([string]$Agent.status -ceq [string]$Cases.expected.agent_status)
Check 'agent-area' ([string]$Agent.area -ceq 'documentation')
Check 'agent-provider-neutral' ([bool]$Agent.provider_neutral)
Check 'agent-subagents-exact' (Exact-Array @($Agent.subagents|ForEach-Object{$_.id}) $Subs)
Check 'agent-skills-exact' (Exact-Array @($Agent.skills.candidate_domain) $Skills)
Check 'agent-dev-delegation' ([bool]$Agent.delegation.code_changes_require_development)
Check 'agent-source-authority' ([bool]$Agent.delegation.domain_facts_require_source_authority)
Check 'agent-tools=0' (@($Agent.tools.documentation_specific_tools).Count -eq 0)
Check 'agent-mcp=0' (@($Agent.mcp.documentation_specific_servers).Count -eq 0)

Check 'map-lanes=7' (@($Map.lanes).Count -eq 7)
Check 'map-dev-delegation' ([bool]$Map.delegation.development_required_for_code_changes)
Check 'map-source-authority' ([bool]$Map.delegation.domain_facts_must_come_from_owning_area_or_evidence)

Check 'runtime-bindings=7' (@($Runtime.bindings).Count -eq 7)
Check 'runtime-tools=0' (@($Runtime.tool_policy.documentation_specific_tools).Count -eq 0)
Check 'runtime-mcp=0' (@($Runtime.mcp_policy.documentation_specific_servers).Count -eq 0)
Check 'runtime-auto-tool=false' (-not [bool]$Runtime.tool_policy.automatic_tool_execution)
Check 'runtime-auto-mcp=false' (-not [bool]$Runtime.mcp_policy.automatic_approval)

Check 'bundle-skills-exact' (Exact-Array @($Bundle.domain_skills) $Skills)
Check 'bundle-auto=false' (-not [bool]$Bundle.activation.automatic_activation)
Check 'bundle-cert-required' ([bool]$Bundle.activation.certification_required_before_activation)

Check 'workflow-id' ([string]$Workflow.id -ceq 'documentation-delivery')
Check 'workflow-status' ([string]$Workflow.status -ceq [string]$Cases.expected.workflow_status)
Check 'workflow-area' ([string]$Workflow.area -ceq 'documentation')
Check 'workflow-steps=9' (@($Workflow.steps).Count -eq 9)
Check 'workflow-source-validation' (@($Workflow.steps|Where-Object{$_.id -eq 'source-owner-validation'}).Count -eq 1)
Check 'workflow-doc-qa' (@($Workflow.steps|Where-Object{$_.id -eq 'documentation-qa'}).Count -eq 1)
Check 'workflow-decisions=4' (@($Workflow.final_decisions).Count -eq 4)
Check 'workflow-no-auto-commit' ([bool]$Workflow.safety.automatic_commit_forbidden)
Check 'workflow-no-auto-push' ([bool]$Workflow.safety.automatic_push_forbidden)

foreach($Id in $Subs){
    $S=Read-J ("agents/documentation/subagents/"+$Id+"/subagent.json")
    Check ("sub-"+$Id+"-id") ([string]$S.id -ceq [string]$Id)
    Check ("sub-"+$Id+"-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status)
    Check ("sub-"+$Id+"-ephemeral") (-not [bool]$S.persistent)
    Check ("sub-"+$Id+"-no-code") (-not [bool]$S.limits.repository_code_implementation)
}
foreach($Id in $Skills){
    $S=Read-J ("skills/documentation/"+$Id+"/skill.json")
    Check ("skill-"+$Id+"-id") ([string]$S.id -ceq [string]$Id)
    Check ("skill-"+$Id+"-area") ([string]$S.area -ceq 'documentation')
    Check ("skill-"+$Id+"-status") ([string]$S.status -ceq [string]$Cases.expected.agent_status)
    Check ("skill-"+$Id+"-provider-neutral") ([bool]$S.provider_neutral)
    Check ("skill-"+$Id+"-no-packages") (@($S.dependencies.direct_packages).Count -eq 0)
    Check ("skill-"+$Id+"-cert-required") ([bool]$S.lifecycle.certification_required_before_activation)
}

$Docs=@(
'agents/documentation/proxtel-documentation-orchestrator/AGENT.md',
'workflows/documentation/delivery/WORKFLOW.md',
'standards/documentation/documentation-standard.md',
'docs/documentation/architecture.md',
'docs/documentation/operating-model.md'
)
foreach($Rel in $Docs){
    Check ("doc-"+$Rel) (Test-Path -LiteralPath (Join-Path $AgencyRoot ($Rel.Replace('/','\'))) -PathType Leaf)
}

Write-Host ""
Write-Host ("DOCUMENTATION_ASSERTIONS="+($Passed+$Failed))
Write-Host ("PASSED="+$Passed)
Write-Host ("FAILED="+$Failed)
if($Failed -gt 0){throw 'DOCUMENTATION AREA CONTRACT TEST FAILURE'}
Write-Host '[PASS] ALL DOCUMENTATION AREA CONTRACT TESTS PASSED'
