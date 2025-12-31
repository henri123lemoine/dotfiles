#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED_TESTS=()
PASSED_TESTS=()
SKIPPED_TESTS=()

pass() {
  echo -e "${GREEN}✓${NC} $1"
  PASSED_TESTS+=("$1")
}

fail() {
  echo -e "${RED}✗${NC} $1"
  FAILED_TESTS+=("$1")
}

skip() {
  echo -e "${YELLOW}⊘${NC} $1 (skipped)"
  SKIPPED_TESTS+=("$1")
}

test_command() {
  local cmd="$1"
  local description="${2:-command '$cmd' exists}"

  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$description"
    return 0
  else
    fail "$description"
    return 1
  fi
}

test_symlink() {
  local path="$1"
  local description="${2:-$path is a symlink}"

  if [[ -L "$path" ]]; then
    pass "$description"
    return 0
  else
    fail "$description"
    return 1
  fi
}

test_file_exists() {
  local path="$1"
  local description="${2:-$path exists}"

  if [[ -e "$path" ]]; then
    pass "$description"
    return 0
  else
    fail "$description"
    return 1
  fi
}

test_command_runs() {
  local cmd="$1"
  local description="${2:-command '$cmd' runs without error}"

  if eval "$cmd" >/dev/null 2>&1; then
    pass "$description"
    return 0
  else
    fail "$description"
    return 1
  fi
}

echo "======================================"
echo "  Dotfiles Setup Validation Tests"
echo "======================================"
echo ""

if [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -f /etc/debian_version ]]; then
  OS_TYPE="ubuntu"
else
  OS_TYPE="unknown"
fi

echo "Detected OS: $OS_TYPE"
echo ""

echo "--- Testing Symlinks ---"
test_symlink "$HOME/.zshenv" ".zshenv symlink"
test_symlink "$HOME/.config/zsh" ".config/zsh symlink"
test_symlink "$HOME/.config/git" ".config/git symlink"
test_symlink "$HOME/.config/tmux" ".config/tmux symlink"
test_symlink "$HOME/.config/nvim" ".config/nvim symlink"

echo ""
echo "--- Testing Configuration Files ---"
test_file_exists "$HOME/.config/zsh/.zshrc" ".zshrc exists"
test_file_exists "$HOME/.config/git/config" "git config exists"
test_file_exists "$HOME/.config/tmux/tmux.conf" "tmux.conf exists"
test_file_exists "$HOME/.config/nvim/init.lua" "nvim init.lua exists"

echo ""
echo "--- Testing Core Commands ---"
test_command "git" "git is installed"
test_command "tmux" "tmux is installed"
test_command "nvim" "neovim is installed"
test_command "zsh" "zsh is installed"
test_command "fzf" "fzf is installed"
test_command "rg" "ripgrep is installed"
test_command "fd" "fd is installed" || test_command "fdfind" "fd-find is installed"
test_command "bat" "bat is installed" || test_command "batcat" "batcat is installed"
test_command "jq" "jq is installed"
test_command "tree" "tree is installed"
test_command "gh" "GitHub CLI is installed"
test_command "docker" "Docker is installed"
test_command "node" "Node.js is installed"
test_command "python3" "Python3 is installed"
test_command "go" "Go is installed"
test_command "git-lfs" "git-lfs is installed"
test_command "delta" "git-delta is installed"
test_command "lazygit" "lazygit is installed"

echo ""
echo "--- Testing Commands Execute ---"
test_command_runs "git --version" "git runs"
test_command_runs "tmux -V" "tmux runs"
test_command_runs "nvim --version" "nvim runs"
test_command_runs "zsh --version" "zsh runs"
test_command_runs "fzf --version" "fzf runs"

echo ""
echo "--- Testing Shell Startup ---"
test_command_runs "zsh -ic 'echo OK'" "zsh interactive startup succeeds"

echo ""
echo "--- Testing OS-Specific Setup ---"
if [[ "$OS_TYPE" == "macos" ]]; then
  test_command "brew" "Homebrew is installed"
  test_file_exists "$(pwd)/Brewfile" "Brewfile exists"
elif [[ "$OS_TYPE" == "ubuntu" ]]; then
  test_command "apt-get" "apt-get is available"
  test_file_exists "$(pwd)/packages.ubuntu" "packages.ubuntu exists"
fi

echo ""
echo "======================================"
echo "           Test Summary"
echo "======================================"
echo -e "${GREEN}Passed:${NC}  ${#PASSED_TESTS[@]}"
echo -e "${RED}Failed:${NC}  ${#FAILED_TESTS[@]}"
echo -e "${YELLOW}Skipped:${NC} ${#SKIPPED_TESTS[@]}"
echo ""

if (( ${#FAILED_TESTS[@]} > 0 )); then
  echo "Failed tests:"
  printf '  - %s\n' "${FAILED_TESTS[@]}"
  echo ""
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
