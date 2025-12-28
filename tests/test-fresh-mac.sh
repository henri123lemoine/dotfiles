#!/bin/bash
# Simulates a fresh Mac by using an isolated HOME directory
# This tests dotfile linking and shell startup without affecting your real HOME
#
# Limitations:
# - Won't test Homebrew package installation (goes to /opt/homebrew)
# - Won't test system-level changes
# - For full fresh-Mac testing, rely on GitHub Actions CI
#
# Usage: ./tests/test-fresh-mac.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================"
echo "  Fresh Mac Simulation Test"
echo "======================================"
echo ""

# Create isolated environment
TEMP_HOME=$(mktemp -d)
echo "Temp HOME: $TEMP_HOME"

cleanup() {
  echo ""
  echo "Cleaning up $TEMP_HOME..."
  rm -rf "$TEMP_HOME"
}
trap cleanup EXIT

# Copy repo to temp location (simulates fresh git clone)
TEMP_REPO="$TEMP_HOME/dotfiles"
echo "Copying repo to $TEMP_REPO..."
cp -R "$REPO_DIR" "$TEMP_REPO"

# Remove any git submodule content (simulates clone without --recursive)
rm -rf "$TEMP_REPO/dotfiles-private"
mkdir -p "$TEMP_REPO/dotfiles-private"

echo ""
echo "--- Running setup with isolated HOME ---"
echo ""

# Run setup (skip brew since it installs to system location)
# Also skip external repos to avoid network dependency
(
  export HOME="$TEMP_HOME"
  export SETUP_BREW_PROFILE="skip"  # Skip brew entirely
  export SETUP_EXTERNAL_REPOS=0     # Skip external repo cloning
  cd "$TEMP_REPO"
  ./setup
)

echo ""
echo "--- Validating symlinks ---"
echo ""

check_symlink() {
  local path="$1"
  if [[ -L "$path" ]]; then
    echo -e "${GREEN}✓${NC} $path"
    return 0
  else
    echo -e "${RED}✗${NC} $path (not a symlink)"
    return 1
  fi
}

FAILED=0

check_symlink "$TEMP_HOME/.zshenv" || FAILED=1
check_symlink "$TEMP_HOME/.config/zsh" || FAILED=1
check_symlink "$TEMP_HOME/.config/git" || FAILED=1
check_symlink "$TEMP_HOME/.config/tmux" || FAILED=1
check_symlink "$TEMP_HOME/.config/nvim" || FAILED=1

echo ""
echo "--- Testing shell startup ---"
echo ""

# Test that zsh can start without errors
if HOME="$TEMP_HOME" zsh -ic 'echo "zsh startup OK"' 2>&1; then
  echo -e "${GREEN}✓${NC} zsh interactive startup succeeded"
else
  echo -e "${RED}✗${NC} zsh interactive startup failed"
  FAILED=1
fi

echo ""
echo "======================================"
if (( FAILED )); then
  echo -e "${RED}FAILED${NC} - Some tests did not pass"
  exit 1
else
  echo -e "${GREEN}PASSED${NC} - Fresh Mac simulation succeeded"
  echo ""
  echo -e "${YELLOW}Note:${NC} This doesn't test Homebrew or external repos."
  echo "For full testing, push to GitHub and check CI."
fi
