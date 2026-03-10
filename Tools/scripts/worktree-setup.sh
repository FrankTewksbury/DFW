#!/usr/bin/env bash
# =============================================================================
# worktree-setup.sh
# Per-worktree environment setup script
#
# PURPOSE:
#   Run once after creating a new worktree. Installs dependencies and sets up
#   the local environment so the worktree is ready to develop in.
#
# USAGE:
#   cd ../your-worktree-dir
#   ./scripts/worktree-setup.sh [--link-env]
#
# WINDOWS NOTE:
#   This is a Bash script. Run it from Git Bash or another POSIX-compatible shell.
#
# OPTIONS:
#   --link-env    Symlink .env.local from the main repo directory instead of
#                 copying from .env.example. Use when all worktrees share
#                 the same local credentials. Default: copy from .env.example.
#                 NOTE: On Windows, --link-env requires a Unix-like environment
#                 (e.g. Git Bash). It will not work in pure PowerShell.
#
# CUSTOMIZATION:
#   Edit the "Install dependencies" and "Verify setup" sections below for your
#   project's specific toolchain. The env file and structure sections are
#   general-purpose and usually need no changes.
# =============================================================================

set -euo pipefail

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

USE_LINK_ENV=false
if [ "${1:-}" = "--link-env" ]; then
  USE_LINK_ENV=true
fi

header "DFW Worktree Setup"
divider
info "Worktree: $(pwd)"
info "Branch:   $(git branch --show-current)"
echo ""

# -----------------------------------------------------------------------------
# Install dependencies
# Customize this section for your project's toolchain.
# -----------------------------------------------------------------------------
header "Installing dependencies"

if [ -f "package.json" ]; then
  info "Node project detected — running npm install"
  npm install
  info "Node dependencies installed"
fi

if [ -f "requirements.txt" ]; then
  info "Python project detected — installing requirements"
  if command -v python3 &>/dev/null; then
    python3 -m pip install -r requirements.txt --quiet
  elif command -v python &>/dev/null; then
    python -m pip install -r requirements.txt --quiet
  else
    warn "Neither python nor python3 found — install Python and re-run"
    exit 1
  fi
  info "Python dependencies installed"
fi

if [ -f "Gemfile" ]; then
  info "Ruby project detected — running bundle install"
  bundle install --quiet
  info "Ruby dependencies installed"
fi

if [ ! -f "package.json" ] && [ ! -f "requirements.txt" ] && [ ! -f "Gemfile" ]; then
  warn "No recognized dependency file found (package.json, requirements.txt, Gemfile)."
  warn "Edit the 'Install dependencies' section of this script for your toolchain."
fi

# -----------------------------------------------------------------------------
# Environment variables
# -----------------------------------------------------------------------------
header "Setting up environment"

# Find the main repo root (not worktree — the original clone)
# Git worktrees share the same .git directory, so we walk up to find it
MAIN_REPO_ROOT="$(git rev-parse --git-common-dir)"
MAIN_REPO_ROOT="$(cd "$MAIN_REPO_ROOT/.." && pwd)"

if [ "$USE_LINK_ENV" = true ]; then
  # Option A: Symlink — all worktrees share the same .env.local
  MAIN_ENV="$MAIN_REPO_ROOT/.env.local"
  if [ -f "$MAIN_ENV" ]; then
    ln -sf "$MAIN_ENV" .env.local
    info "Linked .env.local from main repo ($MAIN_ENV)"
  else
    warn "No .env.local found in main repo at $MAIN_ENV"
    warn "Create it there first, then re-run with --link-env"
  fi
else
  # Option B (default): Copy from .env.example — each worktree has its own
  if [ -f ".env.local" ]; then
    warn ".env.local already exists — skipping (not overwriting)"
  elif [ -f ".env.example" ]; then
    cp .env.example .env.local
    info "Created .env.local from .env.example"
    warn "Review .env.local and update any values needed for local development"
  else
    warn "No .env.example found — create .env.local manually if required"
  fi
fi

# -----------------------------------------------------------------------------
# Verify setup
# Customize this section with a command that confirms the environment is ready.
# The command should exit 0 on success and print something human-readable.
# -----------------------------------------------------------------------------
header "Verifying setup"

# ── CUSTOMIZE: Replace with your project's verification command ──────────────
# Add a command that exits 0 on success and prints something human-readable.
# Examples:
#   npm run typecheck
#   npm run build
#   python -c "import app; print('Import OK')"
#   python3 -m pytest --co -q
#   go build ./...
#   bundle exec rails runner "puts 'OK'"
#
# For now, we just confirm git status:
BRANCH=$(git branch --show-current)
COMMIT=$(git rev-parse --short HEAD)
info "Branch: $BRANCH @ $COMMIT"
info "Verification: add your project-specific check above this line"
# ── END CUSTOMIZE ─────────────────────────────────────────────────────────────

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
header "Worktree setup complete"
divider
echo ""
echo -e "  ${BOLD}Worktree:${RESET}  $(pwd)"
echo -e "  ${BOLD}Branch:${RESET}    $(git branch --show-current)"
echo ""
echo "  Next: write your first commit (new issue) or resume commit (continuable branch)"
echo "  See:  ../../DFW/docs/git-collaboration/commit-conventions.mdx"
echo ""
divider
