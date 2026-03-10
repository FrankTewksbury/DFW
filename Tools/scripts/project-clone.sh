#!/usr/bin/env bash
# =============================================================================
# project-clone.sh
# DevFlywheel on-demand project clone helper
#
# PURPOSE:
#   Clones a project repo into the correct workspace location (02-Projects/),
#   verifies the workspace layout is standard, and configures remotes correctly
#   for the DFW fork model.
#
# USAGE:
#   From anywhere inside your workspace:
#     ./DFW/Tools/scripts/project-clone.sh <github-url> <ProjectFolderName>
#
#   Examples:
#     # Clone a central repo directly (no fork):
#     ./DFW/Tools/scripts/project-clone.sh git@github.com:team/proj-rori.git RORI
#
#     # Clone your fork, with central as upstream:
#     ./DFW/Tools/scripts/project-clone.sh git@github.com:devA/proj-rori.git RORI \
#         --upstream git@github.com:team/proj-rori.git
#
# ARGUMENTS:
#   $1  GitHub URL to clone (your fork, or central if not using fork model)
#   $2  Project folder name — will be created as 02-Projects/<ProjectFolderName>
#
# OPTIONS:
#   --upstream <url>   Also add a remote named 'upstream' pointing to central repo
#                      Required for the DFW fork model (origin = fork, upstream = central)
#
# WHAT IT DOES:
#   1. Verifies workspace layout (DFW present, 02-Projects present)
#   2. Clones the repo into 02-Projects/<ProjectFolderName>
#   3. Configures remotes (origin already set by clone; adds upstream if provided)
#   4. Verifies remote configuration
#   5. Prints next steps
#
# This script assumes the shared DFW repo is cloned locally as `DFW`. Update it together with the onboarding docs if that local folder name changes.
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
# Parse arguments
# -----------------------------------------------------------------------------
header "DevFlywheel Project Clone"
divider

if [ $# -lt 2 ]; then
  error "Missing required arguments."
  echo ""
  echo "  Usage: ./DFW/Tools/scripts/project-clone.sh <github-url> <ProjectFolderName>"
  echo "         ./DFW/Tools/scripts/project-clone.sh <github-url> <ProjectFolderName> --upstream <upstream-url>"
  echo ""
  echo "  Examples:"
  echo "    ./DFW/Tools/scripts/project-clone.sh git@github.com:team/proj-rori.git RORI"
  echo "    ./DFW/Tools/scripts/project-clone.sh git@github.com:devA/proj-rori.git RORI --upstream git@github.com:team/proj-rori.git"
  exit 1
fi

CLONE_URL="$1"
PROJECT_FOLDER_NAME="$2"
UPSTREAM_URL=""

# Parse optional --upstream flag
shift 2
while [ $# -gt 0 ]; do
  case "$1" in
    --upstream)
      if [ -z "${2:-}" ]; then
        error "--upstream requires a URL argument"
        exit 1
      fi
      UPSTREAM_URL="$2"
      shift 2
      ;;
    *)
      error "Unknown argument: $1"
      exit 1
      ;;
  esac
done

info "Clone URL:      $CLONE_URL"
info "Project folder: $PROJECT_FOLDER_NAME"
if [ -n "$UPSTREAM_URL" ]; then
  info "Upstream URL:   $UPSTREAM_URL"
fi

# -----------------------------------------------------------------------------
# Step 1: Locate and verify workspace layout
# -----------------------------------------------------------------------------
header "Verifying workspace layout"

# Find workspace root by looking for the DFW repo clone from current directory upward
CURRENT_DIR="$(pwd)"
WORKSPACE_ROOT=""

# Walk up from current directory looking for DFW
# Note: Search depth is 6 levels; consider increasing for very deep directory structures
SEARCH_DIR="$CURRENT_DIR"
for _ in {1..6}; do
  if [ -d "$SEARCH_DIR/DFW" ]; then
    WORKSPACE_ROOT="$SEARCH_DIR"
    break
  fi
  PARENT="$(dirname "$SEARCH_DIR")"
  if [ "$PARENT" = "$SEARCH_DIR" ]; then
    break  # reached filesystem root
  fi
  SEARCH_DIR="$PARENT"
done

if [ -z "$WORKSPACE_ROOT" ]; then
  error "Could not find workspace root (a directory containing DFW/)."
  error "Run this script from inside your DFW workspace."
  echo ""
  echo "  Expected layout:"
  echo "  your-workspace/"
  echo "  ├── DFW/         ← shared DFW repo"
  echo "  └── 02-Projects/"
  exit 1
fi

info "Workspace root found: $WORKSPACE_ROOT"

# Verify 02-Projects exists
PROJECTS_DIR="$WORKSPACE_ROOT/02-Projects"
if [ ! -d "$PROJECTS_DIR" ]; then
  error "02-Projects/ directory not found at $PROJECTS_DIR"
  error "Run workspace-setup.sh first to initialize the workspace structure."
  exit 1
fi

info "02-Projects/ found — workspace layout OK"

# -----------------------------------------------------------------------------
# Step 2: Check destination doesn't already exist
# -----------------------------------------------------------------------------
DEST_DIR="$PROJECTS_DIR/$PROJECT_FOLDER_NAME"

if [ -d "$DEST_DIR" ]; then
  error "Destination already exists: $DEST_DIR"
  error "If you want to re-clone, remove the existing directory first."
  exit 1
fi

# -----------------------------------------------------------------------------
# Step 3: Clone the repo
# -----------------------------------------------------------------------------
header "Cloning repository"

info "Cloning into: $DEST_DIR"
if ! git clone "$CLONE_URL" "$DEST_DIR"; then
  error "Clone failed. Check your URL, network connection, and SSH keys."
  error "Verify SSH: ssh -T git@github.com"
  exit 1
fi
info "Clone complete"

# -----------------------------------------------------------------------------
# Step 4: Configure remotes
# -----------------------------------------------------------------------------
header "Configuring remotes"

cd "$DEST_DIR"

# origin is already set by git clone to CLONE_URL
info "origin → $CLONE_URL (set by clone)"

# Add upstream if provided
if [ -n "$UPSTREAM_URL" ]; then
  git remote add upstream "$UPSTREAM_URL"
  info "upstream → $UPSTREAM_URL (added)"
else
  warn "No --upstream URL provided."
  warn "If you are using the DFW fork model, add upstream manually:"
  warn "  cd $DEST_DIR"
  warn "  git remote add upstream <central-repo-url>"
fi

# Verify remote configuration
echo ""
info "Remote configuration:"
git remote -v | sed 's/^/  /'

# -----------------------------------------------------------------------------
# Step 5: Verify the clone
# -----------------------------------------------------------------------------
header "Verifying clone"

# Check CLAUDE.md exists (expected in every DFW project)
if [ -f "CLAUDE.md" ]; then
  info "CLAUDE.md found — DFW project confirmed"
else
  warn "CLAUDE.md not found. This may not be a DFW-structured project,"
  warn "or CLAUDE.md may not have been created yet for this project."
fi

# Check for local branch (may not exist on fresh clone — that is OK)
if git show-ref --verify --quiet refs/remotes/origin/local 2>/dev/null; then
  if [ "$(git branch --show-current)" != "local" ]; then
    info "Remote 'local' branch found — checking out"
    git checkout -b local origin/local
    info "Local branch ready"
  else
    info "Already on local branch"
  fi
else
  warn "No 'local' branch found on remote. Create it when starting first session:"
  warn "  git checkout -b local"
  warn "  git push origin local"
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
header "Project cloned successfully"
divider
echo ""
echo -e "  ${BOLD}Project:${RESET}   $PROJECT_FOLDER_NAME"
echo -e "  ${BOLD}Location:${RESET}  $DEST_DIR"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo "  1. Review team conventions:"
echo "     cat $DEST_DIR/CLAUDE.md"
echo ""
echo "  2. Start your first session:"
echo "     cd $DEST_DIR"
echo "     git dfwsync-start feature/<issue-id>-<description> <worktree-dir-name>"
echo ""
echo "  3. Set up your worktree environment:"
echo "     cd ../<worktree-dir-name>"
echo "     ./scripts/worktree-setup.sh"
echo ""
echo "  See the full onboarding guide:"
echo "     $WORKSPACE_ROOT/DFW/docs/git-collaboration/onboarding.mdx"
echo ""
divider
