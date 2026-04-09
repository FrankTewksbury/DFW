<#
.SYNOPSIS
    One-script DFW environment setup. Run this first.

.DESCRIPTION
    Guides a new user through the complete DFW (Development Flywheel) bootstrap:
      1. Validates PowerShell version (7.0+ required)
      2. Checks for Git and Node.js — installs via winget if missing
      3. Resolves root directory (-RootDir or current directory)
      4. Shows install paths and asks for confirmation
      5. Clones the DFW repo into <RootDir>\DFW (if not already there)
      6. Sets persistent environment variables (DFW_ROOT, DFW_TOOLS, PATH)
      7. Delegates to Initialize-DFW.ps1 for vault + DFWP scaffolding
      8. Generates a ready-to-use claude-desktop-config.json
      9. Sets execute permissions on all .ps1 scripts
     10. Prints next steps for Obsidian, Claude Desktop, and Cursor

.PARAMETER RootDir
    Parent directory where the DFW\ folder will be created.
    Example: -RootDir "C:\Projects" creates C:\Projects\DFW\...
    If omitted, defaults to the current working directory.

.PARAMETER GitHubUser
    GitHub username for DFWP remote setup. If omitted, git remote is skipped.

.PARAMETER Force
    Overwrite existing files during scaffolding.

.PARAMETER Help
    Display detailed help information and exit.

.EXAMPLE
    # Install into current directory (creates .\DFW\...):
    .\Start-Here.ps1

.EXAMPLE
    # Install into a specific path:
    .\Start-Here.ps1 -RootDir "D:\Projects"

.EXAMPLE
    # Non-interactive (CI or scripted setup):
    .\Start-Here.ps1 -RootDir "C:\DATA" -GitHubUser FrankTewksbury -Force

.EXAMPLE
    # Show help:
    .\Start-Here.ps1 -Help
#>
[CmdletBinding()]
param(
    [string]$RootDir,
    [string]$GitHubUser,
    [switch]$Force,
    [Alias('h', '?')]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# =========================================================================
# Help
# =========================================================================
if ($Help) {
    Write-Host ''
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host '  DFW — Development Flywheel Setup' -ForegroundColor Cyan
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  WHAT THIS DOES:' -ForegroundColor White
    Write-Host '    Sets up the complete DFW development environment on a new machine.' -ForegroundColor Gray
    Write-Host '    Run this once. Everything else is automated.' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  PREREQUISITES (auto-installed if missing):' -ForegroundColor White
    Write-Host '    - PowerShell 7.0+  (pwsh.exe, not powershell.exe)' -ForegroundColor Gray
    Write-Host '    - Git              (winget install Git.Git)' -ForegroundColor Gray
    Write-Host '    - Node.js LTS      (winget install OpenJS.NodeJS.LTS)' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  WHAT GETS CREATED (DFW\ structure is fixed, not configurable):' -ForegroundColor White
    Write-Host '    <RootDir>\DFW\              DFW repo (cloned or detected)' -ForegroundColor Gray
    Write-Host '    <RootDir>\DFW\DFWP\         Methodology project (scaffolded)' -ForegroundColor Gray
    Write-Host '    <RootDir>\DFW\Vault\        Obsidian vault (scaffolded)' -ForegroundColor Gray
    Write-Host '    <RootDir>\DFW\Tools\        Scripts, templates, rules' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  ENVIRONMENT VARIABLES SET:' -ForegroundColor White
    Write-Host '    DFW_ROOT    = <RootDir>\DFW            (User-level, persistent)' -ForegroundColor Gray
    Write-Host '    DFW_TOOLS   = <RootDir>\DFW\Tools      (User-level, persistent)' -ForegroundColor Gray
    Write-Host '    PATH       += <RootDir>\DFW\Tools\scripts  (User-level, persistent)' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  CONFIG FILES WRITTEN:' -ForegroundColor White
    Write-Host '    ~/.dfw/config.json              Machine-level DFW root config' -ForegroundColor Gray
    Write-Host '    claude-desktop-config.json       Ready-to-copy MCP config' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  PARAMETERS:' -ForegroundColor White
    Write-Host '    -RootDir <path>         Parent directory for DFW (default: current dir)' -ForegroundColor Gray
    Write-Host '    -GitHubUser  <name>     GitHub username for DFWP remote' -ForegroundColor Gray
    Write-Host '    -Force                  Overwrite existing files during scaffold' -ForegroundColor Gray
    Write-Host '    -Help                   Show this help and exit' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  EXAMPLES:' -ForegroundColor White
    Write-Host '    .\Start-Here.ps1                                            # Uses current dir' -ForegroundColor Cyan
    Write-Host '    .\Start-Here.ps1 -RootDir "D:\Projects"                     # Explicit path' -ForegroundColor Cyan
    Write-Host '    .\Start-Here.ps1 -RootDir "C:\DATA" -GitHubUser frank       # Full non-interactive' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  FULL DOCS:' -ForegroundColor White
    Write-Host '    After setup, see: <DFW_ROOT>\Tools\docs\SETUP-GUIDE.md' -ForegroundColor Gray
    Write-Host ''
    return
}

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
# Resolve Root Directory
# =========================================================================

# Detect if we are already running from inside a DFW repo.
# Marker: this script's directory contains Tools\Constitution\DFW-CONSTITUTION.md
$scriptDir = $PSScriptRoot
$isDfwRepo = Test-Path (Join-Path $scriptDir 'Tools\Constitution\DFW-CONSTITUTION.md')

if ($isDfwRepo) {
    # Script is inside the DFW repo — use this location as dfwRoot
    $dfwRoot = [System.IO.Path]::GetFullPath($scriptDir)

    if ($RootDir) {
        # User explicitly passed -RootDir but we're already in a DFW repo.
        # Warn them — we'll use the repo we're in, not create a new nested one.
        $resolvedRootDir = [System.IO.Path]::GetFullPath($RootDir)
        $expectedDfwRoot = Join-Path $resolvedRootDir 'DFW'
        if ($dfwRoot -ne $expectedDfwRoot) {
            Write-Host ''
            Write-Host '  NOTE: You are running Start-Here.ps1 from inside an existing DFW repo.' -ForegroundColor Yellow
            Write-Host "    Detected DFW root: $dfwRoot" -ForegroundColor Yellow
            Write-Host "    -RootDir $RootDir will be ignored." -ForegroundColor Yellow
            Write-Host '    To install elsewhere, copy Start-Here.ps1 to the target and run from there,' -ForegroundColor Gray
            Write-Host '    or run: .\Start-Here.ps1 -RootDir "<parent-of-DFW>" from outside the repo.' -ForegroundColor Gray
        }
    }

    $RootDir = Split-Path $dfwRoot -Parent
} else {
    # Script is NOT in a DFW repo — use -RootDir or CWD
    if (-not $RootDir) {
        $RootDir = (Get-Location).Path
    }

    $RootDir = [System.IO.Path]::GetFullPath($RootDir)

    # Validate the root directory (or its parent) exists
    if (-not (Test-Path $RootDir)) {
        $parentOfRoot = Split-Path $RootDir -Parent
        if (-not $parentOfRoot -or -not (Test-Path $parentOfRoot)) {
            Write-Host "  ERROR: Root directory does not exist and cannot be created: $RootDir" -ForegroundColor Red
            return
        }
    }

    # Check if RootDir itself IS already a DFW repo (user pointed directly at it)
    $rootDirIsDfw = Test-Path (Join-Path $RootDir 'Tools\Constitution\DFW-CONSTITUTION.md')

    if ($rootDirIsDfw) {
        # RootDir points to the DFW repo itself — use it as dfwRoot, parent as RootDir
        $dfwRoot = $RootDir
        $RootDir = Split-Path $dfwRoot -Parent
    } else {
        $dfwRoot = Join-Path $RootDir 'DFW'

        # Guard: if <RootDir>\DFW\DFW would be created, the user likely made an error
        $nestedDfw = Join-Path $dfwRoot 'DFW'
        if (Test-Path (Join-Path $RootDir 'DFW')) {
            $innerIsDfw = Test-Path (Join-Path $dfwRoot 'Tools\Constitution\DFW-CONSTITUTION.md')
            if (-not $innerIsDfw) {
                Write-Host "  ERROR: $dfwRoot exists but is not a DFW repo." -ForegroundColor Red
                Write-Host "  A 'DFW' directory exists at your root but doesn't contain the expected files." -ForegroundColor Yellow
                Write-Host '  Check your -RootDir and try again.' -ForegroundColor Yellow
                return
            }
        }
    }
}

# Derive fixed sub-paths
$dfwpPath  = Join-Path $dfwRoot 'DFWP'
$vaultPath = Join-Path $dfwRoot 'Vault'
$targetDir = $RootDir

# =========================================================================
# Confirm Before Proceeding
# =========================================================================
Write-Host ''
Write-Host '  Install location:' -ForegroundColor White
Write-Host ''
Write-Host "    Root Directory:  $RootDir" -ForegroundColor Cyan
Write-Host "    DFW Root:        $dfwRoot" -ForegroundColor Gray
Write-Host "    DFWP Project:    $dfwpPath" -ForegroundColor Gray
Write-Host "    Obsidian Vault:  $vaultPath" -ForegroundColor Gray
Write-Host "    Tools:           $dfwRoot\Tools" -ForegroundColor Gray
Write-Host ''

$confirm = Read-Host '  Proceed with installation? [Y/n]'
if ($confirm -match '^(n|no)$') {
    Write-Host ''
    Write-Host '  Aborted. Re-run with -RootDir to specify a different location.' -ForegroundColor Yellow
    Write-Host ''
    return
}

Write-Host ''

# =========================================================================
# Create Root Directory
# =========================================================================
if (-not (Test-Path $RootDir)) {
    New-Item -ItemType Directory -Path $RootDir -Force | Out-Null
    Write-Host "  Created: $RootDir" -ForegroundColor Green
} else {
    Write-Host "  $RootDir" -NoNewline
    Write-Host '  exists' -ForegroundColor DarkGray
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
# Set Environment Variables (User-level, persistent across sessions)
# =========================================================================
Write-Host ''
Write-Host '--- Setting environment variables ---' -ForegroundColor Cyan

$toolsPath = Join-Path $dfwRoot 'Tools'
$scriptsPath = Join-Path $toolsPath 'scripts'

# DFW_ROOT
$existingDfwRoot = [Environment]::GetEnvironmentVariable('DFW_ROOT', 'User')
if ($existingDfwRoot -eq $dfwRoot -and -not $Force) {
    Write-Host "  DFW_ROOT     = $dfwRoot" -NoNewline
    Write-Host '  (already set)' -ForegroundColor DarkGray
} else {
    [Environment]::SetEnvironmentVariable('DFW_ROOT', $dfwRoot, 'User')
    $env:DFW_ROOT = $dfwRoot
    Write-Host "  DFW_ROOT     = $dfwRoot" -NoNewline
    Write-Host '  SET' -ForegroundColor Green
}

# DFW_TOOLS
$existingDfwTools = [Environment]::GetEnvironmentVariable('DFW_TOOLS', 'User')
if ($existingDfwTools -eq $toolsPath -and -not $Force) {
    Write-Host "  DFW_TOOLS    = $toolsPath" -NoNewline
    Write-Host '  (already set)' -ForegroundColor DarkGray
} else {
    [Environment]::SetEnvironmentVariable('DFW_TOOLS', $toolsPath, 'User')
    $env:DFW_TOOLS = $toolsPath
    Write-Host "  DFW_TOOLS    = $toolsPath" -NoNewline
    Write-Host '  SET' -ForegroundColor Green
}

# PATH — add Tools\scripts if not already present
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -and $userPath.Split(';') -contains $scriptsPath) {
    Write-Host "  PATH        += $scriptsPath" -NoNewline
    Write-Host '  (already in PATH)' -ForegroundColor DarkGray
} else {
    $newPath = if ($userPath) { "$userPath;$scriptsPath" } else { $scriptsPath }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = "$env:Path;$scriptsPath"
    Write-Host "  PATH        += $scriptsPath" -NoNewline
    Write-Host '  ADDED' -ForegroundColor Green
}

Write-Host ''
Write-Host '  Environment variables are persistent (User-level).' -ForegroundColor Gray
Write-Host '  New terminal windows will inherit them automatically.' -ForegroundColor Gray

# =========================================================================
# Set Execute Permissions on Scripts
# =========================================================================
Write-Host ''
Write-Host '--- Setting script execute permissions ---' -ForegroundColor Cyan

$scriptFiles = Get-ChildItem -Path $scriptsPath -Filter '*.ps1' -File -ErrorAction SilentlyContinue
$libPath = Join-Path $scriptsPath 'lib'
if (Test-Path $libPath) {
    $scriptFiles += Get-ChildItem -Path $libPath -Filter '*.ps1' -File -ErrorAction SilentlyContinue
}
# Include Start-Here.ps1 itself
$scriptFiles += Get-Item $PSCommandPath

$unblocked = 0
foreach ($script in $scriptFiles) {
    # Remove Zone.Identifier ADS (the "downloaded from internet" block)
    if (Get-Item -Path $script.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue) {
        Unblock-File -Path $script.FullName
        $unblocked++
    }
}

if ($unblocked -gt 0) {
    Write-Host "  Unblocked $unblocked script(s) (removed download security zone)" -ForegroundColor Green
} else {
    Write-Host '  All scripts already unblocked' -ForegroundColor DarkGray
}

# Ensure execution policy allows local scripts
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'AllSigned') {
    Write-Host "  Current execution policy: $currentPolicy — setting to RemoteSigned" -ForegroundColor Yellow
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Write-Host '  Execution policy set to RemoteSigned (CurrentUser)' -ForegroundColor Green
} else {
    Write-Host "  Execution policy: $currentPolicy" -NoNewline
    Write-Host '  OK' -ForegroundColor Green
}

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
