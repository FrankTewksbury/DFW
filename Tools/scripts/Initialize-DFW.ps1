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
Write-Host '  1. INSTALL OBSIDIAN (if not already installed)' -ForegroundColor White
Write-Host "     - Download from: https://obsidian.md" -ForegroundColor Gray
Write-Host "     - Free, no account required" -ForegroundColor Gray
Write-Host ''
Write-Host '  2. OPEN THE VAULT IN OBSIDIAN' -ForegroundColor White
Write-Host "     - Open Obsidian > 'Open folder as vault' > select:" -ForegroundColor Gray
Write-Host "       $VaultPath" -ForegroundColor Cyan
Write-Host ''
Write-Host '  3. INSTALL OBSIDIAN PLUGINS' -ForegroundColor White
Write-Host "     - Settings > Community Plugins > Turn on community plugins" -ForegroundColor Gray
Write-Host "     - Browse and install these (then enable each one):" -ForegroundColor Gray
Write-Host "       CardBoard              (id: card-board)" -ForegroundColor Gray
Write-Host "       Templater              (id: templater-obsidian)" -ForegroundColor Gray
Write-Host "       Local REST API         (id: obsidian-local-rest-api)  ** REQUIRED **" -ForegroundColor Yellow
Write-Host "       Smart Connections      (id: smart-connections)" -ForegroundColor Gray
Write-Host "       Smart Templates        (id: smart-templates)" -ForegroundColor Gray
Write-Host "       MCP Tools              (id: mcp-tools)" -ForegroundColor Gray
Write-Host "       Cao                    (id: cao)" -ForegroundColor Gray
Write-Host ''
Write-Host '  4. CONFIGURE THE LOCAL REST API PLUGIN' -ForegroundColor White
Write-Host "     - Settings > Community Plugins > Local REST API (gear icon)" -ForegroundColor Gray
Write-Host "     - Copy or set your API Key — you will need it for Claude Desktop" -ForegroundColor Yellow
Write-Host "     - Default port: 27124 (leave as-is)" -ForegroundColor Gray
Write-Host "     - Test: open http://localhost:27124 in a browser" -ForegroundColor Gray
Write-Host ''
Write-Host '  5. ENABLE CARDBOARD CSS THEME' -ForegroundColor White
Write-Host "     - Settings > Appearance > CSS Snippets" -ForegroundColor Gray
Write-Host "     - Click refresh icon, then enable 'cardboard-dfw-theme'" -ForegroundColor Gray
Write-Host ''
Write-Host '  6. CONFIGURE CLAUDE DESKTOP MCP' -ForegroundColor White
Write-Host "     - Edit: %APPDATA%\Claude\claude_desktop_config.json" -ForegroundColor Gray
Write-Host "     - Use the template at:" -ForegroundColor Gray
Write-Host "       $DFWRoot\Tools\templates\claude-desktop-config-template.json" -ForegroundColor Cyan
Write-Host "     - Replace these placeholders:" -ForegroundColor Gray
Write-Host "       <YOUR_DFW_ROOT>              = $($DFWRoot -replace '\\','\\')" -ForegroundColor Yellow
Write-Host "       <YOUR_DFWP_PATH>             = $($ProjectPath -replace '\\','\\')" -ForegroundColor Yellow
Write-Host "       <YOUR_OBSIDIAN_REST_API_KEY> = your key from step 4" -ForegroundColor Yellow
Write-Host "     - RESTART Claude Desktop after saving" -ForegroundColor Gray
Write-Host ''
Write-Host '  7. CREATE A CLAUDE DESKTOP PROJECT' -ForegroundColor White
Write-Host "     - In Claude Desktop > Projects > Create a project" -ForegroundColor Gray
Write-Host "     - Add CLAUDE.md as a knowledge file:" -ForegroundColor Gray
Write-Host "       $ProjectPath\CLAUDE.md" -ForegroundColor Cyan
Write-Host "     - Enable connectors: dfw-filesystem, obsidian-mcp-tools" -ForegroundColor Gray
Write-Host ''
Write-Host '  8. OPEN DFWP IN CURSOR' -ForegroundColor White
Write-Host "     - Open the project folder:" -ForegroundColor Gray
Write-Host "       $ProjectPath" -ForegroundColor Cyan
Write-Host "     - Cursor rules are already in .cursor/rules/" -ForegroundColor Gray
Write-Host ''

if ($GitHubUser) {
    Write-Host '  9. PUSH DFWP TO GITHUB (optional)' -ForegroundColor White
    Write-Host "     - Create repo: https://github.com/$GitHubUser/DFWP (empty, no README)" -ForegroundColor Gray
    Write-Host "     - Then push:" -ForegroundColor Gray
    Write-Host "       cd $ProjectPath && git push -u origin main" -ForegroundColor Cyan
    Write-Host ''
}

Write-Host '  FULL SETUP GUIDE:' -ForegroundColor White
Write-Host "    $DFWRoot\Tools\docs\SETUP-GUIDE.md" -ForegroundColor Cyan
Write-Host ''
Write-Host '  KEY DOCS:' -ForegroundColor White
Write-Host "    Constitution: $ProjectPath\docs\DFW-CONSTITUTION.md" -ForegroundColor Gray
Write-Host "    Manual:       $ProjectPath\docs\DFW-OPERATING-MANUAL.md" -ForegroundColor Gray
Write-Host ''
