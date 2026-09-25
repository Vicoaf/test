param(
    [Parameter(Mandatory=$true)]
    [string]$AgencyRoot
)

$ErrorActionPreference = 'Stop'
$Passed = 0
$Failed = 0

function Check {
    param([string]$Name,[bool]$Condition)
    if ($Condition) { Write-Host "[PASS] $Name"; $script:Passed++ } else { Write-Host "[FAIL] $Name"; $script:Failed++ }
}

function Read-J {
    param([string]$P)
    return Get-Content -LiteralPath $P -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
}

$RuntimeRoot = Join-Path $AgencyRoot 'runtime\production-v1'
$Cases = Read-J (Join-Path $AgencyRoot 'tests\runtime\production-v1\cases.json')
$Activation = Read-J (Join-Path $AgencyRoot 'config\production-runtime.json')
$Runtime = Read-J (Join-Path $RuntimeRoot 'runtime.json')
$Router = Read-J (Join-Path $RuntimeRoot 'router.json')
$Providers = Read-J (Join-Path $RuntimeRoot 'providers.json')
$Types = Read-J (Join-Path $RuntimeRoot 'project-types.json')
$Gates = Read-J (Join-Path $RuntimeRoot 'approval-gates.json')
$Workflow = Read-J (Join-Path $RuntimeRoot 'workflow.json')
$Cli = Join-Path $AgencyRoot 'scripts\proxtel.ps1'
$Cmd = Join-Path $AgencyRoot 'bin\proxtel.cmd'

Check 'activation-lifecycle' ([string]$Activation.lifecycle -ceq [string]$Cases.expected.lifecycle)
Check 'activation-status' ([string]$Activation.activation -ceq [string]$Cases.expected.activation)
Check 'runtime-status' ([string]$Runtime.status -ceq [string]$Cases.expected.runtime_status)
Check 'runtime-version' ([string]$Runtime.version -ceq [string]$Cases.expected.runtime_version)
Check 'runtime-command-count' (@($Runtime.commands).Count -eq [int]$Cases.expected.command_count)
Check 'workflow-status' ([string]$Workflow.status -ceq [string]$Cases.expected.workflow_status)
Check 'project-types-count' (@($Types.types).Count -eq [int]$Cases.expected.project_type_count)
Check 'provider-count' (@($Providers.providers).Count -eq [int]$Cases.expected.provider_count)
Check 'provider-auto-disabled' (-not [bool]$Providers.automatic_execution)
Check 'approval-gates-count' (@($Gates.gates).Count -eq [int]$Cases.expected.approval_gate_count)
Check 'cli-exists' (Test-Path -LiteralPath $Cli -PathType Leaf)
Check 'cmd-exists' (Test-Path -LiteralPath $Cmd -PathType Leaf)
Check 'router-area-order-8' (@($Router.area_order).Count -eq 8)

$Tokens=$null
$Errors=$null
[System.Management.Automation.Language.Parser]::ParseFile($Cli,[ref]$Tokens,[ref]$Errors) | Out-Null
Check 'cli-parses' ($Errors.Count -eq 0)

$Smoke = Join-Path $env:TEMP 'PROXTEL-RUNTIME-V1-SMOKE'
if (Test-Path -LiteralPath $Smoke) { Remove-Item -LiteralPath $Smoke -Recurse -Force }

$NewOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Cli new -Name 'Runtime Smoke' -Type webtrader -Path $Smoke -Stack 'Laravel + React + MySQL' 2>&1)
$NewExit = $LASTEXITCODE
Check 'bootstrap-exit-zero' ($NewExit -eq 0)
Check 'bootstrap-manifest-exists' (Test-Path -LiteralPath (Join-Path $Smoke '.proxtel\project.json') -PathType Leaf)

$Project = Read-J (Join-Path $Smoke '.proxtel\project.json')
Check 'bootstrap-type-webtrader' ([string]$Project.type -ceq 'webtrader')
Check 'bootstrap-webtrader-area-count' (@($Project.selected_areas).Count -eq [int]$Cases.expected.webtrader_area_count)
Check 'bootstrap-memory-exists' (Test-Path -LiteralPath (Join-Path $Smoke '.proxtel\memory\PROJECT_CONTEXT.md') -PathType Leaf)
Check 'bootstrap-queue-exists' (Test-Path -LiteralPath (Join-Path $Smoke '.proxtel\task-queue.json') -PathType Leaf)

$RouteOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Cli route -Project $Smoke -Request 'Review Asterisk PJSIP trunk and PBX routing' 2>&1)
$RouteExit = $LASTEXITCODE
Check 'route-exit-zero' ($RouteExit -eq 0)
Check 'route-adds-pbx' ((($RouteOutput -join "`n") -match 'ROUTED_AREAS=.*pbx'))

$TaskOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Cli task -Project $Smoke -Title 'PBX Integration' -Request 'Review Asterisk PJSIP trunk and CRM click to call' 2>&1)
$TaskExit = $LASTEXITCODE
Check 'task-exit-zero' ($TaskExit -eq 0)

$TaskIdLine = @($TaskOutput | Where-Object { [string]$_ -match '^TASK_ID=' })
Check 'task-id-produced' ($TaskIdLine.Count -eq 1)

if ($TaskIdLine.Count -eq 1) {
    $TaskId = ([string]$TaskIdLine[0]).Substring(8)
    Check 'task-file-exists' (Test-Path -LiteralPath (Join-Path $Smoke ('.proxtel\tasks\'+$TaskId+'.json')) -PathType Leaf)
    Check 'packet-file-exists' (Test-Path -LiteralPath (Join-Path $Smoke ('.proxtel\packets\'+$TaskId+'.json')) -PathType Leaf)
    $Packet = Read-J (Join-Path $Smoke ('.proxtel\packets\'+$TaskId+'.json'))
    Check 'packet-includes-pbx' (@($Packet.routed_areas) -contains 'pbx')
    Check 'packet-provider-explicit' ([string]$Packet.provider_execution -ceq 'explicit-per-task')
    Check 'packet-qa-required' ([bool]$Packet.gates.qa_required)
    Check 'packet-commit-gated' ([bool]$Packet.gates.git_commit_requires_approval)
    Check 'packet-pbx-live-gated' ([bool]$Packet.gates.pbx_live_change_requires_approval)
}

$Queue = Read-J (Join-Path $Smoke '.proxtel\task-queue.json')
Check 'queue-count-one' (@($Queue.tasks).Count -eq 1)

Remove-Item -LiteralPath $Smoke -Recurse -Force

Write-Host "RUNTIME_ASSERTIONS=$($Passed+$Failed)"
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"

if ($Failed -gt 0) { exit 1 }

Write-Host '[PASS] PRODUCTION RUNTIME CONTRACTS PASSED'
exit 0
