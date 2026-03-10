# =============================================================================
# workspace-setup.ps1
# DevFlywheel workspace initialization script (Windows / PowerShell)
#
# PURPOSE:
#   Creates the standard DFW workspace folder structure and configures
#   DFW git aliases in the global git config.
#
# USAGE:
#   Run from inside the cloned DFW repo (`DFW`) directory:
#     cd path\to\your-workspace\DFW
#     .\Tools\scripts\workspace-setup.ps1
#
#   If execution policy blocks the script:
#     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#
# WHAT IT DOES:
#   1. Verifies it is being run from the correct location (inside the DFW repo root)
#   2. Creates 02-Projects\ directory in the workspace root
#   3. Installs DFW git aliases into global git config
#   4. Prints a summary and next steps
#
# WHAT IT DOES NOT DO:
#   - Clone any project repos (use project-clone.sh / project-clone.ps1)
#   - Modify any existing git config values it did not set
#   - Require network access
#
# NOTE: This script assumes the shared repo is cloned locally as `DFW`.
#       If your team uses a different local folder name, update this script and
#       the onboarding docs together.
# =============================================================================

#Requires -Version 5.1
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
# Step 1: Verify location
# -----------------------------------------------------------------------------
Write-Header "DevFlywheel Workspace Setup"
Write-Divider

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DFWRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$DFWFolderName = Split-Path -Leaf $DFWRoot

if ($DFWFolderName -ne "DFW") {
    Write-Err "This script must be run from inside the DFW directory."
    Write-Err "Current resolved repo directory: $DFWRoot"
    Write-Err "Expected folder name: DFW"
    Write-Host ""
    Write-Host "  Usage: cd path\to\your-workspace\DFW"
    Write-Host "         .\Tools\scripts\workspace-setup.ps1"
    exit 1
}

$WorkspaceRoot = Split-Path -Parent $DFWRoot

Write-DFW "Workspace root detected: $WorkspaceRoot"
Write-DFW "DFW repo location:      $DFWRoot"

# -----------------------------------------------------------------------------
# Step 2: Create standard folder structure
# -----------------------------------------------------------------------------
Write-Header "Creating workspace folder structure"

$ProjectsDir = Join-Path $WorkspaceRoot "02-Projects"

if (Test-Path $ProjectsDir) {
    Write-Warn "02-Projects\ already exists — skipping creation"
} else {
    New-Item -ItemType Directory -Path $ProjectsDir | Out-Null
    Write-DFW "Created: 02-Projects\"
}

# Create .gitkeep so the directory is visible on inspection
$GitkeepPath = Join-Path $ProjectsDir ".gitkeep"
if (-not (Test-Path $GitkeepPath)) {
    New-Item -ItemType File -Path $GitkeepPath | Out-Null
}

Write-DFW "Folder structure ready:"
Write-Host ""
$WorkspaceName = Split-Path -Leaf $WorkspaceRoot
Write-Host "  $WorkspaceName\"
Write-Host "  ├── DFW\              ← shared DFW repo (you are here)"
Write-Host "  └── 02-Projects\      ← project repos live here (cloned on-demand)"
Write-Host ""

# -----------------------------------------------------------------------------
# Step 3: Install DFW git aliases
# -----------------------------------------------------------------------------
Write-Header "Installing DFW git aliases"

# dfwsync-start: sync fork main from upstream + create feature branch + worktree
# Usage: git dfwsync-start <branch-name> <worktree-dir-name>
$dfwSyncStart = '!f() { ' +
    'if [ -z "$1" ] || [ -z "$2" ]; then ' +
        'echo "Usage: git dfwsync-start <branch-name> <worktree-dir-name>"; ' +
        'echo "Example: git dfwsync-start feature/42-auth-module project-rori-42"; ' +
        'exit 1; ' +
    'fi; ' +
    'git remote get-url upstream >/dev/null 2>&1 || { echo "[DFW] Error: upstream remote not configured. Add it with: git remote add upstream <url>"; exit 1; }; ' +
    'echo "[DFW] Fetching upstream..."; ' +
    'git fetch upstream; ' +
    'echo "[DFW] Syncing fork main from upstream..."; ' +
    'git checkout main; ' +
    'git merge upstream/main --ff-only; ' +
    'git push origin main; ' +
    'echo "[DFW] Creating worktree at: ../$2 on branch: $1"; ' +
    'git worktree add "../$2" -b "$1"; ' +
    'echo "[DFW] Done. Run: cd ../$2 && ./scripts/worktree-setup.sh"; ' +
'}; f'

git config --global alias.dfwsync-start $dfwSyncStart
Write-DFW "Installed: git dfwsync-start <branch> <worktree-dir>"

# dfwsync-complete: sync fork main + sync local branch + delete merged branch
# Usage: git dfwsync-complete <merged-branch-name>
$dfwSyncComplete = '!f() { ' +
    'if [ -z "$1" ]; then ' +
        'echo "Usage: git dfwsync-complete <merged-branch-name>"; ' +
        'echo "Example: git dfwsync-complete feature/42-auth-module"; ' +
        'exit 1; ' +
    'fi; ' +
    'git remote get-url upstream >/dev/null 2>&1 || { echo "[DFW] Error: upstream remote not configured. Add it with: git remote add upstream <url>"; exit 1; }; ' +
    'echo "[DFW] Fetching upstream..."; ' +
    'git fetch upstream; ' +
    'echo "[DFW] Syncing fork main from upstream..."; ' +
    'git checkout main; ' +
    'git merge upstream/main --ff-only; ' +
    'git push origin main; ' +
    'if git show-ref --verify --quiet refs/heads/local; then ' +
        'echo "[DFW] Syncing local branch..."; ' +
        'git checkout local; ' +
        'git rebase main; ' +
    'else ' +
        'echo "[DFW] No local branch yet — create it when you next start work: git checkout -b local && git push origin local"; ' +
    'fi; ' +
    'echo "[DFW] Deleting merged branch: $1"; ' +
    'git branch -d "$1"; ' +
    'if git ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1; then ' +
        'git push origin --delete "$1"; ' +
    'else ' +
        'echo "[DFW] Branch $1 was not on origin — skipping remote delete"; ' +
    'fi; ' +
    'echo "[DFW] Post-merge sync complete."; ' +
'}; f'

git config --global alias.dfwsync-complete $dfwSyncComplete
Write-DFW "Installed: git dfwsync-complete <merged-branch>"

# dfwsync-resume: sync and rebase a continuable branch at session start
# Usage: git dfwsync-resume <branch-name>
$dfwSyncResume = '!f() { ' +
    'if [ -z "$1" ]; then ' +
        'echo "Usage: git dfwsync-resume <branch-name>"; ' +
        'echo "Example: git dfwsync-resume feature/42-auth-module"; ' +
        'exit 1; ' +
    'fi; ' +
    'git remote get-url upstream >/dev/null 2>&1 || { echo "[DFW] Error: upstream remote not configured. Add it with: git remote add upstream <url>"; exit 1; }; ' +
    'echo "[DFW] Fetching upstream..."; ' +
    'git fetch upstream; ' +
    'echo "[DFW] Syncing fork main from upstream..."; ' +
    'git checkout main; ' +
    'git merge upstream/main --ff-only; ' +
    'git push origin main; ' +
    'echo "[DFW] Rebasing $1 onto updated main..."; ' +
    'git checkout "$1"; ' +
    'git rebase main; ' +
    'echo "[DFW] Ready to resume. Write your resume commit now."; ' +
'}; f'

git config --global alias.dfwsync-resume $dfwSyncResume
Write-DFW "Installed: git dfwsync-resume <branch>"

Write-Host ""
Write-DFW "All aliases installed to global git config"

# -----------------------------------------------------------------------------
# Step 4: Verify git version (worktrees need git 2.5+)
# -----------------------------------------------------------------------------
Write-Header "Checking prerequisites"

$GitVersionOutput = git --version
$GitVersionString = $GitVersionOutput -replace "git version ", ""
$VersionParts = $GitVersionString.Split(".")

$GitMajor = [int]$VersionParts[0]
$GitMinor = [int]$VersionParts[1]

if ($GitMajor -gt 2 -or ($GitMajor -eq 2 -and $GitMinor -ge 5)) {
    Write-DFW "git $GitVersionString — OK (worktrees supported)"
} else {
    Write-Warn "git $GitVersionString detected. Git 2.5+ required for worktree support."
    Write-Warn "Please upgrade git: https://git-scm.com/downloads"
}

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
Write-Header "Setup complete"
Write-Divider
Write-Host ""
Write-Host "  Workspace root:  $WorkspaceRoot"
Write-Host "  DFW repo:        $DFWRoot"
Write-Host "  Projects dir:    $ProjectsDir"
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Clone a project repo:"
Write-Host "     .\Tools\scripts\project-clone.ps1 <github-url> <ProjectFolderName>"
Write-Host ""
Write-Host "  2. Read the onboarding guide:"
Write-Host "     DFW\docs\git-collaboration\onboarding.mdx"
Write-Host ""
Write-Host "  3. Read the workspace conventions:"
Write-Host "     DFW\docs\git-collaboration\workspace-conventions.mdx"
Write-Host ""
Write-Divider
