param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet(
        "website",
        "landing-page",
        "laravel",
        "crm",
        "saas"
    )]
    [string]$Bundle,

    [string[]]$Skills,

    [ValidateSet(
        "List",
        "Check",
        "Install"
    )]
    [string]$Mode = "Check"
)

$ErrorActionPreference = "Stop"

$AgencyRoot = Split-Path -Parent $PSScriptRoot

$SourceRoot = Join-Path `
    $AgencyRoot `
    "skills\base"

$BundleFile = Join-Path `
    $AgencyRoot `
    "config\skill-bundles.json"

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Get-FolderFingerprint {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    $files = Get-ChildItem `
        -Path $Path `
        -File `
        -Recurse `
        -ErrorAction Stop |
        Sort-Object FullName

    if (-not $files) {
        return $null
    }

    $manifest = foreach ($file in $files) {

        $relativePath = `
            $file.FullName.Substring($Path.Length).TrimStart("\")

        $hash = `
            (Get-FileHash `
                $file.FullName `
                -Algorithm SHA256
            ).Hash

        "$relativePath|$hash"
    }

    $text = $manifest -join "`n"

    $bytes = `
        [System.Text.Encoding]::UTF8.GetBytes($text)

    $sha = `
        [System.Security.Cryptography.SHA256]::Create()

    try {

        return (
            [System.BitConverter]::ToString(
                $sha.ComputeHash($bytes)
            )
        ).Replace("-", "")
    }
    finally {

        $sha.Dispose()
    }
}

function Test-Skill {

    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillFolder
    )

    $skillFile = `
        Join-Path $SkillFolder "SKILL.md"

    if (-not (Test-Path $skillFile)) {

        throw "Falta SKILL.md en: $SkillFolder"
    }

    $content = `
        Get-Content `
            $skillFile `
            -Raw `
            -Encoding UTF8

    if (-not $content.StartsWith("---")) {

        throw "Frontmatter YAML inexistente o invalido en: $skillFile"
    }

    if ($content -notmatch "(?m)^name:\s*\S+") {

        throw "Falta 'name:' en: $skillFile"
    }

    if ($content -notmatch "(?m)^description:\s*.+") {

        throw "Falta 'description:' en: $skillFile"
    }

    return $true
}

function Get-AvailableSkills {

    return Get-ChildItem `
        -Path $SourceRoot `
        -Directory |
        Sort-Object Name
}

function Get-Bundles {

    if (-not (Test-Path $BundleFile)) {

        throw "No existe el archivo de bundles: $BundleFile"
    }

    return Get-Content `
        $BundleFile `
        -Raw `
        -Encoding UTF8 |
        ConvertFrom-Json
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " PROXTEL AI AGENCY - PROJECT SKILL INSTALLER" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

if (-not (Test-Path $SourceRoot)) {

    throw "No existe la biblioteca maestra: $SourceRoot"
}

$availableSkills = Get-AvailableSkills
$bundles = Get-Bundles

if ($Mode -eq "List") {

    Write-Host "SKILLS DISPONIBLES" `
        -ForegroundColor Yellow

    Write-Host ""

    foreach ($skill in $availableSkills) {

        Write-Host " - $($skill.Name)"
    }

    Write-Host ""
    Write-Host "BUNDLES DISPONIBLES" `
        -ForegroundColor Yellow

    Write-Host ""

    foreach ($property in $bundles.PSObject.Properties) {

        Write-Host "$($property.Name):" `
            -ForegroundColor Cyan

        foreach ($skill in $property.Value) {

            Write-Host "   - $skill"
        }
    }

    Write-Host ""

    exit 0
}

if (-not (Test-Path $ProjectPath)) {

    throw "El proyecto no existe: $ProjectPath"
}

$resolvedProject = `
    (Resolve-Path $ProjectPath).Path

$TargetRoot = `
    Join-Path `
        $resolvedProject `
        ".agents\skills"

$projectName = `
    Split-Path `
        $resolvedProject `
        -Leaf

$BackupRoot = `
    Join-Path `
        $env:USERPROFILE `
        ".gemini\proxtel-project-skill-backups\$projectName\$Timestamp"

$selectedSkills = @()

if ($Skills -and $Skills.Count -gt 0) {

    $selectedSkills = $Skills
}
elseif ($Bundle) {

    $bundleProperty = `
        $bundles.PSObject.Properties |
        Where-Object {
            $_.Name -eq $Bundle
        }

    if (-not $bundleProperty) {

        throw "Bundle no encontrado: $Bundle"
    }

    $selectedSkills = @(
        $bundleProperty.Value
    )
}
else {

    throw "Debes indicar -Bundle o -Skills."
}

$selectedSkills = `
    $selectedSkills |
    Sort-Object `
    -Unique

Write-Host "Modo     : $Mode"
Write-Host "Proyecto : $resolvedProject"

if ($Bundle) {
    Write-Host "Bundle   : $Bundle"
}

Write-Host "Destino  : $TargetRoot"

Write-Host ""
Write-Host "Skills seleccionadas:" `
    -ForegroundColor Yellow

foreach ($skill in $selectedSkills) {

    Write-Host " - $skill"
}

Write-Host ""

$errors = 0
$synchronized = 0
$missing = 0
$different = 0
$installed = 0

foreach ($skillName in $selectedSkills) {

    Write-Host "------------------------------------------------------------"
    Write-Host "SKILL: $skillName" `
        -ForegroundColor Yellow

    try {

        $sourceFolder = `
            Join-Path `
                $SourceRoot `
                $skillName

        if (-not (Test-Path $sourceFolder)) {

            throw "La Skill no existe en la biblioteca maestra."
        }

        Test-Skill `
            -SkillFolder $sourceFolder |
            Out-Null

        $targetFolder = `
            Join-Path `
                $TargetRoot `
                $skillName

        $sourceFingerprint = `
            Get-FolderFingerprint `
                -Path $sourceFolder

        $targetFingerprint = `
            Get-FolderFingerprint `
                -Path $targetFolder

        if (
            $targetFingerprint -and
            $sourceFingerprint -eq $targetFingerprint
        ) {

            Write-Host "ESTADO: SINCRONIZADA" `
                -ForegroundColor Green

            $synchronized++

            continue
        }

        if (-not (Test-Path $targetFolder)) {

            Write-Host "ESTADO: NO INSTALADA" `
                -ForegroundColor Yellow

            $missing++
        }
        else {

            Write-Host "ESTADO: DIFERENTE A LA FUENTE MAESTRA" `
                -ForegroundColor Yellow

            $different++
        }

        if ($Mode -eq "Check") {

            continue
        }

        if (-not (Test-Path $TargetRoot)) {

            New-Item `
                -ItemType Directory `
                -Path $TargetRoot `
                -Force |
                Out-Null
        }

        if (Test-Path $targetFolder) {

            $skillBackup = `
                Join-Path `
                    $BackupRoot `
                    $skillName

            New-Item `
                -ItemType Directory `
                -Path $skillBackup `
                -Force |
                Out-Null

            Copy-Item `
                -Path "$targetFolder\*" `
                -Destination $skillBackup `
                -Recurse `
                -Force

            Write-Host "Backup: $skillBackup" `
                -ForegroundColor DarkGray

            Remove-Item `
                -Path $targetFolder `
                -Recurse `
                -Force
        }

        Copy-Item `
            -Path $sourceFolder `
            -Destination $TargetRoot `
            -Recurse `
            -Force

        $installedFingerprint = `
            Get-FolderFingerprint `
                -Path $targetFolder

        if (
            $installedFingerprint -ne
            $sourceFingerprint
        ) {

            throw "Fallo la validacion posterior a la instalacion."
        }

        Write-Host "RESULTADO: INSTALADA CORRECTAMENTE" `
            -ForegroundColor Green

        $installed++
    }
    catch {

        $errors++

        Write-Host "ERROR: $($_.Exception.Message)" `
            -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " RESUMEN" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "Seleccionadas       : $($selectedSkills.Count)"
Write-Host "Sincronizadas       : $synchronized"
Write-Host "No instaladas       : $missing"
Write-Host "Diferentes          : $different"
Write-Host "Instaladas ahora    : $installed"
Write-Host "Errores              : $errors"

Write-Host ""

if ($Mode -eq "Check") {

    Write-Host "No se modifico ningun archivo." `
        -ForegroundColor Green

    if (
        $missing -gt 0 -or
        $different -gt 0
    ) {

        Write-Host ""

        Write-Host "Para instalar:" `
            -ForegroundColor Yellow

        if ($Bundle) {

            Write-Host `
".\scripts\install-project-skills.ps1 -ProjectPath `"$resolvedProject`" -Bundle $Bundle -Mode Install"
        }
        else {

            $skillsText = `
                ($selectedSkills -join '","')

            Write-Host `
".\scripts\install-project-skills.ps1 -ProjectPath `"$resolvedProject`" -Skills `"$skillsText`" -Mode Install"
        }
    }
}

if ($Mode -eq "Install") {

    if ($errors -eq 0) {

        Write-Host "Instalacion terminada correctamente." `
            -ForegroundColor Green
    }
    else {

        Write-Host "La instalacion termino con errores." `
            -ForegroundColor Red

        exit 1
    }
}
