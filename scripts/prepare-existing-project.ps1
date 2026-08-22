param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "website",
        "landing-page",
        "laravel",
        "crm",
        "saas"
    )]
    [string]$Bundle,

    [ValidateSet(
        "Check",
        "Prepare"
    )]
    [string]$Mode = "Check"
)

$ErrorActionPreference = "Stop"

$AgencyRoot = Split-Path -Parent $PSScriptRoot

$SkillInstaller = Join-Path `
    $AgencyRoot `
    "scripts\install-project-skills.ps1"

function Test-CommandExists {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    return [bool](
        Get-Command `
            $Command `
            -ErrorAction SilentlyContinue
    )
}

function Write-Utf8File {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $directory = Split-Path `
        -Parent `
        $Path

    if (
        $directory -and
        -not (Test-Path $directory)
    ) {

        New-Item `
            -ItemType Directory `
            -Path $directory `
            -Force |
            Out-Null
    }

    Set-Content `
        -Path $Path `
        -Value $Content `
        -Encoding UTF8
}

function Get-ProjectFiles {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $excludedDirectories = @(
        ".git",
        "node_modules",
        "vendor"
    )

    $queue = New-Object System.Collections.Queue

    $rootItem = Get-Item `
        -LiteralPath $Root `
        -Force

    $queue.Enqueue($rootItem)

    while ($queue.Count -gt 0) {

        $currentDirectory = $queue.Dequeue()

        $items = @(
            Get-ChildItem `
                -LiteralPath $currentDirectory.FullName `
                -Force `
                -ErrorAction SilentlyContinue
        )

        foreach ($item in $items) {

            if ($item.PSIsContainer) {

                if (
                    $excludedDirectories -notcontains
                    $item.Name
                ) {

                    $queue.Enqueue($item)
                }
            }
            else {

                Write-Output $item
            }
        }
    }
}

function Test-SensitiveCandidate {

    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $name = [System.IO.Path]::GetFileName(
        $RelativePath
    )

    if ($name -ieq ".env.example") {
        return $false
    }

    if ($name -ieq ".env") {
        return $true
    }

    if ($name -like ".env.*") {
        return $true
    }

    if ($name -ieq ".npmrc") {
        return $true
    }

    if ($name -ieq ".pypirc") {
        return $true
    }

    if ($name -ieq "auth.json") {
        return $true
    }

    if ($name -like "credentials*.json") {
        return $true
    }

    if ($name -like "service-account*.json") {
        return $true
    }

    $extension = [System.IO.Path]::GetExtension(
        $name
    ).ToLowerInvariant()

    if (
        $extension -in @(
            ".pem",
            ".key",
            ".p12",
            ".pfx"
        )
    ) {

        return $true
    }

    return $false
}

function Get-NormalizedPath {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (
        [System.IO.Path]::GetFullPath(
            $Path
        )
    ).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " PROXTEL AI AGENCY - EXISTING PROJECT PREPARATION" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

if (-not (Test-Path $ProjectPath)) {

    throw "Project path does not exist: $ProjectPath"
}

$projectItem = Get-Item `
    -LiteralPath $ProjectPath `
    -Force

if (-not $projectItem.PSIsContainer) {

    throw "ProjectPath must be a directory: $ProjectPath"
}

$ResolvedProject = (
    Resolve-Path `
        -LiteralPath $ProjectPath
).Path

$topLevelItems = @(
    Get-ChildItem `
        -LiteralPath $ResolvedProject `
        -Force `
        -ErrorAction Stop
)

if ($topLevelItems.Count -eq 0) {

    throw "Existing project directory is empty: $ResolvedProject"
}

if (-not (Test-Path $SkillInstaller)) {

    throw "Missing project skill installer: $SkillInstaller"
}

Write-Host "Mode       : $Mode"
Write-Host "Project    : $ResolvedProject"
Write-Host "Bundle     : $Bundle"

Write-Host ""

Write-Host "------------------------------------------------------------"
Write-Host " PROJECT MARKERS" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$markers = [ordered]@{
    "index.html"       = Test-Path (Join-Path $ResolvedProject "index.html")
    "index.php"        = Test-Path (Join-Path $ResolvedProject "index.php")
    "composer.json"    = Test-Path (Join-Path $ResolvedProject "composer.json")
    "package.json"     = Test-Path (Join-Path $ResolvedProject "package.json")
    "artisan"          = Test-Path (Join-Path $ResolvedProject "artisan")
    "vite.config.js"   = Test-Path (Join-Path $ResolvedProject "vite.config.js")
    "vite.config.ts"   = Test-Path (Join-Path $ResolvedProject "vite.config.ts")
    "AGENTS.md"        = Test-Path (Join-Path $ResolvedProject "AGENTS.md")
    ".gitignore"       = Test-Path (Join-Path $ResolvedProject ".gitignore")
    ".editorconfig"    = Test-Path (Join-Path $ResolvedProject ".editorconfig")
}

foreach ($marker in $markers.GetEnumerator()) {

    $state = if ($marker.Value) {
        "YES"
    }
    else {
        "NO"
    }

    Write-Host ("{0,-20}: {1}" -f $marker.Key, $state)
}

Write-Host ""

Write-Host "Important:"
Write-Host "Presence of a marker does not prove framework version or architecture."

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " SENSITIVE FILE CANDIDATES" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$projectFiles = @(
    Get-ProjectFiles `
        -Root $ResolvedProject
)

$sensitiveCandidates = @()

foreach ($file in $projectFiles) {

    $relativePath = $file.FullName.Substring(
        $ResolvedProject.Length
    ).TrimStart("\")

    if (
        Test-SensitiveCandidate `
            -RelativePath $relativePath
    ) {

        $sensitiveCandidates += $relativePath
    }
}

if ($sensitiveCandidates.Count -eq 0) {

    Write-Host "Sensitive candidates found: 0" `
        -ForegroundColor Green
}
else {

    Write-Host "Sensitive candidates found: $($sensitiveCandidates.Count)" `
        -ForegroundColor Yellow

    foreach ($candidate in $sensitiveCandidates) {

        Write-Host " - $candidate" `
            -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "File contents were NOT inspected or displayed." `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " GIT" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$gitAvailable = Test-CommandExists "git"

$gitRepoRoot = $null
$isProjectRepoRoot = $false
$gitBranch = $null
$gitStatusLines = @()
$trackedSensitiveFiles = @()
$hasGitCommit = $false

if (-not $gitAvailable) {

    Write-Host "Git available : NO" `
        -ForegroundColor Red
}
else {

    Write-Host "Git available : YES" `
        -ForegroundColor Green

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    $gitRootOutput = @(
        git -C $ResolvedProject `
            rev-parse `
            --show-toplevel `
            2>$null
    )

    $gitRootExitCode = $LASTEXITCODE

    $ErrorActionPreference = $previousErrorActionPreference

    if (
        $gitRootExitCode -eq 0 -and
        $gitRootOutput.Count -gt 0
    ) {

        $gitRepoRoot = $gitRootOutput[0]

        $normalizedProject = Get-NormalizedPath `
            -Path $ResolvedProject

        $normalizedGitRoot = Get-NormalizedPath `
            -Path $gitRepoRoot

        $isProjectRepoRoot = (
            $normalizedProject -ieq
            $normalizedGitRoot
        )

        Write-Host "Git repository: YES" `
            -ForegroundColor Green

        Write-Host "Git root      : $gitRepoRoot"

        if ($isProjectRepoRoot) {

            Write-Host "Project root   : MATCH" `
                -ForegroundColor Green
        }
        else {

            Write-Host "Project root   : INSIDE ANOTHER REPOSITORY" `
                -ForegroundColor Yellow
        }

        $branchOutput = @(
            git -C $ResolvedProject `
                branch `
                --show-current `
                2>$null
        )

        if (
            $LASTEXITCODE -eq 0 -and
            $branchOutput.Count -gt 0
        ) {

            $gitBranch = $branchOutput[0]
        }

        if (
            [string]::IsNullOrWhiteSpace(
                $gitBranch
            )
        ) {

            Write-Host "Branch         : DETACHED OR UNRESOLVED"
        }
        else {

            Write-Host "Branch         : $gitBranch"
        }

        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"

        git -C $ResolvedProject `
            rev-parse `
            --verify `
            HEAD `
            *> $null

        $gitHeadExitCode = $LASTEXITCODE

        $ErrorActionPreference = $previousErrorActionPreference

        if ($gitHeadExitCode -eq 0) {

            $hasGitCommit = $true
        }

        Write-Host "Has commit     : $hasGitCommit"

        $gitStatusLines = @(
            git -C $ResolvedProject `
                status `
                --porcelain `
                2>$null
        )

        if ($gitStatusLines.Count -eq 0) {

            Write-Host "Working tree   : CLEAN" `
                -ForegroundColor Green
        }
        else {

            Write-Host "Working tree   : DIRTY" `
                -ForegroundColor Yellow

            Write-Host "Pending entries: $($gitStatusLines.Count)"
        }

        $trackedFiles = @(
            git -C $ResolvedProject `
                ls-files `
                2>$null
        )

        foreach ($trackedFile in $trackedFiles) {

            if (
                Test-SensitiveCandidate `
                    -RelativePath $trackedFile
            ) {

                $trackedSensitiveFiles += $trackedFile
            }
        }

        if ($trackedSensitiveFiles.Count -gt 0) {

            Write-Host ""
            Write-Host "WARNING: sensitive candidate files are tracked by Git:" `
                -ForegroundColor Red

            foreach ($trackedSensitive in $trackedSensitiveFiles) {

                Write-Host " - $trackedSensitive" `
                    -ForegroundColor Red
            }
        }
        else {

            Write-Host "Tracked sensitive candidates: 0" `
                -ForegroundColor Green
        }
    }
    else {

        Write-Host "Git repository: NO" `
            -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " AGENT CONFIGURATION" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$agentsFile = Join-Path `
    $ResolvedProject `
    "AGENTS.md"

$rulesFolder = Join-Path `
    $ResolvedProject `
    ".agents\rules"

$proxtelRule = Join-Path `
    $rulesFolder `
    "proxtel-project.md"

$skillsFolder = Join-Path `
    $ResolvedProject `
    ".agents\skills"

Write-Host "AGENTS.md                  : $(Test-Path $agentsFile)"
Write-Host ".agents/rules              : $(Test-Path $rulesFolder)"
Write-Host "proxtel-project.md          : $(Test-Path $proxtelRule)"
Write-Host ".agents/skills             : $(Test-Path $skillsFolder)"

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " PROJECT SKILLS" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

& $SkillInstaller `
    -ProjectPath $ResolvedProject `
    -Bundle $Bundle `
    -Mode Check

if (-not $?) {

    throw "Project Skill check failed."
}

if ($Mode -eq "Check") {

    Write-Host ""
    Write-Host "============================================================" `
        -ForegroundColor Cyan

    Write-Host " CHECK COMPLETE" `
        -ForegroundColor Green

    Write-Host "============================================================" `
        -ForegroundColor Cyan

    Write-Host ""
    Write-Host "No project files were modified." `
        -ForegroundColor Green

    Write-Host "No Git repository was initialized."
    Write-Host "No Git staging or commit was performed."
    Write-Host "No application code was modified."
    Write-Host "No sensitive file contents were displayed."

    exit 0
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " PREPARE VALIDATION" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

if (-not $gitAvailable) {

    throw "Prepare requires Git to be available in PATH."
}

if (
    $gitRepoRoot -and
    -not $isProjectRepoRoot
) {

    throw "Project is inside another Git repository. Prepare stopped to avoid modifying the parent repository."
}

if (
    $gitRepoRoot -and
    $gitStatusLines.Count -gt 0
) {

    throw "Existing Git working tree is not clean. Prepare stopped. Protect or commit current work before continuing."
}

if ($trackedSensitiveFiles.Count -gt 0) {

    throw "Sensitive candidate files are tracked by Git. Prepare stopped for manual review."
}

Write-Host "Safety validation passed." `
    -ForegroundColor Green

Write-Host ""

if (-not (Test-Path $agentsFile)) {

    $agentsContent = @"
# AGENTS.md

## Existing project

This is an existing project.

Before modifying application code:

1. Inspect the repository.
2. Inspect the current architecture and stack.
3. Check Git status.
4. Preserve existing functionality.
5. Preserve approved branding and content.
6. Avoid unrelated changes.
7. Validate changes before completion.

## No assumptions

Do not invent:

- framework versions;
- credentials;
- URLs;
- database schema;
- routes;
- integrations;
- business requirements.

Infer technical facts from actual project files.

## Security

Never expose or commit:

- .env;
- credentials;
- API keys;
- tokens;
- private keys;
- production secrets.

Do not perform destructive database operations without explicit authorization.

## Git safety

Do not:

- force push;
- use git reset --hard;
- use git clean -fd;
- delete branches;
- overwrite uncommitted work.

Review Git diff before considering work complete.

## Production

Do not deploy to production without explicit authorization.
"@

    Write-Utf8File `
        -Path $agentsFile `
        -Content $agentsContent

    Write-Host "Created: AGENTS.md" `
        -ForegroundColor Green
}
else {

    Write-Host "Preserved existing: AGENTS.md" `
        -ForegroundColor Green
}

if (-not (Test-Path $rulesFolder)) {

    New-Item `
        -ItemType Directory `
        -Path $rulesFolder `
        -Force |
        Out-Null
}

if (-not (Test-Path $proxtelRule)) {

    $ruleContent = @"
# PROXTEL Existing Project Rules

## Scope

These rules apply to this existing project.

## Protection

- Inspect before editing.
- Preserve the confirmed stack.
- Preserve existing functionality.
- Preserve approved branding and content.
- Prefer minimal targeted changes.
- Do not reinitialize the application.
- Do not replace working configuration blindly.
- Do not install dependencies without justification.

## Audit first

When asked to audit, review, inspect, diagnose or analyze:

- default to read-only;
- gather evidence;
- separate verified facts from recommendations;
- do not modify application files unless explicitly authorized.

## Validation

After authorized implementation, validate what applies:

- syntax;
- tests;
- lint;
- build;
- browser behavior;
- Git diff.

Report any validation that could not be executed.
"@

    Write-Utf8File `
        -Path $proxtelRule `
        -Content $ruleContent

    Write-Host "Created: .agents/rules/proxtel-project.md" `
        -ForegroundColor Green
}
else {

    Write-Host "Preserved existing: .agents/rules/proxtel-project.md" `
        -ForegroundColor Green
}

$gitIgnore = Join-Path `
    $ResolvedProject `
    ".gitignore"

if (
    -not $gitRepoRoot -and
    -not (Test-Path $gitIgnore)
) {

    $safeGitIgnore = @"
# Environment
.env
.env.*
!.env.example

# Credentials
*.pem
*.key
*.p12
*.pfx
.npmrc
.pypirc
auth.json
credentials*.json
service-account*.json

# Dependencies
node_modules/
vendor/

# Logs
*.log

# Operating system
.DS_Store
Thumbs.db
Desktop.ini
"@

    Write-Utf8File `
        -Path $gitIgnore `
        -Content $safeGitIgnore

    Write-Host "Created: .gitignore" `
        -ForegroundColor Green
}
elseif (Test-Path $gitIgnore) {

    Write-Host "Preserved existing: .gitignore" `
        -ForegroundColor Green
}

if (-not $gitRepoRoot) {

    git -C $ResolvedProject init

    if ($LASTEXITCODE -ne 0) {

        throw "git init failed."
    }

    Write-Host "Initialized Git repository." `
        -ForegroundColor Green
}
else {

    Write-Host "Preserved existing Git repository." `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Installing project Skills..." `
    -ForegroundColor Cyan

$global:LASTEXITCODE = 0

& $SkillInstaller `
    -ProjectPath $ResolvedProject `
    -Bundle $Bundle `
    -Mode Install

if (
    -not $? -or
    $LASTEXITCODE -ne 0
) {

    throw "Project Skill installation failed."
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " PROJECT PREPARED" `
    -ForegroundColor Green

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "Project : $ResolvedProject"
Write-Host "Bundle  : $Bundle"

Write-Host ""
Write-Host "Application code was not intentionally modified."
Write-Host "No Git staging was performed."
Write-Host "No Git commit was created."
Write-Host "No production action was performed."

Write-Host ""

git -C $ResolvedProject status
