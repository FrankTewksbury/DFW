<#
.SYNOPSIS
    One-script DFW environment setup. Run this first.

.DESCRIPTION
    Guides a new user through the complete DFW (Development Flywheel) bootstrap:
      1. Validates PowerShell version (7.0+ required)
      2. Checks for Git and Node.js — installs via winget if missing
      3. Prompts for a drive letter to host all DFW projects
      4. Creates the Target Directory (<drive>:\Projects)
      5. Clones the DFW repo into the Target Directory (if not already there)
      6. Delegates to Initialize-DFW.ps1 for vault + DFWP scaffolding
      7. Generates a ready-to-use claude-desktop-config.json
      8. Prints next steps for Obsidian, Claude Desktop, and Cursor

.EXAMPLE
    # After cloning DFW to any temporary location:
    .\Start-Here.ps1

.EXAMPLE
    # Non-interactive (CI or scripted setup):
    .\Start-Here.ps1 -DriveLetter D -GitHubUser FrankTewksbury -Force
#>
[CmdletBinding()]
param(
    [string]$DriveLetter,
    [string]$GitHubUser,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# =========================================================================
# Banner
# =========================================================================
Write-Host ''
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host '  DFW — Development Flywheel Setup' -ForegroundColor Cyan
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host ''

# =========================================================================
# PowerShell Version Gate
# =========================================================================
Write-Host '  Checking prerequisites...' -ForegroundColor Gray
Write-Host ''

$psVer = $PSVersionTable.PSVersion
if ($psVer -lt [version]'7.0') {
    Write-Host "    PowerShell $psVer" -NoNewline
    Write-Host '          FAIL' -ForegroundColor Red
    Write-Host ''
    Write-Host '  DFW requires PowerShell 7.0 or later.' -ForegroundColor Red
    Write-Host "  Current version: $psVer" -ForegroundColor Red
    Write-Host '  Download from: https://github.com/PowerShell/PowerShell/releases' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  After installing, relaunch this script using pwsh:' -ForegroundColor Gray
    Write-Host '    pwsh .\Start-Here.ps1' -ForegroundColor Cyan
    Write-Host ''
    return
}
Write-Host "    PowerShell $psVer" -NoNewline
Write-Host '          OK' -ForegroundColor Green

# =========================================================================
# Helper: Refresh PATH from registry (picks up winget installs)
# =========================================================================
function Refresh-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

# =========================================================================
# Helper: Check for winget availability
# =========================================================================
function Test-Winget {
    $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
}

# =========================================================================
# Prerequisite: Git
# =========================================================================
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVer = (git --version) -replace 'git version ', ''
    Write-Host "    Git $gitVer" -NoNewline
    Write-Host '          OK' -ForegroundColor Green
} else {
    Write-Host '    Git ...' -NoNewline
    Write-Host '                    not found' -ForegroundColor Yellow

    if (Test-Winget) {
        Write-Host '      Installing via winget...' -ForegroundColor Gray
        winget install Git.Git --accept-source-agreements --accept-package-agreements --silent | Out-Null
        Refresh-SessionPath

        if (Get-Command git -ErrorAction SilentlyContinue) {
            $gitVer = (git --version) -replace 'git version ', ''
            Write-Host "      Installed Git $gitVer" -NoNewline
            Write-Host '     OK' -ForegroundColor Green
        } else {
            Write-Host ''
            Write-Host '  ERROR: Git installation completed but git is still not in PATH.' -ForegroundColor Red
            Write-Host '  Close this terminal, open a new one, and re-run Start-Here.ps1' -ForegroundColor Yellow
            Write-Host ''
            return
        }
    } else {
        Write-Host ''
        Write-Host '  Git is required but not installed, and winget is not available.' -ForegroundColor Red
        Write-Host '  Install Git manually: https://git-scm.com/downloads' -ForegroundColor Yellow
        Write-Host '  Then re-run this script.' -ForegroundColor Yellow
        Write-Host ''
        return
    }
}

# =========================================================================
# Prerequisite: Node.js
# =========================================================================
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVer = (node --version)
    Write-Host "    Node.js $nodeVer" -NoNewline
    Write-Host '          OK' -ForegroundColor Green
} else {
    Write-Host '    Node.js ...' -NoNewline
    Write-Host '                 not found' -ForegroundColor Yellow

    if (Test-Winget) {
        Write-Host '      Installing via winget...' -ForegroundColor Gray
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent | Out-Null
        Refresh-SessionPath

        if (Get-Command node -ErrorAction SilentlyContinue) {
            $nodeVer = (node --version)
            Write-Host "      Installed Node.js $nodeVer" -NoNewline
            Write-Host '  OK' -ForegroundColor Green
        } else {
            Write-Host ''
            Write-Host '  ERROR: Node.js installation completed but node is still not in PATH.' -ForegroundColor Red
            Write-Host '  Close this terminal, open a new one, and re-run Start-Here.ps1' -ForegroundColor Yellow
            Write-Host ''
            return
        }
    } else {
        Write-Host ''
        Write-Host '  Node.js is required but not installed, and winget is not available.' -ForegroundColor Red
        Write-Host '  Install Node.js LTS: https://nodejs.org' -ForegroundColor Yellow
        Write-Host '  Then re-run this script.' -ForegroundColor Yellow
        Write-Host ''
        return
    }
}

Write-Host ''

# =========================================================================
# Drive Letter Prompt
# =========================================================================
if (-not $DriveLetter) {
    Write-Host '  What drive letter do you want for DFW projects?' -ForegroundColor White
    Write-Host '  (All DFW repos, vault, and projects will live under <drive>:\Projects)' -ForegroundColor Gray
    Write-Host ''
    $DriveLetter = Read-Host '  Drive letter (e.g., C, D, X)'
}

$DriveLetter = $DriveLetter.Trim().TrimEnd(':').ToUpper()

if ($DriveLetter.Length -ne 1 -or $DriveLetter -notmatch '^[A-Z]$') {
    Write-Host "  ERROR: '$DriveLetter' is not a valid drive letter." -ForegroundColor Red
    return
}

$driveRoot = "${DriveLetter}:\"
if (-not (Test-Path $driveRoot)) {
    Write-Host "  ERROR: Drive ${DriveLetter}: does not exist." -ForegroundColor Red
    return
}

$targetDir = "${DriveLetter}:\Projects"
$dfwRoot = Join-Path $targetDir 'DFW'
$dfwpPath = Join-Path $dfwRoot 'DFWP'
$vaultPath = Join-Path $dfwRoot 'Vault'

Write-Host ''
Write-Host "  Target Directory:  $targetDir" -ForegroundColor White
Write-Host "  DFW Root:          $dfwRoot" -ForegroundColor White
Write-Host "  DFWP Project:      $dfwpPath" -ForegroundColor White
Write-Host "  Obsidian Vault:    $vaultPath" -ForegroundColor White
Write-Host ''

# =========================================================================
# Create Target Directory
# =========================================================================
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "  Creating $targetDir ..." -NoNewline
    Write-Host '              OK' -ForegroundColor Green
} else {
    Write-Host "  $targetDir" -NoNewline
    Write-Host '              exists' -ForegroundColor DarkGray
}

# =========================================================================
# Clone or Locate DFW Repo
# =========================================================================
$currentScriptDir = $PSScriptRoot

if ((Resolve-Path $currentScriptDir).Path -eq (Resolve-Path $dfwRoot -ErrorAction SilentlyContinue)?.Path) {
    Write-Host "  DFW repo already at $dfwRoot" -NoNewline
    Write-Host '  OK' -ForegroundColor Green
} elseif (Test-Path (Join-Path $dfwRoot 'Tools\Constitution\DFW-CONSTITUTION.md')) {
    Write-Host "  DFW repo already exists at $dfwRoot" -NoNewline
    Write-Host '  OK' -ForegroundColor Green
} else {
    Write-Host "  Cloning DFW to $dfwRoot ..." -ForegroundColor Gray

    $remoteUrl = $null
    try {
        $remoteUrl = git -C $currentScriptDir remote get-url origin 2>$null
    } catch { }

    if (-not $remoteUrl) {
        $remoteUrl = 'https://github.com/FrankTewksbury/DFW.git'
    }

    git clone $remoteUrl $dfwRoot
    if ($LASTEXITCODE -ne 0) {
        Write-Host '  ERROR: git clone failed.' -ForegroundColor Red
        return
    }
    Write-Host "  Cloned DFW to $dfwRoot" -NoNewline
    Write-Host '     OK' -ForegroundColor Green
}

Write-Host ''

# =========================================================================
# Delegate to Initialize-DFW.ps1
# =========================================================================
$initScript = Join-Path $dfwRoot 'Tools\scripts\Initialize-DFW.ps1'

if (-not (Test-Path $initScript)) {
    Write-Host "  ERROR: Cannot find $initScript" -ForegroundColor Red
    Write-Host '  The DFW repo may be incomplete. Try deleting and re-cloning.' -ForegroundColor Yellow
    return
}

$initParams = @{
    DFWRoot         = $dfwRoot
    ProjectPath     = $dfwpPath
    VaultPath       = $vaultPath
    TargetDirectory = $targetDir
    Force           = $Force
}
if ($GitHubUser) {
    $initParams['GitHubUser'] = $GitHubUser
}

& $initScript @initParams

# =========================================================================
# Generate claude-desktop-config.json
# =========================================================================
Write-Host ''
Write-Host '--- Generating Claude Desktop config ---' -ForegroundColor Cyan

$escapedDfwRoot = $dfwRoot -replace '\\', '\\'
$escapedDfwpPath = $dfwpPath -replace '\\', '\\'
$escapedTargetDir = $targetDir -replace '\\', '\\'

$configContent = @"
{
  "mcpServers": {
    "dfw-filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "$escapedDfwRoot",
        "$escapedDfwpPath"
      ]
    },
    "projects-filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "$escapedTargetDir"
      ]
    },
    "obsidian-mcp-tools": {
      "command": "npx",
      "args": ["-y", "obsidian-mcp-tools"],
      "env": {
        "OBSIDIAN_API_KEY": "<PASTE_YOUR_API_KEY_HERE>"
      }
    }
  }
}
"@

$configPath = Join-Path $dfwRoot 'claude-desktop-config.json'
Set-Content -Path $configPath -Value $configContent -Encoding UTF8
Write-Host "  Generated: $configPath" -ForegroundColor Green

# =========================================================================
# Final Instructions
# =========================================================================
Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Write-Host '  Setup Complete!' -ForegroundColor Green
Write-Host '================================================================' -ForegroundColor Green
Write-Host ''
Write-Host '  NEXT STEPS:' -ForegroundColor Yellow
Write-Host ''
Write-Host '  1. COPY THE CLAUDE DESKTOP CONFIG' -ForegroundColor White
Write-Host "     FROM: $configPath" -ForegroundColor Cyan
Write-Host '     TO:   %APPDATA%\Claude\claude_desktop_config.json' -ForegroundColor Cyan
Write-Host ''
Write-Host '     On Windows, press Win+R, type %APPDATA%\Claude, press Enter.' -ForegroundColor Gray
Write-Host '     If the folder does not exist, create it. Copy the file there.' -ForegroundColor Gray
Write-Host ''
Write-Host '  2. INSTALL OBSIDIAN (if not already installed)' -ForegroundColor White
Write-Host '     Download from: https://obsidian.md (free, no account required)' -ForegroundColor Gray
Write-Host ''
Write-Host '  3. OPEN THE VAULT IN OBSIDIAN' -ForegroundColor White
Write-Host "     Open Obsidian > 'Open folder as vault' > select:" -ForegroundColor Gray
Write-Host "     $vaultPath" -ForegroundColor Cyan
Write-Host ''
Write-Host '  4. INSTALL REQUIRED OBSIDIAN PLUGINS' -ForegroundColor White
Write-Host '     Settings > Community Plugins > Turn on community plugins > Browse' -ForegroundColor Gray
Write-Host '     Install and ENABLE each of these:' -ForegroundColor Gray
Write-Host '       Local REST API         (id: obsidian-local-rest-api)' -ForegroundColor Yellow
Write-Host '           ** REQUIRED — this is the bridge between Claude and your vault **' -ForegroundColor Yellow
Write-Host '       MCP Tools              (id: mcp-tools)' -ForegroundColor Gray
Write-Host '       CardBoard              (id: card-board)' -ForegroundColor Gray
Write-Host '       Templater              (id: templater-obsidian)' -ForegroundColor Gray
Write-Host '       Smart Connections      (id: smart-connections)' -ForegroundColor Gray
Write-Host ''
Write-Host '  5. GET YOUR OBSIDIAN API KEY' -ForegroundColor White
Write-Host '     Settings > Community Plugins > Local REST API (gear icon)' -ForegroundColor Gray
Write-Host '     Copy the API Key from the settings page.' -ForegroundColor Gray
Write-Host '     Test it: open http://localhost:27124 in a browser.' -ForegroundColor Gray
Write-Host ''
Write-Host '  6. UPDATE THE CONFIG WITH YOUR API KEY' -ForegroundColor White
Write-Host '     Open %APPDATA%\Claude\claude_desktop_config.json' -ForegroundColor Gray
Write-Host '     Replace <PASTE_YOUR_API_KEY_HERE> with your actual key from step 5.' -ForegroundColor Gray
Write-Host ''
Write-Host '  7. ENABLE CARDBOARD CSS THEME' -ForegroundColor White
Write-Host '     Settings > Appearance > CSS Snippets' -ForegroundColor Gray
Write-Host "     Click refresh icon, then enable 'cardboard-dfw-theme'" -ForegroundColor Gray
Write-Host ''
Write-Host '  8. RESTART CLAUDE DESKTOP — REQUIRED' -ForegroundColor White
Write-Host '     Right-click Claude icon in system tray > Quit (not just close window)' -ForegroundColor Yellow
Write-Host '     Then relaunch Claude Desktop.' -ForegroundColor Yellow
Write-Host '     MCP config is ONLY loaded at startup.' -ForegroundColor Yellow
Write-Host ''
Write-Host '  9. OPEN DFWP IN CURSOR' -ForegroundColor White
Write-Host "     Open Cursor > File > Open Folder > select:" -ForegroundColor Gray
Write-Host "     $dfwpPath" -ForegroundColor Cyan
Write-Host '     Cursor rules are already in .cursor/rules/' -ForegroundColor Gray
Write-Host ''

if ($GitHubUser) {
    Write-Host '  10. PUSH DFWP TO GITHUB (optional)' -ForegroundColor White
    Write-Host "      Create repo: https://github.com/$GitHubUser/DFWP (empty, no README)" -ForegroundColor Gray
    Write-Host "      Then: cd $dfwpPath && git push -u origin main" -ForegroundColor Cyan
    Write-Host ''
}

Write-Host '  FULL SETUP GUIDE:' -ForegroundColor White
Write-Host "    $dfwRoot\Tools\docs\SETUP-GUIDE.md" -ForegroundColor Cyan
Write-Host ''
Write-Host '  KEY DOCS:' -ForegroundColor White
Write-Host "    Constitution: $dfwpPath\docs\DFW-CONSTITUTION.md" -ForegroundColor Gray
Write-Host "    Manual:       $dfwpPath\docs\DFW-OPERATING-MANUAL.md" -ForegroundColor Gray
Write-Host ''
