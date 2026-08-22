param(
    [ValidateSet("Check", "Install")]
    [string]$Mode = "Check"
)

$ErrorActionPreference = "Stop"

$AgencyRoot = Split-Path -Parent $PSScriptRoot
$SourceRoot = Join-Path $AgencyRoot "skills\base"
$TargetRoot = Join-Path $env:USERPROFILE ".gemini\config\skills"

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $env:USERPROFILE ".gemini\proxtel-skill-backups\$Timestamp"

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
        $relativePath = $file.FullName.Substring($Path.Length).TrimStart("\")
        $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash

        "$relativePath|$hash"
    }

    $text = $manifest -join "`n"

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)

    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        return ([System.BitConverter]::ToString(
            $sha.ComputeHash($bytes)
        )).Replace("-", "")
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

    $skillFile = Join-Path $SkillFolder "SKILL.md"

    if (-not (Test-Path $skillFile)) {
        throw "Falta SKILL.md en: $SkillFolder"
    }

    $content = Get-Content $skillFile -Raw -Encoding UTF8

    if (-not $content.StartsWith("---")) {
        throw "Frontmatter YAML inexistente o invalido en: $skillFile"
    }

    if ($content -notmatch "(?m)^name:\s*\S+") {
        throw "Falta 'name:' en el frontmatter de: $skillFile"
    }

    if ($content -notmatch "(?m)^description:\s*.+") {
        throw "Falta 'description:' en el frontmatter de: $skillFile"
    }

    return $true
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " PROXTEL AI AGENCY - SKILL SYNCHRONIZER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Modo   : $Mode"
Write-Host "Origen : $SourceRoot"
Write-Host "Destino: $TargetRoot"
Write-Host ""

if (-not (Test-Path $SourceRoot)) {
    throw "No existe la biblioteca maestra: $SourceRoot"
}

New-Item `
    -ItemType Directory `
    -Path $TargetRoot `
    -Force | Out-Null

$skills = Get-ChildItem `
    -Path $SourceRoot `
    -Directory |
    Sort-Object Name

if (-not $skills) {
    throw "No se encontraron Skills en: $SourceRoot"
}

$errors = 0
$changes = 0
$ok = 0

foreach ($skill in $skills) {

    Write-Host "------------------------------------------------------------"
    Write-Host "SKILL: $($skill.Name)" -ForegroundColor Yellow

    try {

        Test-Skill -SkillFolder $skill.FullName | Out-Null

        $sourceFingerprint = Get-FolderFingerprint -Path $skill.FullName

        $targetFolder = Join-Path $TargetRoot $skill.Name
        $targetFingerprint = Get-FolderFingerprint -Path $targetFolder

        if (
            $targetFingerprint -and
            $sourceFingerprint -eq $targetFingerprint
        ) {
            Write-Host "ESTADO: SINCRONIZADA" -ForegroundColor Green
            $ok++
            continue
        }

        Write-Host "ESTADO: REQUIERE SINCRONIZACION" -ForegroundColor Yellow
        $changes++

        if ($Mode -eq "Check") {
            continue
        }

        if (Test-Path $targetFolder) {

            $skillBackup = Join-Path $BackupRoot $skill.Name

            New-Item `
                -ItemType Directory `
                -Path $skillBackup `
                -Force | Out-Null

            Copy-Item `
                -Path "$targetFolder\*" `
                -Destination $skillBackup `
                -Recurse `
                -Force

            Write-Host "Backup: $skillBackup" -ForegroundColor DarkGray

            Remove-Item `
                -Path $targetFolder `
                -Recurse `
                -Force
        }

        Copy-Item `
            -Path $skill.FullName `
            -Destination $TargetRoot `
            -Recurse `
            -Force

        $installedFingerprint = Get-FolderFingerprint -Path $targetFolder

        if ($installedFingerprint -ne $sourceFingerprint) {
            throw "La validacion posterior a la copia fallo."
        }

        Write-Host "RESULTADO: INSTALADA CORRECTAMENTE" -ForegroundColor Green
    }
    catch {

        $errors++

        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " RESUMEN" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Skills encontradas : $($skills.Count)"
Write-Host "Ya sincronizadas   : $ok"
Write-Host "Requieren cambios  : $changes"
Write-Host "Errores             : $errors"

Write-Host ""

if ($Mode -eq "Check") {

    if ($changes -gt 0) {
        Write-Host "No se modifico ningun archivo." -ForegroundColor Green
        Write-Host ""
        Write-Host "Para instalar:" -ForegroundColor Yellow
        Write-Host ".\scripts\sync-skills.ps1 -Mode Install"
    }
    else {
        Write-Host "Todas las Skills estan sincronizadas." -ForegroundColor Green
    }
}

if ($Mode -eq "Install") {

    if ($errors -eq 0) {
        Write-Host "Sincronizacion terminada correctamente." -ForegroundColor Green
    }
    else {
        Write-Host "La sincronizacion termino con errores." -ForegroundColor Red
        exit 1
    }
}
