# =============================================================================
# project-clone.ps1
# DevFlywheel on-demand project clone helper (Windows / PowerShell)
#
# PURPOSE:
#   Clones a project repo into the correct workspace location (02-Projects\),
#   verifies the workspace layout is standard, and configures remotes correctly
#   for the DFW fork model.
#
# USAGE:
#   From anywhere inside your workspace:
#     .\DFW\Tools\scripts\project-clone.ps1 <github-url> <ProjectFolderName>
#
#   Examples:
#     # Clone a central repo directly (no fork):
#     .\DFW\Tools\scripts\project-clone.ps1 git@github.com:team/proj-rori.git RORI
#
#     # Clone your fork, with central as upstream:
#     .\DFW\Tools\scripts\project-clone.ps1 git@github.com:devA/proj-rori.git RORI `
#         -Upstream git@github.com:team/proj-rori.git
#
# PARAMETERS:
#   CloneUrl         GitHub URL to clone (your fork, or central if not using fork model)
#   ProjectFolderName Project folder name — will be created as 02-Projects\<ProjectFolderName>
#   Upstream         Optional. Central repo URL for the DFW fork model (origin=fork, upstream=central)
#
# WHAT IT DOES:
#   1. Verifies workspace layout (DFW present, 02-Projects present)
#   2. Clones the repo into 02-Projects\<ProjectFolderName>
#   3. Configures remotes (origin already set by clone; adds upstream if provided)
#   4. Verifies remote configuration
#   5. Prints next steps
#
# NOTE: This script assumes the shared DFW repo is cloned locally as `DFW`.
#       Update it together with the onboarding docs if that local folder name changes.
# =============================================================================

#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$CloneUrl,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$ProjectFolderName,

    [Parameter(Mandatory = $false)]
    [string]$Upstream
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# Formatting helpers
# -----------------------------------------------------------------------------
function Write-DFW    { param($Msg) Write-Host "[DFW] $Msg" -ForegroundColor Green }
function Write-Warn   { param($Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err    { param($Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }
function Write-Header { param($Msg) Write-Host "`n$Msg" -ForegroundColor White }
function Write-Divider { Write-Host "──────────────────────────────────────────────" }

# -----------------------------------------------------------------------------
# Step 1: Locate and verify workspace layout
# -----------------------------------------------------------------------------
Write-Header "DevFlywheel Project Clone"
Write-Divider

Write-DFW "Clone URL:      $CloneUrl"
Write-DFW "Project folder: $ProjectFolderName"
if ($Upstream) {
    Write-DFW "Upstream URL:   $Upstream"
}

Write-Header "Verifying workspace layout"

$SearchDir = Get-Location
$WorkspaceRoot = $null
$MaxDepth = 6

for ($i = 0; $i -lt $MaxDepth; $i++) {
    $MetaPath = Join-Path $SearchDir "DFW"
    if (Test-Path $MetaPath -PathType Container) {
        $WorkspaceRoot = $SearchDir
        break
    }
    $Parent = Split-Path -Parent $SearchDir
    if ($Parent -eq $SearchDir) {
        break
    }
    $SearchDir = $Parent
}

if (-not $WorkspaceRoot) {
    Write-Err "Could not find workspace root (a directory containing DFW\)."
    Write-Err "Run this script from inside your DFW workspace."
    Write-Host ""
    Write-Host "  Expected layout:"
    Write-Host "  your-workspace\"
    Write-Host "  ├── DFW\         ← shared DFW repo"
    Write-Host "  └── 02-Projects\"
    exit 1
}

Write-DFW "Workspace root found: $WorkspaceRoot"

$ProjectsDir = Join-Path $WorkspaceRoot "02-Projects"
if (-not (Test-Path $ProjectsDir -PathType Container)) {
    Write-Err "02-Projects\ directory not found at $ProjectsDir"
    Write-Err "Run workspace-setup.ps1 first to initialize the workspace structure."
    exit 1
}

Write-DFW "02-Projects\ found — workspace layout OK"

# -----------------------------------------------------------------------------
# Step 2: Check destination doesn't already exist
# -----------------------------------------------------------------------------
$DestDir = Join-Path $ProjectsDir $ProjectFolderName

if (Test-Path $DestDir) {
    Write-Err "Destination already exists: $DestDir"
    Write-Err "If you want to re-clone, remove the existing directory first."
    exit 1
}

# -----------------------------------------------------------------------------
# Step 3: Clone the repo
# -----------------------------------------------------------------------------
Write-Header "Cloning repository"

Write-DFW "Cloning into: $DestDir"
git clone $CloneUrl $DestDir
if ($LASTEXITCODE -ne 0) {
    Write-Err "Clone failed. Check your URL, network connection, and SSH keys."
    Write-Err "Verify SSH: ssh -T git@github.com"
    exit 1
}
Write-DFW "Clone complete"

# -----------------------------------------------------------------------------
# Step 4: Configure remotes
# -----------------------------------------------------------------------------
Write-Header "Configuring remotes"

Push-Location $DestDir
try {
    Write-DFW "origin → $CloneUrl (set by clone)"

    if ($Upstream) {
        git remote add upstream $Upstream
        Write-DFW "upstream → $Upstream (added)"
    } else {
        Write-Warn "No -Upstream URL provided."
        Write-Warn "If you are using the DFW fork model, add upstream manually:"
        Write-Warn "  cd $DestDir"
        Write-Warn "  git remote add upstream <central-repo-url>"
    }

    Write-Host ""
    Write-DFW "Remote configuration:"
    git remote -v | ForEach-Object { Write-Host "  $_" }

    # -----------------------------------------------------------------------------
    # Step 5: Verify the clone
    # -----------------------------------------------------------------------------
    Write-Header "Verifying clone"

    if (Test-Path "CLAUDE.md") {
        Write-DFW "CLAUDE.md found — DFW project confirmed"
    } else {
        Write-Warn "CLAUDE.md not found. This may not be a DFW-structured project,"
        Write-Warn "or CLAUDE.md may not have been created yet for this project."
    }

    git show-ref --verify --quiet refs/remotes/origin/local 2>$null
    $LocalExists = ($LASTEXITCODE -eq 0)
    $CurrentBranch = git branch --show-current 2>$null
    if ($LocalExists) {
        if ($CurrentBranch -ne "local") {
            Write-DFW "Remote 'local' branch found — checking out"
            git checkout -b local origin/local
            Write-DFW "Local branch ready"
        } else {
            Write-DFW "Already on local branch"
        }
    } else {
        Write-Warn "No 'local' branch found on remote. Create it when starting first session:"
        Write-Warn "  git checkout -b local"
        Write-Warn "  git push origin local"
    }

    # -----------------------------------------------------------------------------
    # Done
    # -----------------------------------------------------------------------------
    Write-Header "Project cloned successfully"
    Write-Divider
    Write-Host ""
    Write-Host "  Project:   $ProjectFolderName"
    Write-Host "  Location:  $DestDir"
    Write-Host ""
    Write-Host "  Next steps:"
    Write-Host "  1. Review team conventions:"
    Write-Host "     Get-Content $DestDir\CLAUDE.md"
    Write-Host ""
    Write-Host "  2. Start your first session:"
    Write-Host "     cd $DestDir"
    Write-Host "     git dfwsync-start feature/<issue-id>-<description> <worktree-dir-name>"
    Write-Host ""
    Write-Host "  3. Set up your worktree environment:"
    Write-Host "     cd ..\<worktree-dir-name>"
    Write-Host "     .\scripts\worktree-setup.sh   # Run from Git Bash (Bash script)"
    Write-Host ""
    Write-Host "  See the full onboarding guide:"
    Write-Host "     $WorkspaceRoot\DFW\docs\git-collaboration\onboarding.mdx"
    Write-Host ""
    Write-Divider
} finally {
    Pop-Location
}
