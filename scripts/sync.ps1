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

.PARAMETER AntigravitySkillsJson
skills.json de Antigravity (donde corre Gemini Neon). Sus entradas del plugin
mattpocock-skills llevan la versión en la ruta y Claude Code borra la versión
vieja al actualizar el plugin: el script las reapunta a la versión instalada más
nueva (backup en skills.json.bak) y avisa de toda entrada cuya ruta no exista.
Por defecto: "$env:USERPROFILE\.gemini\config\skills.json". Si no existe, se omite.

.PARAMETER SkipAntigravity
No toca el skills.json de Antigravity.
#>
[CmdletBinding()]
param(
    [string]$TargetRoot = (Join-Path $env:USERPROFILE ".claude"),
    [switch]$DryRun,
    [switch]$SkipClaudeMd,
    [string]$AntigravitySkillsJson = (Join-Path $env:USERPROFILE ".gemini\config\skills.json"),
    [switch]$SkipAntigravity
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

function Get-LatestPluginVersionDir {
    param([Parameter(Mandatory)][string]$PluginCacheDir)

    if (-not (Test-Path -LiteralPath $PluginCacheDir -PathType Container)) {
        return $null
    }

    $latest = Get-ChildItem -LiteralPath $PluginCacheDir -Directory |
        Where-Object { $_.Name -match '^\d+(\.\d+){1,3}$' } |
        Sort-Object { [version]$_.Name } -Descending |
        Select-Object -First 1

    return $latest
}

function Sync-AntigravitySkillsJson {
    # Reapunta las entradas del plugin de Matt en el skills.json de Antigravity a la
    # versión instalada más nueva. Nunca agrega ni borra entradas, y ante un archivo
    # inesperado avisa y sigue: el resto del sync ya corrió y no debe abortar.
    param(
        [Parameter(Mandatory)][string]$SkillsJsonPath,
        [Parameter(Mandatory)][string]$PluginCacheDir,
        [Parameter(Mandatory)][hashtable]$Counts,
        [switch]$DryRun
    )

    # Los métodos .NET resuelven rutas relativas contra otro directorio que PowerShell.
    $SkillsJsonPath = (Resolve-Path -LiteralPath $SkillsJsonPath).ProviderPath
    $pluginPathPattern = '(?i)/plugins/cache/mattpocock/mattpocock-skills/[^/]+/skills/([^/]+)/?$'

    try {
        $config = [System.IO.File]::ReadAllText($SkillsJsonPath) | ConvertFrom-Json
    }
    catch {
        $config = $null
    }
    $entriesProperty = if ($null -ne $config) { $config.PSObject.Properties['entries'] } else { $null }
    if ($null -eq $entriesProperty) {
        $Counts.Skipped++
        $Counts.Warnings++
        Write-Output "WARN      antigravity: skills.json no es un JSON con 'entries'; no se tocó ($SkillsJsonPath)"
        return
    }

    # Solo las entradas con un path de texto no vacío; el resto se avisa y se deja como está.
    $pathEntries = @()
    foreach ($entry in @($entriesProperty.Value)) {
        $pathProperty = if ($entry -is [psobject]) { $entry.PSObject.Properties['path'] } else { $null }
        if ($null -eq $pathProperty -or [string]::IsNullOrWhiteSpace([string]$pathProperty.Value)) {
            $Counts.Warnings++
            Write-Output "WARN      antigravity: entrada sin 'path' en skills.json; se deja como está"
            continue
        }
        $pathEntries += $entry
    }
    $pathsOnDisk = @($pathEntries | ForEach-Object { [string]$_.path })

    $latestDir = Get-LatestPluginVersionDir -PluginCacheDir $PluginCacheDir
    $changed = $false

    if ($null -eq $latestDir) {
        $Counts.Skipped++
        $Counts.Warnings++
        Write-Output "WARN      antigravity: el plugin mattpocock-skills no está instalado en $PluginCacheDir"
    }
    else {
        $latestDirFwd = $latestDir.FullName -replace '\\', '/'
        $pluginEntryCount = 0

        foreach ($entry in $pathEntries) {
            $pluginMatch = [regex]::Match([string]$entry.path, $pluginPathPattern)
            if (-not $pluginMatch.Success) { continue }
            $pluginEntryCount++
            $newPath = "$latestDirFwd/skills/$($pluginMatch.Groups[1].Value)"
            if ($entry.path -ne $newPath) {
                $entry.path = $newPath
                $changed = $true
            }
        }

        if ($pluginEntryCount -eq 0) {
            $Counts.Warnings++
            Write-Output "WARN      antigravity: skills.json no tiene entradas del plugin mattpocock-skills; agregalas a mano si Neon las necesita"
        }

        if ($changed) {
            if (-not $DryRun) {
                Copy-Item -LiteralPath $SkillsJsonPath -Destination "$SkillsJsonPath.bak" -Force
                $json = $config | ConvertTo-Json -Depth 10
                [System.IO.File]::WriteAllText($SkillsJsonPath, $json, (New-Object System.Text.UTF8Encoding $false))
            }
            $Counts.Updated++
            Write-Output ("UPDATED   antigravity/skills.json -> mattpocock-skills {0} (backup: skills.json.bak)" -f $latestDir.Name)
        }
        else {
            $Counts.Unchanged++
            Write-Output "UNCHANGED antigravity/skills.json"
        }
    }

    # En DryRun no se escribió nada: el aviso describe las rutas tal como están hoy.
    $pathsToCheck = if ($DryRun) { $pathsOnDisk } else { @($pathEntries | ForEach-Object { [string]$_.path }) }
    foreach ($path in $pathsToCheck) {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            $Counts.Warnings++
            Write-Output ("WARN      antigravity: la ruta no existe: {0}" -f $path)
        }
    }
}

$counts = @{
    Added     = 0
    Updated   = 0
    Unchanged = 0
    Skipped   = 0
    Warnings  = 0
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

if ($SkipAntigravity) {
    $counts.Skipped++
    Write-Output "SKIPPED   antigravity/skills.json"
}
elseif (-not (Test-Path -LiteralPath $AntigravitySkillsJson -PathType Leaf)) {
    $counts.Skipped++
    Write-Output "SKIPPED   antigravity/skills.json (no existe: $AntigravitySkillsJson)"
}
else {
    Sync-AntigravitySkillsJson `
        -SkillsJsonPath $AntigravitySkillsJson `
        -PluginCacheDir (Join-Path $TargetRoot "plugins\cache\mattpocock\mattpocock-skills") `
        -Counts $counts `
        -DryRun:$DryRun
}

Write-Output ""
Write-Output ("Resumen: {0} agregados, {1} actualizados, {2} sin cambios, {3} omitidos, {4} avisos -> {5}" -f `
    $counts.Added, $counts.Updated, $counts.Unchanged, $counts.Skipped, $counts.Warnings, $TargetRoot)

if ($DryRun) {
    Write-Output "[DRY RUN] No se modificó ningún archivo."
}
