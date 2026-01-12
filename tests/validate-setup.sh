#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED_TESTS=()
PASSED_TESTS=()
SKIPPED_TESTS=()
WARNED_TESTS=()

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

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  WARNED_TESTS+=("$1")
}

section() {
  echo ""
  echo -e "${BLUE}--- $1 ---${NC}"
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

test_command_optional() {
  local cmd="$1"
  local description="${2:-command '$cmd' exists}"

  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$description"
    return 0
  else
    warn "$description (optional)"
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

test_dir_exists() {
  local path="$1"
  local description="${2:-$path exists}"

  if [[ -d "$path" ]]; then
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

test_command_output_contains() {
  local cmd="$1"
  local expected="$2"
  local description="${3:-'$cmd' output contains '$expected'}"

  if eval "$cmd" 2>&1 | grep -q "$expected"; then
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

if [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -f /etc/debian_version ]]; then
  OS_TYPE="ubuntu"
else
  OS_TYPE="unknown"
fi

echo ""
echo "Detected OS: $OS_TYPE"

# =============================================================================
section "Symlinks"
# =============================================================================
test_symlink "$HOME/.zshenv" ".zshenv symlink"
test_symlink "$HOME/.config/zsh" ".config/zsh symlink"
test_symlink "$HOME/.config/git" ".config/git symlink"
test_symlink "$HOME/.config/tmux" ".config/tmux symlink"
test_symlink "$HOME/.config/nvim" ".config/nvim symlink"

if [[ "$OS_TYPE" == "macos" ]]; then
  test_symlink "$HOME/.config/wezterm" ".config/wezterm symlink" || true
  test_symlink "$HOME/.config/hammerspoon" ".config/hammerspoon symlink" || true
fi

# =============================================================================
section "Configuration Files Exist"
# =============================================================================
test_file_exists "$HOME/.config/zsh/.zshrc" ".zshrc exists"
test_file_exists "$HOME/.config/zsh/functions.zsh" "functions.zsh exists"
test_file_exists "$HOME/.config/git/config" "git config exists"
test_file_exists "$HOME/.config/tmux/tmux.conf" "tmux.conf exists"
test_file_exists "$HOME/.config/nvim/init.lua" "nvim init.lua exists"

# =============================================================================
section "External Repositories"
# =============================================================================
test_dir_exists "$HOME/.config/tmux/plugins/tpm" "TPM (tmux plugin manager) cloned"
test_file_exists "$HOME/.config/tmux/plugins/tpm/tpm" "TPM executable exists"

# =============================================================================
section "Core Commands"
# =============================================================================
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
test_command "node" "Node.js is installed"
test_command "python3" "Python3 is installed"
test_command "delta" "git-delta is installed"
test_command "lazygit" "lazygit is installed"

# =============================================================================
section "Workflow-Critical Tools (from dev environment)"
# =============================================================================
test_command "yazi" "yazi (file manager) is installed"
test_command "lazydocker" "lazydocker is installed"
test_command "zoxide" "zoxide is installed"
test_command "eza" "eza is installed"
test_command "direnv" "direnv is installed"

# Grove - custom worktree manager (may be cargo-installed or external)
if command -v grove >/dev/null 2>&1; then
  pass "grove (worktree manager) is installed"
else
  warn "grove (worktree manager) not found - install with: cargo install grove-tui"
fi

# =============================================================================
section "Commands Execute Successfully"
# =============================================================================
test_command_runs "git --version" "git runs"
test_command_runs "tmux -V" "tmux runs"
test_command_runs "nvim --version" "nvim runs"
test_command_runs "zsh --version" "zsh runs"
test_command_runs "fzf --version" "fzf runs"
test_command_runs "lazygit --version" "lazygit runs"
test_command_runs "yazi --version" "yazi runs" || true
test_command_runs "zoxide --version" "zoxide runs" || true

# =============================================================================
section "Configuration Validation"
# =============================================================================

# Git config is valid
if git config --list >/dev/null 2>&1; then
  pass "git config parses correctly"
else
  fail "git config has errors"
fi

# Git delta is configured
if git config --get core.pager | grep -q delta 2>/dev/null; then
  pass "git delta is configured as pager"
else
  warn "git delta not configured as pager (check .config/git/config)"
fi

# Tmux config parses (use isolated socket to avoid interfering with running tmux)
test_socket="/tmp/tmux-validate-$$"
if tmux -S "$test_socket" -f "$HOME/.config/tmux/tmux.conf" start-server \; kill-server 2>/dev/null; then
  pass "tmux config parses correctly"
  rm -f "$test_socket" 2>/dev/null || true
else
  rm -f "$test_socket" 2>/dev/null || true
  # Check if it's a TPM issue (plugins not installed)
  if tmux -S "$test_socket" start-server \; kill-server 2>/dev/null; then
    warn "tmux config may have issues (TPM plugins not installed?)"
  else
    fail "tmux config has syntax errors"
  fi
  rm -f "$test_socket" 2>/dev/null || true
fi

# Neovim config loads and can execute commands
# Note: Some plugins (like image.nvim) emit errors in headless mode due to no TTY - that's OK
# We test functionality rather than looking for error strings
if nvim --headless -c 'lua vim.cmd("qall")' 2>/dev/null; then
  pass "nvim config loads successfully"
else
  fail "nvim config failed to load"
fi

# Neovim can run basic Lua after config
if nvim --headless -c 'lua print("nvim-ok")' -c 'qall' 2>&1 | grep -q "nvim-ok"; then
  pass "nvim lua runtime works"
else
  fail "nvim lua runtime has issues"
fi

# Neovim checkhealth basics (just verify it doesn't crash)
if timeout 10 nvim --headless -c 'checkhealth vim.health' -c 'qall' >/dev/null 2>&1; then
  pass "nvim checkhealth runs"
else
  warn "nvim checkhealth had issues (may be OK)"
fi

# =============================================================================
section "Shell Environment"
# =============================================================================

# Zsh interactive startup
if zsh -ic 'exit 0' 2>/dev/null; then
  pass "zsh interactive startup succeeds"
else
  fail "zsh interactive startup fails"
fi

# Zinit is installed
if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git" ]]; then
  pass "zinit plugin manager is installed"
else
  warn "zinit not installed (will auto-install on first zsh launch)"
fi

# Zoxide is initialized in shell
if zsh -ic 'type z' 2>/dev/null | grep -q "function"; then
  pass "zoxide 'z' command available in zsh"
else
  warn "zoxide 'z' not available (zoxide init may not have run)"
fi

# FZF shell integration
if zsh -ic 'type fzf-history-widget' 2>/dev/null | grep -q "function"; then
  pass "fzf shell integration loaded"
else
  warn "fzf shell integration not loaded"
fi

# Critical aliases exist
if zsh -ic 'alias l' 2>/dev/null | grep -q "eza"; then
  pass "alias 'l' -> eza configured"
else
  warn "alias 'l' not found or not using eza"
fi

if zsh -ic 'type wt' 2>/dev/null | grep -q "function"; then
  pass "worktree function 'wt' available"
else
  warn "worktree function 'wt' not found"
fi

if zsh -ic 'type dwt' 2>/dev/null | grep -q "function"; then
  pass "worktree function 'dwt' available"
else
  warn "worktree function 'dwt' not found"
fi

# =============================================================================
section "Tmux Plugins"
# =============================================================================

# Check if TPM plugins directory has content
tpm_plugins_dir="$HOME/.config/tmux/plugins"
if [[ -d "$tpm_plugins_dir" ]]; then
  plugin_count=$(find "$tpm_plugins_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$plugin_count" -gt 1 ]]; then
    pass "tmux plugins installed ($plugin_count plugins)"
  else
    warn "tmux plugins not installed yet (run prefix + I in tmux to install)"
  fi
else
  warn "tmux plugins directory missing"
fi

# =============================================================================
section "OS-Specific Setup"
# =============================================================================
if [[ "$OS_TYPE" == "macos" ]]; then
  test_command "brew" "Homebrew is installed"
  test_file_exists "$(pwd)/Brewfile" "Brewfile exists" || test_file_exists "$HOME/dotfiles/Brewfile" "Brewfile exists"

  # Check for Nerd Font (important for terminal icons)
  if fc-list 2>/dev/null | grep -qi "nerd\|fira.*code\|jetbrains.*mono"; then
    pass "Nerd Font appears to be installed"
  elif [[ -d "$HOME/Library/Fonts" ]] && ls "$HOME/Library/Fonts" 2>/dev/null | grep -qi "nerd\|fira\|jetbrains"; then
    pass "Nerd Font appears to be installed"
  else
    warn "Nerd Font may not be installed (icons may not display correctly)"
  fi

  # WezTerm
  if [[ -d "/Applications/WezTerm.app" ]] || command -v wezterm >/dev/null 2>&1; then
    pass "WezTerm is installed"
  else
    warn "WezTerm not found (terminal emulator)"
  fi

elif [[ "$OS_TYPE" == "ubuntu" ]]; then
  test_command "apt-get" "apt-get is available"
  test_file_exists "$(pwd)/packages.ubuntu" "packages.ubuntu exists" || test_file_exists "$HOME/dotfiles/packages.ubuntu" "packages.ubuntu exists"
fi

# =============================================================================
section "Optional Tools"
# =============================================================================
test_command_optional "docker" "Docker is installed"
test_command_optional "go" "Go is installed"
test_command_optional "cargo" "Rust/Cargo is installed"
test_command_optional "uv" "uv (Python) is installed"
test_command_optional "bun" "Bun is installed"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "======================================"
echo "           Test Summary"
echo "======================================"
echo -e "${GREEN}Passed:${NC}  ${#PASSED_TESTS[@]}"
echo -e "${RED}Failed:${NC}  ${#FAILED_TESTS[@]}"
echo -e "${YELLOW}Warned:${NC}  ${#WARNED_TESTS[@]}"
echo -e "${YELLOW}Skipped:${NC} ${#SKIPPED_TESTS[@]}"
echo ""

if (( ${#FAILED_TESTS[@]} > 0 )); then
  echo -e "${RED}Failed tests:${NC}"
  printf '  - %s\n' "${FAILED_TESTS[@]}"
  echo ""
fi

if (( ${#WARNED_TESTS[@]} > 0 )); then
  echo -e "${YELLOW}Warnings (non-blocking):${NC}"
  printf '  - %s\n' "${WARNED_TESTS[@]}"
  echo ""
fi

if (( ${#FAILED_TESTS[@]} > 0 )); then
  echo -e "${RED}Setup validation failed!${NC}"
  exit 1
else
  echo -e "${GREEN}Setup validation passed!${NC}"
  if (( ${#WARNED_TESTS[@]} > 0 )); then
    echo "(with ${#WARNED_TESTS[@]} warnings - consider addressing these)"
  fi
  exit 0
fi
