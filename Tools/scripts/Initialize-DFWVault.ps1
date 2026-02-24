<#
.SYNOPSIS
    Creates the DFW Obsidian vault from seed templates.

.DESCRIPTION
    Scaffolds the Obsidian vault directory structure and copies seed files
    from Tools/templates/vault/. The vault is personal and .gitignored in
    the DFW repo — this script recreates it from templates.

.PARAMETER VaultPath
    Absolute path where the vault should be created. Defaults to <DFWRoot>\Vault.

.PARAMETER DFWRoot
    Root of the DFW installation. Defaults to the parent of this script's location.

.PARAMETER DFWPDir
    Absolute path to the DFWP project directory. Used for template variable substitution.

.PARAMETER Force
    If set, overwrites existing vault files. Otherwise skips if vault already exists.
#>
[CmdletBinding()]
param(
    [string]$VaultPath,
    [string]$DFWRoot,
    [string]$DFWPDir,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Resolve DFW root from script location if not provided
if (-not $DFWRoot) {
    $DFWRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

if (-not $VaultPath) {
    $VaultPath = Join-Path $DFWRoot 'Vault'
}

if (-not $DFWPDir) {
    $DFWPDir = Join-Path (Split-Path $DFWRoot -Parent) 'DFWP'
}

$TemplatePath = Join-Path $DFWRoot 'Tools\templates\vault'

Write-Host ''
Write-Host '=== Initialize-DFWVault ===' -ForegroundColor Cyan
Write-Host "  DFW Root:     $DFWRoot"
Write-Host "  Vault Path:   $VaultPath"
Write-Host "  DFWP Dir:     $DFWPDir"
Write-Host "  Template Src: $TemplatePath"
Write-Host ''

# Guard: check template source exists
if (-not (Test-Path $TemplatePath)) {
    Write-Error "Template directory not found: $TemplatePath"
    return
}

# Guard: check if vault already exists
if ((Test-Path $VaultPath) -and -not $Force) {
    Write-Host "Vault already exists at $VaultPath. Use -Force to overwrite." -ForegroundColor Yellow
    return
}

# Create vault directory
if (-not (Test-Path $VaultPath)) {
    New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
    Write-Host "  Created: $VaultPath" -ForegroundColor Green
}

# Copy entire template tree
Write-Host '  Copying vault templates...' -ForegroundColor Gray
$templateFiles = Get-ChildItem -Path $TemplatePath -Recurse -File

$today = Get-Date -Format 'yyyy-MM-dd'

foreach ($file in $templateFiles) {
    $relativePath = $file.FullName.Substring($TemplatePath.Length + 1)
    $destPath = Join-Path $VaultPath $relativePath
    $destDir = Split-Path $destPath -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if ((Test-Path $destPath) -and -not $Force) {
        Write-Host "  Skipped (exists): $relativePath" -ForegroundColor DarkGray
        continue
    }

    $content = Get-Content -Path $file.FullName -Raw

    # Template variable substitution
    $content = $content -replace '\{\{DFWP_DIR\}\}', $DFWPDir
    $content = $content -replace '\{\{DFW_ROOT\}\}', $DFWRoot
    $content = $content -replace '\{\{DATE\}\}', $today
    $content = $content -replace '\{\{OWNER\}\}', $env:USERNAME

    Set-Content -Path $destPath -Value $content -NoNewline
    Write-Host "  Created: $relativePath" -ForegroundColor Green
}

# Create empty directories that templates don't populate
$emptyDirs = @(
    'research',
    'projects\_archive'
)

foreach ($dir in $emptyDirs) {
    $dirPath = Join-Path $VaultPath $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        Write-Host "  Created dir: $dir" -ForegroundColor Green
    }
}

# =========================================================================
# Post-Scaffold Verification
# =========================================================================
Write-Host '  Verifying vault structure...' -ForegroundColor Gray

$requiredDirs = @('ideas', 'inbox', 'journal', 'meta', 'projects')
$missingDirs = @()

foreach ($dir in $requiredDirs) {
    $dirPath = Join-Path $VaultPath $dir
    if (-not (Test-Path $dirPath)) {
        $missingDirs += $dir
    }
}

if ($missingDirs.Count -gt 0) {
    Write-Host ''
    Write-Host '  WARNING: Vault structure verification FAILED.' -ForegroundColor Red
    Write-Host '  Missing directories at vault root:' -ForegroundColor Red
    foreach ($d in $missingDirs) {
        Write-Host "    - $d" -ForegroundColor Red
    }
    Write-Host '  The template may not have copied correctly.' -ForegroundColor Red
    Write-Host '  Check that Tools\templates\vault\ contains the expected structure.' -ForegroundColor Red
    Write-Host ''
} else {
    Write-Host '  Vault structure verified: all required directories present.' -ForegroundColor Green
}

$nestedVaults = Get-ChildItem -Path $VaultPath -Directory -Depth 1 |
    Where-Object {
        $_.Name -ne '.obsidian' -and
        $_.Name -notin $requiredDirs -and
        $_.Name -ne 'research' -and
        $_.Name -ne '_archive' -and
        (Test-Path (Join-Path $_.FullName '.obsidian'))
    }

if ($nestedVaults.Count -gt 0) {
    Write-Host ''
    Write-Host '  WARNING: Possible nested vault detected:' -ForegroundColor Yellow
    foreach ($nv in $nestedVaults) {
        Write-Host "    - $($nv.FullName) (contains .obsidian/)" -ForegroundColor Yellow
    }
    Write-Host '  This may indicate the template was copied to the wrong depth.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '  Vault initialization complete.' -ForegroundColor Green
Write-Host ''
