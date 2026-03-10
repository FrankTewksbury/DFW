#!/usr/bin/env bash
# =============================================================================
# workspace-setup.sh
# DevFlywheel workspace initialization script
#
# PURPOSE:
#   Creates the standard DFW workspace folder structure and configures
#   DFW git aliases in the global git config.
#
# USAGE:
#   Run from inside the cloned DFW repo (`DFW`) directory:
#     cd path/to/your-workspace/DFW
#     ./Tools/scripts/workspace-setup.sh
#
# WHAT IT DOES:
#   1. Verifies it is being run from the correct location (inside the DFW repo root)
#   2. Creates 02-Projects/ directory in the workspace root
#   3. Installs DFW git aliases into ~/.gitconfig
#   4. Prints a summary and next steps
#
# WHAT IT DOES NOT DO:
#   - Clone any project repos (use project-clone.sh for that)
#   - Modify any existing git config values it did not set
#   - Require network access
#
# NOTE: This script assumes the shared repo is cloned locally as `DFW`. If your team uses a different local folder name, update this script and the onboarding docs together.
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Formatting helpers
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${GREEN}[DFW]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
header()  { echo -e "\n${BOLD}$1${RESET}"; }
divider() { echo "──────────────────────────────────────────────"; }

# -----------------------------------------------------------------------------
# Step 1: Verify location
# -----------------------------------------------------------------------------
header "DevFlywheel Workspace Setup"
divider

# This script should be run from inside DFW/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DFW_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DFW_FOLDER_NAME="$(basename "$DFW_ROOT")"

if [ "$DFW_FOLDER_NAME" != "DFW" ]; then
  error "This script must be run from inside the DFW directory."
  error "Current resolved repo directory: $DFW_ROOT"
  error "Expected folder name: DFW"
  echo ""
  echo "  Usage: cd path/to/your-workspace/DFW"
  echo "         ./Tools/scripts/workspace-setup.sh"
  exit 1
fi

WORKSPACE_ROOT="$(cd "$DFW_ROOT/.." && pwd)"
info "Workspace root detected: $WORKSPACE_ROOT"
info "DFW repo location:      $DFW_ROOT"

# -----------------------------------------------------------------------------
# Step 2: Create standard folder structure
# -----------------------------------------------------------------------------
header "Creating workspace folder structure"

PROJECTS_DIR="$WORKSPACE_ROOT/02-Projects"

if [ -d "$PROJECTS_DIR" ]; then
  warn "02-Projects/ already exists — skipping creation"
else
  mkdir -p "$PROJECTS_DIR"
  info "Created: 02-Projects/"
fi

# Create a .gitkeep so the directory is visible if someone inspects the layout
# (02-Projects itself is not a repo, so nothing to track)
if [ ! -f "$PROJECTS_DIR/.gitkeep" ]; then
  touch "$PROJECTS_DIR/.gitkeep"
fi

info "Folder structure ready:"
echo ""
echo "  $(basename "$WORKSPACE_ROOT")/"
echo "  ├── DFW/              ← shared DFW repo (you are here)"
echo "  └── 02-Projects/      ← project repos live here (cloned on-demand)"
echo ""

# -----------------------------------------------------------------------------
# Step 3: Install DFW git aliases
# -----------------------------------------------------------------------------
header "Installing DFW git aliases"

# dfwsync-start: sync fork main from upstream + create feature branch + worktree
# Usage: git dfwsync-start <branch-name> <worktree-dir-name>
# Example: git dfwsync-start feature/42-auth-module project-rori-42
git config --global alias.dfwsync-start '!f() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: git dfwsync-start <branch-name> <worktree-dir-name>";
    echo "Example: git dfwsync-start feature/42-auth-module project-rori-42";
    exit 1;
  fi;
  git remote get-url upstream >/dev/null 2>&1 || { echo "[DFW] Error: upstream remote not configured. Add it with: git remote add upstream <url>"; exit 1; };
  echo "[DFW] Fetching upstream...";
  git fetch upstream;
  echo "[DFW] Syncing fork main from upstream...";
  git checkout main;
  git merge upstream/main --ff-only;
  git push origin main;
  echo "[DFW] Creating worktree at: ../$2 on branch: $1";
  git worktree add "../$2" -b "$1";
  echo "[DFW] Done. Run: cd ../$2 && ./scripts/worktree-setup.sh";
}; f'

info "Installed: git dfwsync-start <branch> <worktree-dir>"

# dfwsync-complete: sync fork main + sync local branch + delete merged branch
# Usage: git dfwsync-complete <merged-branch-name>
# Example: git dfwsync-complete feature/42-auth-module
git config --global alias.dfwsync-complete '!f() {
  if [ -z "$1" ]; then
    echo "Usage: git dfwsync-complete <merged-branch-name>";
    echo "Example: git dfwsync-complete feature/42-auth-module";
    exit 1;
  fi;
  git remote get-url upstream >/dev/null 2>&1 || { echo "[DFW] Error: upstream remote not configured. Add it with: git remote add upstream <url>"; exit 1; };
  echo "[DFW] Fetching upstream...";
  git fetch upstream;
  echo "[DFW] Syncing fork main from upstream...";
  git checkout main;
  git merge upstream/main --ff-only;
  git push origin main;
  if git show-ref --verify --quiet refs/heads/local; then
    echo "[DFW] Syncing local branch...";
    git checkout local;
    git rebase main;
  else
    echo "[DFW] No local branch yet — create it when you next start work: git checkout -b local && git push origin local";
  fi;
  echo "[DFW] Deleting merged branch: $1";
  git branch -d "$1";
  if git ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1; then
    git push origin --delete "$1";
  else
    echo "[DFW] Branch $1 was not on origin — skipping remote delete";
  fi;
  echo "[DFW] Post-merge sync complete.";
}; f'

info "Installed: git dfwsync-complete <merged-branch>"

# dfwsync-resume: sync and rebase a continuable branch at session start
# Usage: git dfwsync-resume <branch-name>
# Example: git dfwsync-resume feature/42-auth-module
git config --global alias.dfwsync-resume '!f() {
  if [ -z "$1" ]; then
    echo "Usage: git dfwsync-resume <branch-name>";
    echo "Example: git dfwsync-resume feature/42-auth-module";
    exit 1;
  fi;
  git remote get-url upstream >/dev/null 2>&1 || { echo "[DFW] Error: upstream remote not configured. Add it with: git remote add upstream <url>"; exit 1; };
  echo "[DFW] Fetching upstream...";
  git fetch upstream;
  echo "[DFW] Syncing fork main from upstream...";
  git checkout main;
  git merge upstream/main --ff-only;
  git push origin main;
  echo "[DFW] Rebasing $1 onto updated main...";
  git checkout "$1";
  git rebase main;
  echo "[DFW] Ready to resume. Write your resume commit now.";
}; f'

info "Installed: git dfwsync-resume <branch>"

echo ""
info "All aliases installed to ~/.gitconfig"
echo ""
echo "  Run 'git dfwsync-start --help'... (just run it with no args to see usage)"
echo ""

# -----------------------------------------------------------------------------
# Step 4: Verify git version (worktrees need git 2.5+)
# -----------------------------------------------------------------------------
header "Checking prerequisites"

GIT_VERSION=$(git --version | awk '{print $3}')
GIT_MAJOR=$(echo "$GIT_VERSION" | cut -d. -f1)
GIT_MINOR=$(echo "$GIT_VERSION" | cut -d. -f2)

if [ "$GIT_MAJOR" -gt 2 ] || { [ "$GIT_MAJOR" -eq 2 ] && [ "$GIT_MINOR" -ge 5 ]; }; then
  info "git $GIT_VERSION — OK (worktrees supported)"
else
  warn "git $GIT_VERSION detected. Git 2.5+ required for worktree support."
  warn "Please upgrade git: https://git-scm.com/downloads"
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
header "Setup complete"
divider
echo ""
echo -e "  ${BOLD}Workspace root:${RESET}  $WORKSPACE_ROOT"
echo -e "  ${BOLD}DFW repo:${RESET}        $DFW_ROOT"
echo -e "  ${BOLD}Projects dir:${RESET}    $PROJECTS_DIR"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo "  1. Clone a project repo:"
echo "     ./Tools/scripts/project-clone.sh <github-url> <ProjectFolderName>"
echo ""
echo "  2. Read the onboarding guide:"
echo "     DFW/docs/git-collaboration/onboarding.mdx"
echo ""
echo "  3. Read the workspace conventions:"
echo "     DFW/docs/git-collaboration/workspace-conventions.mdx"
echo ""
divider
