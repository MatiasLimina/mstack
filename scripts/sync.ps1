<#
.SYNOPSIS
Sincroniza las skills y el CLAUDE.md global de mstack hacia ~/.claude/.

.DESCRIPTION
Copia cada skill de skills/ a <TargetRoot>\skills\<nombre> (reemplazando la
carpeta de forma limpia sin tocar skills de terceros) y actualiza
<TargetRoot>\CLAUDE.md desde config\CLAUDE.md haciendo backup previo en
CLAUDE.md.bak cuando hay cambios.

.PARAMETER TargetRoot
Carpeta destino de Claude Code. Por defecto: "$env:USERPROFILE\.claude".

.PARAMETER DryRun
Muestra qué cambiaría sin modificar ningún archivo.

.PARAMETER SkipClaudeMd
Sincroniza únicamente las skills y deja intacto el CLAUDE.md global.
#>
[CmdletBinding()]
param(
    [string]$TargetRoot = (Join-Path $env:USERPROFILE ".claude"),
    [switch]$DryRun,
    [switch]$SkipClaudeMd
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SourceSkillsDir = Join-Path $RepoRoot "skills"
$SourceClaudeMd = Join-Path (Join-Path $RepoRoot "config") "CLAUDE.md"
$TargetSkillsDir = Join-Path $TargetRoot "skills"
$TargetClaudeMd = Join-Path $TargetRoot "CLAUDE.md"
$TargetClaudeBackup = Join-Path $TargetRoot "CLAUDE.md.bak"

if (-not (Test-Path -LiteralPath $SourceSkillsDir -PathType Container)) {
    throw "No se encontró la carpeta de skills en: $SourceSkillsDir"
}

if (-not $SkipClaudeMd -and -not (Test-Path -LiteralPath $SourceClaudeMd -PathType Leaf)) {
    throw "No se encontró config\CLAUDE.md en: $SourceClaudeMd"
}

function Get-DirectoryManifest {
    param([Parameter(Mandatory)][string]$RootPath)

    $resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path.TrimEnd('\', '/')
    $files = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Force)
    $manifest = @{}

    foreach ($file in $files) {
        $rel = $file.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/') -replace '\\', '/'
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        $manifest[$rel] = $hash
    }

    return $manifest
}

function Test-DirectoryEqual {
    param(
        [Parameter(Mandatory)][string]$SourceDir,
        [Parameter(Mandatory)][string]$DestDir
    )

    if (-not (Test-Path -LiteralPath $DestDir -PathType Container)) {
        return $false
    }

    $srcManifest = Get-DirectoryManifest -RootPath $SourceDir
    $dstManifest = Get-DirectoryManifest -RootPath $DestDir

    if ($srcManifest.Count -ne $dstManifest.Count) {
        return $false
    }

    foreach ($key in $srcManifest.Keys) {
        if (-not $dstManifest.ContainsKey($key)) {
            return $false
        }
        if ($srcManifest[$key] -ne $dstManifest[$key]) {
            return $false
        }
    }

    return $true
}

function Copy-SkillDirectory {
    param(
        [Parameter(Mandatory)][string]$SourceDir,
        [Parameter(Mandatory)][string]$DestDir
    )

    $parentDir = Split-Path -Parent $DestDir
    $leafName = Split-Path -Leaf $DestDir
    $stagingDir = Join-Path $parentDir ".mstack-sync-tmp-$leafName-$PID"

    if (Test-Path -LiteralPath $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force
    }

    try {
        Copy-Item -LiteralPath $SourceDir -Destination $stagingDir -Recurse -Force
        if (Test-Path -LiteralPath $DestDir) {
            Remove-Item -LiteralPath $DestDir -Recurse -Force
        }
        Move-Item -LiteralPath $stagingDir -Destination $DestDir
    }
    finally {
        if (Test-Path -LiteralPath $stagingDir) {
            Remove-Item -LiteralPath $stagingDir -Recurse -Force
        }
    }
}

$counts = @{
    Added     = 0
    Updated   = 0
    Unchanged = 0
    Skipped   = 0
}

if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $TargetRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $TargetSkillsDir -PathType Container)) {
        New-Item -ItemType Directory -Path $TargetSkillsDir -Force | Out-Null
    }
}

$skillDirs = @(Get-ChildItem -LiteralPath $SourceSkillsDir -Directory | Sort-Object Name)

foreach ($skill in $skillDirs) {
    $destSkillDir = Join-Path $TargetSkillsDir $skill.Name

    if (-not (Test-Path -LiteralPath $destSkillDir -PathType Container)) {
        if (-not $DryRun) {
            Copy-SkillDirectory -SourceDir $skill.FullName -DestDir $destSkillDir
        }
        $counts.Added++
        Write-Output ("ADDED     skill/{0}" -f $skill.Name)
    }
    elseif (Test-DirectoryEqual -SourceDir $skill.FullName -DestDir $destSkillDir) {
        $counts.Unchanged++
        Write-Output ("UNCHANGED skill/{0}" -f $skill.Name)
    }
    else {
        if (-not $DryRun) {
            Copy-SkillDirectory -SourceDir $skill.FullName -DestDir $destSkillDir
        }
        $counts.Updated++
        Write-Output ("UPDATED   skill/{0}" -f $skill.Name)
    }
}

if ($SkipClaudeMd) {
    $counts.Skipped++
    Write-Output "SKIPPED   CLAUDE.md"
}
elseif (-not (Test-Path -LiteralPath $TargetClaudeMd -PathType Leaf)) {
    if (-not $DryRun) {
        Copy-Item -LiteralPath $SourceClaudeMd -Destination $TargetClaudeMd -Force
    }
    $counts.Added++
    Write-Output "ADDED     CLAUDE.md"
}
else {
    $srcHash = (Get-FileHash -LiteralPath $SourceClaudeMd -Algorithm SHA256).Hash
    $dstHash = (Get-FileHash -LiteralPath $TargetClaudeMd -Algorithm SHA256).Hash

    if ($srcHash -eq $dstHash) {
        $counts.Unchanged++
        Write-Output "UNCHANGED CLAUDE.md"
    }
    else {
        if (-not $DryRun) {
            Copy-Item -LiteralPath $TargetClaudeMd -Destination $TargetClaudeBackup -Force
            Copy-Item -LiteralPath $SourceClaudeMd -Destination $TargetClaudeMd -Force
        }
        $counts.Updated++
        Write-Output "UPDATED   CLAUDE.md (backup: CLAUDE.md.bak)"
    }
}

Write-Output ""
Write-Output ("Resumen: {0} agregados, {1} actualizados, {2} sin cambios, {3} omitidos -> {4}" -f `
    $counts.Added, $counts.Updated, $counts.Unchanged, $counts.Skipped, $TargetRoot)

if ($DryRun) {
    Write-Output "[DRY RUN] No se modificó ningún archivo."
}
