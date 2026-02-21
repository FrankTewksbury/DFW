<#
.SYNOPSIS
    Master bootstrap script for the DFW (Development Flywheel) environment.

.DESCRIPTION
    Orchestrates the full DFW setup:
      1. Validates the DFW repo clone
      2. Creates the Obsidian vault (Initialize-DFWVault.ps1)
      3. Scaffolds the DFWP meta-project (Initialize-DFWP.ps1)
      4. Prints post-setup instructions for Obsidian, Claude Desktop, and Cursor

.PARAMETER DFWRoot
    Root of the DFW installation. Defaults to the parent of this script's Tools/scripts/ location.

.PARAMETER ProjectPath
    Where to create the DFWP project. Defaults to <DFWRoot parent>\DFWP.

.PARAMETER VaultPath
    Where to create the Obsidian vault. Defaults to <DFWRoot>\Vault.

.PARAMETER GitHubUser
    GitHub username for DFWP remote setup.

.PARAMETER SkipVault
    Skip vault creation (if already exists or managed separately).

.PARAMETER SkipProject
    Skip DFWP project creation.

.PARAMETER Force
    Overwrite existing files in both vault and project.

.EXAMPLE
    # Default installation
    .\Initialize-DFW.ps1

.EXAMPLE
    # Custom paths for testing
    .\Initialize-DFW.ps1 -DFWRoot C:\test\DFW -ProjectPath C:\test\DFWP -VaultPath C:\test\DFW\Vault

.EXAMPLE
    # Skip vault, only scaffold DFWP
    .\Initialize-DFW.ps1 -SkipVault -GitHubUser FrankTewksbury
#>
[CmdletBinding()]
param(
    [string]$DFWRoot,
    [string]$ProjectPath,
    [string]$VaultPath,
    [string]$GitHubUser,
    [switch]$SkipVault,
    [switch]$SkipProject,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Resolve DFW root from script location if not provided
if (-not $DFWRoot) {
    $DFWRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

$parentDir = Split-Path $DFWRoot -Parent

if (-not $ProjectPath) {
    $ProjectPath = Join-Path $parentDir 'DFWP'
}

if (-not $VaultPath) {
    $VaultPath = Join-Path $DFWRoot 'Vault'
}

$ToolsPath = Join-Path $DFWRoot 'Tools'

# =========================================================================
# Banner
# =========================================================================
Write-Host ''
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host '  DFW — Development Flywheel Bootstrap' -ForegroundColor Cyan
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "  DFW Root:      $DFWRoot"
Write-Host "  Vault Path:    $VaultPath"
Write-Host "  Project Path:  $ProjectPath"
Write-Host "  GitHub User:   $(if ($GitHubUser) { $GitHubUser } else { '(not set)' })"
Write-Host ''

# =========================================================================
# Validation
# =========================================================================
Write-Host '--- Validating DFW installation ---' -ForegroundColor Gray

$requiredFiles = @(
    (Join-Path $ToolsPath 'Constitution\DFW-CONSTITUTION.md'),
    (Join-Path $ToolsPath 'Manuals\DFW-OPERATING-MANUAL.md'),
    (Join-Path $ToolsPath 'Constitution\CLAUDE-PROJECT-TEMPLATE.md'),
    (Join-Path $ToolsPath 'templates\vault\.obsidian\community-plugins.json'),
    (Join-Path $ToolsPath 'templates\dfwp\.dfw\project.json')
)

$missing = @()
foreach ($f in $requiredFiles) {
    if (-not (Test-Path $f)) {
        $missing += $f
    }
}

if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host '  ERROR: Missing required files:' -ForegroundColor Red
    foreach ($m in $missing) {
        Write-Host "    - $m" -ForegroundColor Red
    }
    Write-Host ''
    Write-Host '  Make sure you cloned the full DFW repo.' -ForegroundColor Red
    return
}

Write-Host '  All required files present.' -ForegroundColor Green
Write-Host ''

# =========================================================================
# Step 1: Create Obsidian Vault
# =========================================================================
if (-not $SkipVault) {
    Write-Host '--- Step 1: Creating Obsidian Vault ---' -ForegroundColor Cyan

    $vaultScript = Join-Path $PSScriptRoot 'Initialize-DFWVault.ps1'
    & $vaultScript -VaultPath $VaultPath -DFWRoot $DFWRoot -DFWPDir $ProjectPath -Force:$Force
} else {
    Write-Host '--- Step 1: Skipped (Vault) ---' -ForegroundColor DarkGray
}

# =========================================================================
# Step 2: Scaffold DFWP Project
# =========================================================================
if (-not $SkipProject) {
    Write-Host '--- Step 2: Scaffolding DFWP Project ---' -ForegroundColor Cyan

    $projectScript = Join-Path $PSScriptRoot 'Initialize-DFWP.ps1'
    $projectParams = @{
        ProjectPath = $ProjectPath
        DFWRoot     = $DFWRoot
        Force       = $Force
    }
    if ($GitHubUser) {
        $projectParams['GitHubUser'] = $GitHubUser
    }
    & $projectScript @projectParams
} else {
    Write-Host '--- Step 2: Skipped (DFWP) ---' -ForegroundColor DarkGray
}

# =========================================================================
# Post-Setup Instructions
# =========================================================================
Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Write-Host '  DFW Bootstrap Complete!' -ForegroundColor Green
Write-Host '================================================================' -ForegroundColor Green
Write-Host ''
Write-Host '  NEXT STEPS:' -ForegroundColor Yellow
Write-Host ''
Write-Host '  1. OBSIDIAN' -ForegroundColor White
Write-Host "     - Open Obsidian and create a new vault pointing to:" -ForegroundColor Gray
Write-Host "       $VaultPath" -ForegroundColor Cyan
Write-Host "     - Go to Settings > Community Plugins > Turn on community plugins" -ForegroundColor Gray
Write-Host "     - Install these plugins:" -ForegroundColor Gray
Write-Host "       card-board, templater-obsidian, obsidian-local-rest-api" -ForegroundColor Gray
Write-Host "       smart-connections, smart-templates, mcp-tools, cao" -ForegroundColor Gray
Write-Host "     - Go to Settings > Appearance > CSS Snippets > Enable 'cardboard-dfw-theme'" -ForegroundColor Gray
Write-Host ''
Write-Host '  2. CLAUDE DESKTOP' -ForegroundColor White
Write-Host "     - Edit: %APPDATA%\Claude\claude_desktop_config.json" -ForegroundColor Gray
Write-Host "     - Add a 'dfw-filesystem' MCP server with allowed paths:" -ForegroundColor Gray
Write-Host "       $DFWRoot, $ProjectPath" -ForegroundColor Cyan
Write-Host "     - Create a Claude Desktop project with CLAUDE.md as knowledge file" -ForegroundColor Gray
Write-Host ''
Write-Host '  3. CURSOR / VS CODE' -ForegroundColor White
Write-Host "     - Open the workspace file or folder:" -ForegroundColor Gray
Write-Host "       $ProjectPath" -ForegroundColor Cyan
Write-Host "     - Cursor rules are already in .cursor/rules/" -ForegroundColor Gray
Write-Host ''

if ($GitHubUser) {
    Write-Host '  4. GITHUB' -ForegroundColor White
    Write-Host "     - Create repo: https://github.com/$GitHubUser/DFWP" -ForegroundColor Gray
    Write-Host "     - Then push:" -ForegroundColor Gray
    Write-Host "       cd $ProjectPath && git push -u origin main" -ForegroundColor Cyan
    Write-Host ''
}

Write-Host '  Read the constitution: docs/DFW-CONSTITUTION.md' -ForegroundColor Gray
Write-Host '  Read the manual:       docs/DFW-OPERATING-MANUAL.md' -ForegroundColor Gray
Write-Host ''
