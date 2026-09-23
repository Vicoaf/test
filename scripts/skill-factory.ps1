param(
    [ValidateSet("Status","Plan","Start","Show")]
    [string]$Mode = "Status",

    [ValidateSet("Create","Update","AuditExternal")]
    [string]$Action,

    [string]$Request = "",

    [ValidateSet("core","development","documentation","crm","sales","customer-service","finance","marketing","pbx")]
    [string]$Area = "core",

    [string]$SubjectId = "",

    [string]$SourcePath = "",

    [ValidatePattern("^[A-Za-z0-9][A-Za-z0-9._-]*$")]
    [string]$RunId,

    [string]$WorkspaceRoot = "",

    [string]$AgencyRoot = "",

    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AgencyRoot)) {
    $AgencyRoot = Split-Path -Parent $PSScriptRoot
}

$AgencyRoot = [System.IO.Path]::GetFullPath($AgencyRoot)

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $AgencyRoot "config\skill-factory-operator.json"
}

if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    $RuntimeBase = $env:LOCALAPPDATA

    if ([string]::IsNullOrWhiteSpace($RuntimeBase)) {
        $RuntimeBase = Join-Path $env:USERPROFILE ".proxtel"
    }

    $WorkspaceRoot = Join-Path $RuntimeBase "PROXTEL-AI-AGENCY\skill-factory\runs"
}

$WorkspaceRoot = [System.IO.Path]::GetFullPath($WorkspaceRoot)

function Get-Sha {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ("Required file missing: " + $Path)
    }

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
    )

    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function Write-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )

    Write-Utf8NoBom -Path $Path -Content (ConvertTo-Json -InputObject $Object -Depth 100)
}

function Get-TreeFingerprint {
    param([Parameter(Mandatory = $true)][string]$Root)

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw ("Directory missing: " + $Root)
    }

    $Files = @(
        Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
        Sort-Object FullName
    )

    $Manifest = @()

    foreach ($File in $Files) {
        $Relative = $File.FullName.Substring($Root.Length).TrimStart("\")
        $Hash = (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash
        $Manifest += ($Relative + "|" + $Hash)
    }

    $Text = $Manifest -join "`n"
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $Sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        return ([System.BitConverter]::ToString($Sha.ComputeHash($Bytes))).Replace("-","")
    }
    finally {
        $Sha.Dispose()
    }
}

function Get-Baseline {
    $WorkflowPath = Join-Path $AgencyRoot "workflows\core\skill-factory\workflow.json"
    $CreatorPath = Join-Path $AgencyRoot "skills\core\proxtel-skill-creator\skill.json"
    $AuditorPath = Join-Path $AgencyRoot "skills\core\proxtel-skill-auditor\skill.json"

    foreach ($Path in @($WorkflowPath,$CreatorPath,$AuditorPath,$ConfigPath)) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw ("Skill Factory baseline missing: " + $Path)
        }
    }

    $Workflow = Get-Content -LiteralPath $WorkflowPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Creator = Get-Content -LiteralPath $CreatorPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Auditor = Get-Content -LiteralPath $AuditorPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

    if ([string]$Workflow.id -cne "skill-factory-operational" -or [string]$Workflow.status -cne "approved") {
        throw "Skill Factory workflow is not approved."
    }

    if ([string]$Creator.lifecycle.state -cne "approved") {
        throw "PROXTEL Skill Creator is not approved."
    }

    if ([string]$Auditor.lifecycle.state -cne "approved") {
        throw "PROXTEL Skill Auditor is not approved."
    }

    if ([string]$Config.id -cne "skill-factory-operator" -or [string]$Config.status -cne "approved") {
        throw "Skill Factory operator config is not approved."
    }

    return [pscustomobject]@{
        workflow = $Workflow
        creator = $Creator
        auditor = $Auditor
        config = $Config
        workflow_path = $WorkflowPath
        creator_path = $CreatorPath
        auditor_path = $AuditorPath
    }
}

function Require-PlanInput {
    if ([string]::IsNullOrWhiteSpace($Action)) {
        throw "Action is required for Plan or Start."
    }

    if ([string]::IsNullOrWhiteSpace($Request)) {
        throw "Request is required for Plan or Start."
    }

    if ($Action -eq "Update" -and [string]::IsNullOrWhiteSpace($SubjectId)) {
        throw "SubjectId is required for Update."
    }

    if ($Action -eq "AuditExternal") {
        if ([string]::IsNullOrWhiteSpace($SourcePath)) {
            throw "SourcePath is required for AuditExternal."
        }

        if (-not (Test-Path -LiteralPath $SourcePath)) {
            throw ("External SourcePath does not exist: " + $SourcePath)
        }
    }
}

function Get-Plan {
    Require-PlanInput

    $SourceType = switch ($Action) {
        "Create" { "internal-new" }
        "Update" { "internal-update" }
        "AuditExternal" { "external-source" }
        default { throw "Unsupported Action." }
    }

    return [pscustomobject]@{
        action = $Action
        area = $Area
        source_type = $SourceType
        subject_id = $SubjectId
        quarantine_required = ($Action -eq "AuditExternal")
        next_stage = "mechanism-router"
        next_owner = "proxtel-skill-creator"
        provider_execution_allowed = $false
        automatic_live_retry_allowed = $false
    }
}

$Baseline = Get-Baseline

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " PROXTEL AI AGENCY - SKILL FACTORY OPERATOR" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("Mode          : " + $Mode)
Write-Host ("Agency        : " + $AgencyRoot)
Write-Host ("Workspace     : " + $WorkspaceRoot)

if ($Mode -eq "Status") {
    Write-Host ""
    Write-Host "OPERATOR_STATUS=READY"
    Write-Host ("WORKFLOW_ID=" + [string]$Baseline.workflow.id)
    Write-Host ("WORKFLOW_VERSION=" + [string]$Baseline.workflow.version)
    Write-Host ("WORKFLOW_STATE=" + [string]$Baseline.workflow.status)
    Write-Host ("CREATOR_STATE=" + [string]$Baseline.creator.lifecycle.state)
    Write-Host ("AUDITOR_STATE=" + [string]$Baseline.auditor.lifecycle.state)
    Write-Host "PROVIDER_EXECUTION_ALLOWED=False"
    Write-Host "AUTOMATIC_LIVE_RETRY_ALLOWED=False"
    Write-Host "REPOSITORY_WRITE_PERFORMED=NO"
    Write-Host "WORKSPACE_WRITE_PERFORMED=NO"
    exit 0
}

if ($Mode -eq "Plan") {
    $Plan = Get-Plan

    Write-Host ""
    Write-Host "OPERATOR_PLAN=READY"
    Write-Host ("PLAN_ACTION=" + [string]$Plan.action)
    Write-Host ("PLAN_AREA=" + [string]$Plan.area)
    Write-Host ("PLAN_SOURCE_TYPE=" + [string]$Plan.source_type)
    Write-Host ("PLAN_QUARANTINE_REQUIRED=" + [bool]$Plan.quarantine_required)
    Write-Host ("PLAN_NEXT_STAGE=" + [string]$Plan.next_stage)
    Write-Host ("PLAN_NEXT_OWNER=" + [string]$Plan.next_owner)
    Write-Host "PROVIDER_EXECUTION_ALLOWED=False"
    Write-Host "AUTOMATIC_LIVE_RETRY_ALLOWED=False"
    Write-Host "REPOSITORY_WRITE_PERFORMED=NO"
    Write-Host "WORKSPACE_WRITE_PERFORMED=NO"
    exit 0
}

if ($Mode -eq "Start") {
    $Plan = Get-Plan

    if ([string]::IsNullOrWhiteSpace($RunId)) {
        $RunId = (
            "sf-" +
            (Get-Date -Format "yyyyMMdd-HHmmss") +
            "-" +
            [guid]::NewGuid().ToString("N").Substring(0,8)
        )
    }

    if ($RunId -notmatch "^[A-Za-z0-9][A-Za-z0-9._-]*$") {
        throw "RunId contains unsupported characters."
    }

    New-Item -ItemType Directory -Path $WorkspaceRoot -Force | Out-Null

    $FinalRunRoot = Join-Path $WorkspaceRoot $RunId
    $TempRunRoot = Join-Path $WorkspaceRoot (".tmp-" + $RunId + "-" + [guid]::NewGuid().ToString("N"))

    if (Test-Path -LiteralPath $FinalRunRoot) {
        throw ("RunId already exists: " + $RunId)
    }

    New-Item -ItemType Directory -Path $TempRunRoot -Force | Out-Null

    try {
        $EvidenceRoot = Join-Path $TempRunRoot "evidence"
        $OutputsRoot = Join-Path $TempRunRoot "outputs"
        New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null
        New-Item -ItemType Directory -Path $OutputsRoot -Force | Out-Null

        $SourceSnapshot = $null

        if ($Action -eq "AuditExternal") {
            $QuarantineRoot = Join-Path $TempRunRoot "quarantine"
            New-Item -ItemType Directory -Path $QuarantineRoot -Force | Out-Null

            $ResolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
            $LeafName = Split-Path -Leaf $ResolvedSource
            $SnapshotPath = Join-Path $QuarantineRoot $LeafName

            if (Test-Path -LiteralPath $ResolvedSource -PathType Leaf) {
                Copy-Item -LiteralPath $ResolvedSource -Destination $SnapshotPath
                $SnapshotHash = Get-Sha -Path $SnapshotPath
                $SnapshotKind = "file"
            }
            elseif (Test-Path -LiteralPath $ResolvedSource -PathType Container) {
                Copy-Item -LiteralPath $ResolvedSource -Destination $QuarantineRoot -Recurse
                $SnapshotHash = Get-TreeFingerprint -Root $SnapshotPath
                $SnapshotKind = "directory"
            }
            else {
                throw "Unsupported external source type."
            }

            $SourceSnapshot = [ordered]@{
                kind = $SnapshotKind
                original_path = $ResolvedSource
                quarantine_relative_path = ("quarantine/" + $LeafName)
                sha256 = $SnapshotHash
                executed = $false
            }
        }

        $RequestPath = Join-Path $TempRunRoot "request.md"
        $RequestLines = @(
            "# PROXTEL Skill Factory Run",
            "",
            ("RunId: " + $RunId),
            ("Action: " + $Action),
            ("Area: " + $Area),
            ("SubjectId: " + $SubjectId),
            "",
            "## Request",
            "",
            $Request
        )

        Write-Utf8NoBom -Path $RequestPath -Content ($RequestLines -join [Environment]::NewLine)

        $Run = [ordered]@{
            schema_version = "1.0"
            kind = "proxtel-skill-factory-run"
            run_id = $RunId
            state = "intake"
            action = $Action
            area = $Area
            subject_id = $SubjectId
            request = $Request
            source_type = [string]$Plan.source_type
            source_snapshot = $SourceSnapshot
            workflow = [ordered]@{
                id = [string]$Baseline.workflow.id
                version = [string]$Baseline.workflow.version
                sha256 = Get-Sha -Path $Baseline.workflow_path
            }
            creator = [ordered]@{
                id = [string]$Baseline.creator.id
                version = [string]$Baseline.creator.lifecycle.version
                state = [string]$Baseline.creator.lifecycle.state
                sha256 = Get-Sha -Path $Baseline.creator_path
            }
            auditor = [ordered]@{
                id = [string]$Baseline.auditor.id
                version = [string]$Baseline.auditor.lifecycle.version
                state = [string]$Baseline.auditor.lifecycle.state
                sha256 = Get-Sha -Path $Baseline.auditor_path
            }
            next_stage = [string]$Plan.next_stage
            next_owner = [string]$Plan.next_owner
            provider_execution_allowed = $false
            automatic_live_retry_allowed = $false
            repository_mutation_allowed = $false
            created_utc = [DateTime]::UtcNow.ToString("o")
        }

        $RunJsonPath = Join-Path $TempRunRoot "run.json"
        Write-Json -Path $RunJsonPath -Object $Run

        $VerifyRun = Get-Content -LiteralPath $RunJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ([string]$VerifyRun.run_id -cne $RunId -or [string]$VerifyRun.state -cne "intake") {
            throw "Run packet validation failed before promote."
        }

        Move-Item -LiteralPath $TempRunRoot -Destination $FinalRunRoot

        Write-Host ""
        Write-Host "RUN_CREATED=True"
        Write-Host ("RUN_ID=" + $RunId)
        Write-Host ("RUN_ROOT=" + $FinalRunRoot)
        Write-Host "RUN_STATE=intake"
        Write-Host ("RUN_ACTION=" + $Action)
        Write-Host ("RUN_SOURCE_TYPE=" + [string]$Plan.source_type)
        Write-Host ("RUN_NEXT_STAGE=" + [string]$Plan.next_stage)
        Write-Host ("RUN_NEXT_OWNER=" + [string]$Plan.next_owner)
        Write-Host "PROVIDER_EXECUTION_ALLOWED=False"
        Write-Host "AUTOMATIC_LIVE_RETRY_ALLOWED=False"
        Write-Host "REPOSITORY_WRITE_PERFORMED=NO"
        Write-Host "WORKSPACE_WRITE_PERFORMED=YES"
        exit 0
    }
    catch {
        if (Test-Path -LiteralPath $TempRunRoot -PathType Container) {
            Remove-Item -LiteralPath $TempRunRoot -Recurse -Force -ErrorAction SilentlyContinue
        }

        throw
    }
}

if ($Mode -eq "Show") {
    if ([string]::IsNullOrWhiteSpace($RunId)) {
        throw "RunId is required for Show."
    }

    $RunRoot = Join-Path $WorkspaceRoot $RunId
    $RunJsonPath = Join-Path $RunRoot "run.json"

    if (-not (Test-Path -LiteralPath $RunJsonPath -PathType Leaf)) {
        throw ("Run not found: " + $RunId)
    }

    $Run = Get-Content -LiteralPath $RunJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

    Write-Host ""
    Write-Host "RUN_FOUND=True"
    Write-Host ("RUN_ID=" + [string]$Run.run_id)
    Write-Host ("RUN_STATE=" + [string]$Run.state)
    Write-Host ("RUN_ACTION=" + [string]$Run.action)
    Write-Host ("RUN_AREA=" + [string]$Run.area)
    Write-Host ("RUN_SOURCE_TYPE=" + [string]$Run.source_type)
    Write-Host ("RUN_NEXT_STAGE=" + [string]$Run.next_stage)
    Write-Host ("RUN_NEXT_OWNER=" + [string]$Run.next_owner)
    Write-Host "PROVIDER_EXECUTION_ALLOWED=False"
    Write-Host "AUTOMATIC_LIVE_RETRY_ALLOWED=False"
    Write-Host "REPOSITORY_WRITE_PERFORMED=NO"
    Write-Host "WORKSPACE_WRITE_PERFORMED=NO"
    exit 0
}

throw ("Unsupported Mode: " + $Mode)