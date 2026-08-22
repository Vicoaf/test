param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[A-Za-z0-9][A-Za-z0-9._-]*$")]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "website",
        "landing-page",
        "laravel",
        "crm",
        "saas"
    )]
    [string]$Type,

    [string]$ParentPath = "C:\DEV\CLIENTES",

    [string]$Description = "",

    [switch]$NoGitCommit
)

$ErrorActionPreference = "Stop"

$AgencyRoot = Split-Path -Parent $PSScriptRoot

$SkillInstaller = Join-Path `
    $AgencyRoot `
    "scripts\install-project-skills.ps1"

$TemplateRoot = Join-Path `
    $AgencyRoot `
    "templates\$Type"

$ProjectPath = Join-Path `
    $ParentPath `
    $Name

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

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " PROXTEL AI AGENCY - NEW PROJECT" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "Name        : $Name"
Write-Host "Type        : $Type"
Write-Host "Parent      : $ParentPath"
Write-Host "Project     : $ProjectPath"

Write-Host ""

if (-not (Test-Path $SkillInstaller)) {

    throw "Missing project skill installer: $SkillInstaller"
}

if (-not (Test-CommandExists "git")) {

    throw "Git is not available in PATH."
}

if (Test-Path $ProjectPath) {

    $existingItems = @(
        Get-ChildItem `
            -Path $ProjectPath `
            -Force `
            -ErrorAction Stop
    )

    if ($existingItems.Count -gt 0) {

        throw "Project path already exists and is not empty: $ProjectPath"
    }
}

if (-not (Test-Path $ParentPath)) {

    New-Item `
        -ItemType Directory `
        -Path $ParentPath `
        -Force |
        Out-Null
}

if (-not (Test-Path $ProjectPath)) {

    New-Item `
        -ItemType Directory `
        -Path $ProjectPath `
        -Force |
        Out-Null
}

Write-Host "Created project directory." `
    -ForegroundColor Green

$AgentsRoot = Join-Path `
    $ProjectPath `
    ".agents"

$RulesRoot = Join-Path `
    $AgentsRoot `
    "rules"

$DocsRoot = Join-Path `
    $ProjectPath `
    "docs"

New-Item `
    -ItemType Directory `
    -Path $RulesRoot `
    -Force |
    Out-Null

New-Item `
    -ItemType Directory `
    -Path $DocsRoot `
    -Force |
    Out-Null

$gitignore = @"
# Environment
.env
.env.*
!.env.example

# Dependencies
node_modules/
vendor/

# Build
dist/
build/
coverage/

# Logs
*.log
storage/logs/*.log

# IDE
.idea/

# Operating system
.DS_Store
Thumbs.db
Desktop.ini

# Credentials
*.pem
*.key
*.p12
*.pfx

# Temporary files
*.tmp
*.temp
*.bak
"@

Write-Utf8File `
    -Path (Join-Path $ProjectPath ".gitignore") `
    -Content $gitignore

$editorConfig = @"
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.php]
indent_style = space
indent_size = 4

[*.blade.php]
indent_style = space
indent_size = 4

[*.{js,css,scss,html,json,yml,yaml}]
indent_style = space
indent_size = 4

[*.md]
trim_trailing_whitespace = false

[*.ps1]
end_of_line = crlf
indent_style = space
indent_size = 4
"@

Write-Utf8File `
    -Path (Join-Path $ProjectPath ".editorconfig") `
    -Content $editorConfig

if ([string]::IsNullOrWhiteSpace($Description)) {

    $descriptionText = "Pending project description."
}
else {

    $descriptionText = $Description
}

$agentsContent = @"
# AGENTS.md

## Project

Name: $Name

Type: $Type

Description:

$descriptionText

## Development environment

Primary environment:

- Windows
- Visual Studio Code
- PROXTEL AI Agency profile

Agent tools may include:

- Codex
- Antigravity

## Project instructions

Before modifying code:

1. Inspect the repository.
2. Inspect the current architecture.
3. Check Git status.
4. Preserve existing functionality.
5. Avoid unrelated changes.
6. Validate changes before reporting completion.

## Stack

The final stack must be inferred from the actual project files.

Do not assume:

- Laravel version;
- PHP version;
- database schema;
- authentication system;
- frontend framework;
- external integrations.

## Commands

Before running project commands, inspect the real project configuration.

Do not invent commands that are not supported by the repository.

## Security

Never expose or commit:

- .env;
- credentials;
- API keys;
- tokens;
- private keys;
- production secrets.

Do not perform destructive database operations without explicit authorization.

## Git

Do not:

- force push;
- use git reset --hard;
- use git clean -fd;
- delete branches;
- overwrite uncommitted work.

Review the diff before considering a task complete.

## Production

Do not deploy to production without explicit authorization.

Recommended flow:

local -> validation -> staging -> production
"@

Write-Utf8File `
    -Path (Join-Path $ProjectPath "AGENTS.md") `
    -Content $agentsContent

$projectRules = @"
# Project Rules

Project: $Name
Type: $Type

These rules are specific to this workspace.

## General

- Preserve the project's confirmed stack.
- Preserve branding and approved content.
- Inspect before modifying.
- Prefer minimal targeted changes.
- Do not invent requirements.
- Do not install dependencies without justification.

## Existing projects

If code already exists:

- inspect before editing;
- preserve architecture where reasonable;
- do not reinitialize the project;
- do not overwrite configuration blindly.

## New projects

Do not select framework versions, authentication systems, database entities or integrations until requirements are confirmed.

## Validation

When implementation occurs, validate what applies:

- syntax;
- tests;
- lint;
- build;
- browser behavior;
- Git diff.

Report validations that could not be executed.
"@

Write-Utf8File `
    -Path (Join-Path $RulesRoot "project.md") `
    -Content $projectRules

$projectDoc = @"
# Project Definition

## Name

$Name

## Type

$Type

## Description

$descriptionText

## Status

Initial workspace created.

## Confirmed requirements

Pending.

## Functional requirements

Pending.

## Technical decisions

Pending.

## Integrations

Pending.

## Data model

Pending.

## Authentication and authorization

Pending.

## Deployment environment

Pending.

## Notes

Do not fill unknown requirements with assumptions.
"@

Write-Utf8File `
    -Path (Join-Path $DocsRoot "PROJECT.md") `
    -Content $projectDoc

$readme = @"
# $Name

Type: $Type

$descriptionText

## Status

Project workspace initialized by PROXTEL AI Agency.

The application stack and functional architecture have not been assumed.

## Documentation

See:

docs/PROJECT.md

## Agent configuration

Project agent context:

AGENTS.md

Project-specific Antigravity rules:

.agents/rules/project.md

Project Skills:

.agents/skills/

## Git

This repository is intended to use local Git version control before development begins.
"@

Write-Utf8File `
    -Path (Join-Path $ProjectPath "README.md") `
    -Content $readme

if (Test-Path $TemplateRoot) {

    $templateFiles = @(
        Get-ChildItem `
            -Path $TemplateRoot `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -ne ".gitkeep"
        }
    )

    foreach ($templateFile in $templateFiles) {

        $relative = `
            $templateFile.FullName.Substring(
                $TemplateRoot.Length
            ).TrimStart("\")

        $destination = `
            Join-Path `
                $ProjectPath `
                $relative

        $destinationDirectory = `
            Split-Path `
                -Parent `
                $destination

        if (
            $destinationDirectory -and
            -not (Test-Path $destinationDirectory)
        ) {

            New-Item `
                -ItemType Directory `
                -Path $destinationDirectory `
                -Force |
                Out-Null
        }

        if (-not (Test-Path $destination)) {

            Copy-Item `
                -Path $templateFile.FullName `
                -Destination $destination
        }
        else {

            throw "Template attempted to overwrite existing file: $destination"
        }
    }
}

Write-Host "Installing project Skills..." `
    -ForegroundColor Cyan

$global:LASTEXITCODE = 0

& $SkillInstaller `
    -ProjectPath $ProjectPath `
    -Bundle $Type `
    -Mode Install

if (
    -not $? -or
    $LASTEXITCODE -ne 0
) {

    throw "Project Skill installation failed."
}

git -C $ProjectPath init

if ($LASTEXITCODE -ne 0) {

    throw "git init failed."
}

git -C $ProjectPath add .

if ($LASTEXITCODE -ne 0) {

    throw "git add failed."
}

if (-not $NoGitCommit) {

    $gitName = git -C $ProjectPath config user.name
    $gitEmail = git -C $ProjectPath config user.email

    if (
        [string]::IsNullOrWhiteSpace($gitName) -or
        [string]::IsNullOrWhiteSpace($gitEmail)
    ) {

        Write-Host ""
        Write-Host "WARNING: Git user.name or user.email is not configured." `
            -ForegroundColor Yellow

        Write-Host "Initial commit was not created." `
            -ForegroundColor Yellow
    }
    else {

        git -C $ProjectPath commit `
            -m "Initialize $Name workspace"

        if ($LASTEXITCODE -ne 0) {

            throw "Initial Git commit failed."
        }
    }
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " PROJECT CREATED" `
    -ForegroundColor Green

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "Project : $ProjectPath"
Write-Host "Type    : $Type"

Write-Host ""

Write-Host "Created:" `
    -ForegroundColor Yellow

Write-Host " - README.md"
Write-Host " - AGENTS.md"
Write-Host " - .gitignore"
Write-Host " - .editorconfig"
Write-Host " - docs/PROJECT.md"
Write-Host " - .agents/rules/project.md"
Write-Host " - .agents/skills/"
Write-Host " - Git repository"

Write-Host ""

Write-Host "No framework version or application dependencies were assumed." `
    -ForegroundColor Green

Write-Host ""

git -C $ProjectPath status
