param(
    [Parameter(Position=0)]
    [ValidateSet('help','status','doctor','new','route','task')]
    [string]$Command = 'help',

    [string]$Name,
    [string]$Slug,
    [string]$Type = 'generic',
    [string]$Path,
    [string]$Stack,

    [string]$Project,
    [string]$Title,
    [string]$Request
)

$ErrorActionPreference = 'Stop'

$AgencyRoot = Split-Path -Parent $PSScriptRoot
$RuntimeRoot = Join-Path $AgencyRoot 'runtime\production-v1'

function Read-J {
    param([string]$P)
    return Get-Content -LiteralPath $P -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
}

function Write-J {
    param([string]$P,$Object)
    $Parent = Split-Path -Parent $P
    if (-not (Test-Path -LiteralPath $Parent -PathType Container)) { New-Item -ItemType Directory -Path $Parent -Force | Out-Null }
    $Enc = New-Object System.Text.UTF8Encoding($false)
    $Json = $Object | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($P,($Json.TrimEnd("`r","`n")+"`n"),$Enc)
}

function Get-Slug {
    param([string]$Value)
    $S = $Value.ToLowerInvariant() -replace '[^a-z0-9]+','-'
    return $S.Trim('-')
}

function Get-ProjectManifest {
    param([string]$ProjectRoot)
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { throw '-Project is required.' }
    $Manifest = Join-Path $ProjectRoot '.proxtel\project.json'
    if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) { throw "Not a PROXTEL project: $ProjectRoot" }
    return Read-J $Manifest
}

function Get-RoutedAreas {
    param($Manifest,[string]$Text)
    $Router = Read-J (Join-Path $RuntimeRoot 'router.json')
    $Set = @{}
    foreach ($Area in @($Manifest.selected_areas)) { $Set[[string]$Area] = $true }
    foreach ($Rule in @($Router.keyword_routes)) {
        if ($Text -match ('(?i)' + [string]$Rule.pattern)) { $Set[[string]$Rule.area] = $true }
    }
    $Result = @()
    foreach ($Area in @($Router.area_order)) { if ($Set.ContainsKey([string]$Area)) { $Result += [string]$Area } }
    return @($Result)
}

switch ($Command.ToLowerInvariant()) {

    'help' {
        Write-Host 'PROXTEL AI AGENCY - Production Runtime v1'
        Write-Host ''
        Write-Host 'proxtel status'
        Write-Host 'proxtel doctor'
        Write-Host 'proxtel new -Name "Proyecto" -Type webtrader -Path "C:\DEV\WEBS\proyecto" -Stack "Laravel + React + MySQL"'
        Write-Host 'proxtel route -Project "C:\DEV\WEBS\proyecto" -Request "Crear autenticacion"'
        Write-Host 'proxtel task -Project "C:\DEV\WEBS\proyecto" -Title "Autenticacion" -Request "Crear login seguro"'
        exit 0
    }

    'status' {
        $Runtime = Read-J (Join-Path $RuntimeRoot 'runtime.json')
        $Activation = Read-J (Join-Path $AgencyRoot 'config\production-runtime.json')
        Write-Host "PROXTEL_RUNTIME_VERSION=$($Runtime.version)"
        Write-Host "PROXTEL_RUNTIME_STATUS=$($Runtime.status)"
        Write-Host "PROXTEL_RUNTIME_ACTIVATION=$($Activation.activation)"
        Write-Host "AGENCY_ROOT=$AgencyRoot"
        Write-Host "PARENT_GOLD_MASTER=$($Runtime.parent_gold_master_commit)"
        if (-not [string]::IsNullOrWhiteSpace($Project)) {
            $M = Get-ProjectManifest $Project
            Write-Host "PROJECT_ID=$($M.id)"
            Write-Host "PROJECT_NAME=$($M.name)"
            Write-Host "PROJECT_TYPE=$($M.type)"
            Write-Host "PROJECT_STATUS=$($M.status)"
            Write-Host "PROJECT_AREAS=$(@($M.selected_areas) -join ',')"
        }
        exit 0
    }

    'doctor' {
        Write-Host 'PROXTEL_DOCTOR_BEGIN'
        foreach ($Cmd in @('git','claude','codex','agy')) {
            $Found = Get-Command $Cmd -ErrorAction SilentlyContinue
            if ($null -eq $Found) { Write-Host "$($Cmd.ToUpperInvariant())=MISSING" } else { Write-Host "$($Cmd.ToUpperInvariant())=AVAILABLE" }
        }
        Write-Host 'PROVIDER_EXECUTION=EXPLICIT-PER-TASK'
        Write-Host 'AUTOMATIC_PROVIDER_EXECUTION=DISABLED'
        Write-Host 'PROXTEL_DOCTOR_END'
        exit 0
    }

    'new' {
        if ([string]::IsNullOrWhiteSpace($Name)) { throw '-Name is required.' }
        if ([string]::IsNullOrWhiteSpace($Path)) { throw '-Path is required.' }
        if ([string]::IsNullOrWhiteSpace($Slug)) { $Slug = Get-Slug $Name }
        if ([string]::IsNullOrWhiteSpace($Stack)) { $Stack = 'To be defined' }

        $Types = Read-J (Join-Path $RuntimeRoot 'project-types.json')
        $Match = @($Types.types | Where-Object { [string]$_.id -ceq $Type })
        if ($Match.Count -ne 1) { throw "Unknown project type: $Type" }

        if (-not (Test-Path -LiteralPath $Path -PathType Container)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }

        $Px = Join-Path $Path '.proxtel'
        $ManifestPath = Join-Path $Px 'project.json'
        if (Test-Path -LiteralPath $ManifestPath) { throw "Project already bootstrapped: $Path" }

        foreach ($Dir in @('tasks','packets','evidence','memory')) { New-Item -ItemType Directory -Path (Join-Path $Px $Dir) -Force | Out-Null }

        $Manifest = [PSCustomObject][ordered]@{
            schema_version='1.0'
            kind='proxtel-project'
            id=$Slug
            name=$Name
            type=$Type
            root=$Path
            stack=$Stack
            status='ACTIVE'
            created_utc=[DateTime]::UtcNow.ToString('o')
            agency=[ordered]@{
                root=$AgencyRoot
                production_runtime='1.0.0'
                gold_master_commit='f44e317e2301d35477132bdfbde86a0573f1992c'
            }
            selected_areas=@($Match[0].areas)
            execution=[ordered]@{
                provider_mode='explicit-per-task'
                automatic_commit=$false
                automatic_push=$false
                automatic_deploy=$false
                qa_required=$true
                evidence_required=$true
            }
        }

        Write-J $ManifestPath $Manifest

        Write-J (Join-Path $Px 'state.json') ([PSCustomObject][ordered]@{ status='READY'; current_task=$null; updated_utc=[DateTime]::UtcNow.ToString('o') })
        Write-J (Join-Path $Px 'task-queue.json') ([PSCustomObject][ordered]@{ schema_version='1.0'; tasks=@() })
        Write-J (Join-Path $Px 'approvals.json') ([PSCustomObject][ordered]@{ schema_version='1.0'; approvals=@() })
        Write-J (Join-Path $Px 'evidence\index.json') ([PSCustomObject][ordered]@{ schema_version='1.0'; evidence=@() })

        $Context = @(
            '# PROXTEL Project Context',
            '',
            ("Project: " + $Name),
            ("ID: " + $Slug),
            ("Type: " + $Type),
            ("Stack: " + $Stack),
            ("Areas: " + (@($Match[0].areas) -join ', ')),
            '',
            'This file is project-local memory. Keep durable architectural decisions, constraints and validated context here.',
            ''
        ) -join "`n"

        $Enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText((Join-Path $Px 'memory\PROJECT_CONTEXT.md'),($Context+"`n"),$Enc)

        Write-Host 'PROJECT_BOOTSTRAP_STATUS=SUCCESS'
        Write-Host "PROJECT_ID=$Slug"
        Write-Host "PROJECT_ROOT=$Path"
        Write-Host "PROJECT_TYPE=$Type"
        Write-Host "PROJECT_AREAS=$(@($Match[0].areas) -join ',')"
        Write-Host 'NEXT_ACTION=CREATE-TASK'
        exit 0
    }

    'route' {
        if ([string]::IsNullOrWhiteSpace($Request)) { throw '-Request is required.' }
        $M = Get-ProjectManifest $Project
        $Areas = @(Get-RoutedAreas $M $Request)
        Write-Host "ROUTED_PROJECT=$($M.id)"
        Write-Host "ROUTED_AREAS=$($Areas -join ',')"
        Write-Host 'PROVIDER_PLAN=CLAUDE-ARCHITECTURE,CODEX-IMPLEMENTATION,ANTIGRAVITY-AUDIT'
        Write-Host 'PROVIDER_EXECUTION=EXPLICIT-PER-TASK'
        exit 0
    }

    'task' {
        if ([string]::IsNullOrWhiteSpace($Title)) { throw '-Title is required.' }
        if ([string]::IsNullOrWhiteSpace($Request)) { throw '-Request is required.' }

        $M = Get-ProjectManifest $Project
        $Areas = @(Get-RoutedAreas $M $Request)

        $Sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes(($M.id + '|' + $Title + '|' + $Request))
            $Hash = [System.BitConverter]::ToString($Sha.ComputeHash($Bytes)).Replace('-','').Substring(0,8)
        } finally { $Sha.Dispose() }

        $TaskId = 'TASK-' + (Get-Date -Format 'yyyyMMddHHmmss') + '-' + $Hash
        $Px = Join-Path $Project '.proxtel'

        $TaskObject = [PSCustomObject][ordered]@{
            schema_version='1.0'
            id=$TaskId
            project_id=$M.id
            title=$Title
            request=$Request
            status='READY-FOR-ORCHESTRATION'
            created_utc=[DateTime]::UtcNow.ToString('o')
            routed_areas=$Areas
            qa_required=$true
            evidence_required=$true
            approval_state='NOT-REQUIRED-YET'
        }

        $Providers = Read-J (Join-Path $RuntimeRoot 'providers.json')

        $Packet = [PSCustomObject][ordered]@{
            schema_version='1.0'
            kind='proxtel-execution-packet'
            task_id=$TaskId
            project_id=$M.id
            project_root=$Project
            request=$Request
            routed_areas=$Areas
            provider_plan=@($Providers.default_plan)
            provider_execution='explicit-per-task'
            context=[ordered]@{
                project_manifest='.proxtel/project.json'
                project_memory='.proxtel/memory/PROJECT_CONTEXT.md'
            }
            gates=[ordered]@{
                qa_required=$true
                git_commit_requires_approval=$true
                git_push_requires_approval=$true
                dependency_install_requires_approval=$true
                deploy_requires_approval=$true
                production_mutation_requires_approval=$true
                pbx_live_change_requires_approval=$true
            }
            state='READY'
        }

        Write-J (Join-Path $Px ('tasks\' + $TaskId + '.json')) $TaskObject
        Write-J (Join-Path $Px ('packets\' + $TaskId + '.json')) $Packet

        $QueuePath = Join-Path $Px 'task-queue.json'
        $Queue = Read-J $QueuePath
        $Existing = @($Queue.tasks)
        $Queue.tasks = @($Existing + $TaskId)
        Write-J $QueuePath $Queue

        $StatePath = Join-Path $Px 'state.json'
        $State = Read-J $StatePath
        $State.status = 'TASK-READY'
        $State.current_task = $TaskId
        $State.updated_utc = [DateTime]::UtcNow.ToString('o')
        Write-J $StatePath $State

        Write-Host 'TASK_CREATE_STATUS=SUCCESS'
        Write-Host "TASK_ID=$TaskId"
        Write-Host "TASK_TITLE=$Title"
        Write-Host "ROUTED_AREAS=$($Areas -join ',')"
        Write-Host "PACKET=.proxtel/packets/$TaskId.json"
        Write-Host 'PROVIDER_PLAN=CLAUDE-ARCHITECTURE,CODEX-IMPLEMENTATION,ANTIGRAVITY-AUDIT'
        Write-Host 'PROVIDER_EXECUTION=EXPLICIT-PER-TASK'
        Write-Host 'NEXT_ACTION=ORCHESTRATE-TASK'
        exit 0
    }
}
