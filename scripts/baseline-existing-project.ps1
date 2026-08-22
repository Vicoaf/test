param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet(
        "Check",
        "Create"
    )]
    [string]$Mode = "Check",

    [string]$CommitMessage = "Establish existing project baseline"
)

$ErrorActionPreference = "Stop"

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

function Invoke-GitQuery {

    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    $output = @(
        & git @Arguments 2>$null
    )

    $exitCode = $LASTEXITCODE

    $ErrorActionPreference = $previousErrorActionPreference

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " PROXTEL AI AGENCY - EXISTING PROJECT BASELINE" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

if (-not (Test-CommandExists "git")) {

    throw "Git is not available in PATH."
}

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

Write-Host "Mode       : $Mode"
Write-Host "Project    : $ResolvedProject"
Write-Host ""

$gitRootResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "rev-parse",
        "--show-toplevel"
    )

if (
    $gitRootResult.ExitCode -ne 0 -or
    $gitRootResult.Output.Count -eq 0
) {

    throw "Project is not a Git repository. Run prepare-existing-project.ps1 first."
}

$gitRoot = $gitRootResult.Output[0]

$normalizedProject = Get-NormalizedPath `
    -Path $ResolvedProject

$normalizedGitRoot = Get-NormalizedPath `
    -Path $gitRoot

if ($normalizedProject -ine $normalizedGitRoot) {

    throw "Project is inside another Git repository. Baseline stopped to protect the parent repository."
}

Write-Host "Git repository : YES" `
    -ForegroundColor Green

Write-Host "Git root       : $gitRoot"
Write-Host "Project root   : MATCH" `
    -ForegroundColor Green

$headResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "rev-parse",
        "--verify",
        "HEAD"
    )

$hasCommit = (
    $headResult.ExitCode -eq 0
)

Write-Host "Has commit     : $hasCommit"

$branchResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "branch",
        "--show-current"
    )

$branch = ""

if (
    $branchResult.ExitCode -eq 0 -and
    $branchResult.Output.Count -gt 0
) {

    $branch = $branchResult.Output[0]
}

if ([string]::IsNullOrWhiteSpace($branch)) {

    Write-Host "Branch         : DETACHED OR UNRESOLVED"
}
else {

    Write-Host "Branch         : $branch"
}

$statusResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "status",
        "--porcelain"
    )

if ($statusResult.ExitCode -ne 0) {

    throw "Unable to read Git working tree status."
}

$statusLines = @(
    $statusResult.Output
)

if ($statusLines.Count -eq 0) {

    Write-Host "Working tree   : CLEAN" `
        -ForegroundColor Green
}
else {

    Write-Host "Working tree   : DIRTY" `
        -ForegroundColor Yellow

    Write-Host "Pending entries: $($statusLines.Count)"
}

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " INDEX SAFETY" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$stagedResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "diff",
        "--cached",
        "--name-only"
    )

if ($stagedResult.ExitCode -ne 0) {

    throw "Unable to inspect Git index."
}

$stagedFiles = @(
    $stagedResult.Output |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }
)

Write-Host "Previously staged files: $($stagedFiles.Count)"

if ($stagedFiles.Count -gt 0) {

    foreach ($stagedFile in $stagedFiles) {

        Write-Host " - $stagedFile" `
            -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " SENSITIVE FILE SAFETY" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$trackedResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "ls-files"
    )

if ($trackedResult.ExitCode -ne 0) {

    throw "Unable to inspect tracked Git files."
}

$trackedSensitive = @()

foreach ($trackedFile in $trackedResult.Output) {

    if (
        Test-SensitiveCandidate `
            -RelativePath $trackedFile
    ) {

        $trackedSensitive += $trackedFile
    }
}

$untrackedResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "ls-files",
        "--others",
        "--exclude-standard"
    )

if ($untrackedResult.ExitCode -ne 0) {

    throw "Unable to inspect untracked files."
}

$untrackedSensitive = @()

foreach ($untrackedFile in $untrackedResult.Output) {

    if (
        Test-SensitiveCandidate `
            -RelativePath $untrackedFile
    ) {

        $untrackedSensitive += $untrackedFile
    }
}

Write-Host "Tracked sensitive candidates  : $($trackedSensitive.Count)"
Write-Host "Untracked sensitive candidates: $($untrackedSensitive.Count)"

if ($trackedSensitive.Count -gt 0) {

    Write-Host ""
    Write-Host "Tracked sensitive candidates:" `
        -ForegroundColor Red

    foreach ($item in $trackedSensitive) {

        Write-Host " - $item" `
            -ForegroundColor Red
    }
}

if ($untrackedSensitive.Count -gt 0) {

    Write-Host ""
    Write-Host "Untracked sensitive candidates not ignored by Git:" `
        -ForegroundColor Red

    foreach ($item in $untrackedSensitive) {

        Write-Host " - $item" `
            -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " BASELINE DECISION" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$baselineAllowed = $true
$baselineReason = "READY"

if ($hasCommit) {

    $baselineAllowed = $false
    $baselineReason = "EXISTING_HISTORY"
}
elseif ($stagedFiles.Count -gt 0) {

    $baselineAllowed = $false
    $baselineReason = "PREEXISTING_STAGED_FILES"
}
elseif ($trackedSensitive.Count -gt 0) {

    $baselineAllowed = $false
    $baselineReason = "TRACKED_SENSITIVE_FILES"
}
elseif ($untrackedSensitive.Count -gt 0) {

    $baselineAllowed = $false
    $baselineReason = "UNIGNORED_SENSITIVE_FILES"
}

Write-Host "Baseline allowed: $baselineAllowed"
Write-Host "Decision        : $baselineReason"

if ($Mode -eq "Check") {

    Write-Host ""
    Write-Host "============================================================" `
        -ForegroundColor Cyan

    Write-Host " CHECK COMPLETE" `
        -ForegroundColor Green

    Write-Host "============================================================" `
        -ForegroundColor Cyan

    Write-Host ""
    Write-Host "No Git staging was performed."
    Write-Host "No Git commit was created."
    Write-Host "No project files were modified."

    exit 0
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " CREATE VALIDATION" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

if (-not $baselineAllowed) {

    if ($baselineReason -eq "EXISTING_HISTORY") {

        throw "Project already has Git history. No new baseline should be created."
    }

    if ($baselineReason -eq "PREEXISTING_STAGED_FILES") {

        throw "Git index already contains staged files. Baseline stopped to avoid altering existing staging."
    }

    if ($baselineReason -eq "TRACKED_SENSITIVE_FILES") {

        throw "Sensitive candidate files are already tracked by Git. Manual review is required."
    }

    if ($baselineReason -eq "UNIGNORED_SENSITIVE_FILES") {

        throw "Sensitive candidate files are untracked and not ignored. Fix .gitignore before creating a baseline."
    }

    throw "Baseline safety validation failed."
}

$gitNameResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "config",
        "user.name"
    )

$gitEmailResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "config",
        "user.email"
    )

$gitName = ""

if (
    $gitNameResult.ExitCode -eq 0 -and
    $gitNameResult.Output.Count -gt 0
) {

    $gitName = $gitNameResult.Output[0]
}

$gitEmail = ""

if (
    $gitEmailResult.ExitCode -eq 0 -and
    $gitEmailResult.Output.Count -gt 0
) {

    $gitEmail = $gitEmailResult.Output[0]
}

if (
    [string]::IsNullOrWhiteSpace($gitName) -or
    [string]::IsNullOrWhiteSpace($gitEmail)
) {

    throw "Git user.name or user.email is not configured."
}

Write-Host "Git identity validation passed." `
    -ForegroundColor Green

Write-Host "Staging project baseline..." `
    -ForegroundColor Cyan

git -C $ResolvedProject add --all

if ($LASTEXITCODE -ne 0) {

    throw "git add --all failed."
}

$stagedAfterResult = Invoke-GitQuery `
    -Arguments @(
        "-C",
        $ResolvedProject,
        "diff",
        "--cached",
        "--name-only"
    )

if ($stagedAfterResult.ExitCode -ne 0) {

    throw "Unable to validate staged baseline."
}

$stagedAfter = @(
    $stagedAfterResult.Output |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }
)

if ($stagedAfter.Count -eq 0) {

    throw "No files were staged. Baseline commit was not created."
}

$stagedSensitiveAfter = @()

foreach ($stagedFile in $stagedAfter) {

    if (
        Test-SensitiveCandidate `
            -RelativePath $stagedFile
    ) {

        $stagedSensitiveAfter += $stagedFile
    }
}

if ($stagedSensitiveAfter.Count -gt 0) {

    Write-Host ""
    Write-Host "SECURITY STOP: sensitive files reached the Git index." `
        -ForegroundColor Red

    foreach ($item in $stagedSensitiveAfter) {

        Write-Host " - $item" `
            -ForegroundColor Red
    }

    throw "Sensitive files were staged. Commit was blocked. Manual index review is required."
}

Write-Host "Staged sensitive candidates: 0" `
    -ForegroundColor Green

git -C $ResolvedProject commit `
    -m $CommitMessage

if ($LASTEXITCODE -ne 0) {

    throw "Baseline Git commit failed."
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " BASELINE CREATED" `
    -ForegroundColor Green

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

git -C $ResolvedProject log --oneline -1
git -C $ResolvedProject status
