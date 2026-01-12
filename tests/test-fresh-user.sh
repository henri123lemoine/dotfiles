#!/bin/bash
set -euo pipefail

# Test dotfiles setup with a fresh macOS user account
# Creates a temporary user, runs setup, validates, then cleans up

TEST_USER="dotfilestest"
TEST_UID="599"  # Use a UID in the 500-599 range (non-standard, easy to identify)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="/tmp/dotfiles-fresh-test-$$"
INSTALL_HOMEBREW="${INSTALL_HOMEBREW:-0}"  # Set to 1 to install Homebrew (slow)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[test]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; }
success() { echo -e "${GREEN}[success]${NC} $*"; }

cleanup() {
    log "Cleaning up..."

    # Kill any processes owned by test user
    if id "$TEST_USER" &>/dev/null; then
        sudo pkill -u "$TEST_USER" 2>/dev/null || true
        sleep 1
        sudo pkill -9 -u "$TEST_USER" 2>/dev/null || true
    fi

    # Delete the user and their home directory
    if id "$TEST_USER" &>/dev/null; then
        log "Deleting user $TEST_USER..."
        sudo dscl . -delete /Users/"$TEST_USER" 2>/dev/null || true
        sudo rm -rf /Users/"$TEST_USER" 2>/dev/null || true
    fi

    # Remove from admin group if added
    sudo dseditgroup -o edit -d "$TEST_USER" -t user admin 2>/dev/null || true

    # Remove sudoers file
    sudo rm -f "/etc/sudoers.d/$TEST_USER" 2>/dev/null || true

    log "Cleanup complete"
}

# Ensure cleanup runs on exit
trap cleanup EXIT

echo "======================================"
echo "  Fresh User Dotfiles Test"
echo "======================================"
echo ""
echo "This script will:"
echo "  1. Create a temporary macOS user '$TEST_USER'"
echo "  2. Clone/copy dotfiles to that user's home"
echo "  3. Run ./setup as that user"
echo "  4. Run validation tests"
echo "  5. Clean up (delete the user)"
echo ""
echo "Output will be saved to: $OUTPUT_DIR/"
echo ""

if [[ "$INSTALL_HOMEBREW" == "1" ]]; then
    warn "INSTALL_HOMEBREW=1: Will attempt to install Homebrew (slow, ~5-10 min)"
else
    log "Skipping Homebrew install (set INSTALL_HOMEBREW=1 to enable)"
fi

echo ""
read -p "Press Enter to continue (Ctrl+C to abort)..."
echo ""

# Check we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script only works on macOS"
    exit 1
fi

# Check for existing test user
if id "$TEST_USER" &>/dev/null; then
    warn "User $TEST_USER already exists, cleaning up first..."
    cleanup
    trap cleanup EXIT  # Re-register trap
fi

mkdir -p "$OUTPUT_DIR"

# Create the test user
log "Creating user $TEST_USER..."
sudo dscl . -create /Users/"$TEST_USER"
sudo dscl . -create /Users/"$TEST_USER" UserShell /bin/zsh
sudo dscl . -create /Users/"$TEST_USER" RealName "Dotfiles Test"
sudo dscl . -create /Users/"$TEST_USER" UniqueID "$TEST_UID"
sudo dscl . -create /Users/"$TEST_USER" PrimaryGroupID 20  # staff group
sudo dscl . -create /Users/"$TEST_USER" NFSHomeDirectory /Users/"$TEST_USER"

# Set a password for the test user (required for sudo to work)
# Using a simple password since this is a temporary test user
TEST_PASSWORD="testpass123"
sudo dscl . -passwd /Users/"$TEST_USER" "$TEST_PASSWORD"

# Create home directory
sudo mkdir -p /Users/"$TEST_USER"
sudo chown -R "$TEST_USER":staff /Users/"$TEST_USER"

# Add to admin group (needed for some installations)
sudo dseditgroup -o edit -a "$TEST_USER" -t user admin

# Add NOPASSWD sudo access for the test user (needed for Homebrew install)
SUDOERS_FILE="/etc/sudoers.d/$TEST_USER"
echo "$TEST_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" >/dev/null
sudo chmod 440 "$SUDOERS_FILE"

success "User $TEST_USER created (password: $TEST_PASSWORD)"

# Clone dotfiles from GitHub (avoids git ownership issues with local clone)
log "Cloning dotfiles from GitHub..."
REMOTE_URL=$(git -C "$SCRIPT_DIR" remote get-url origin 2>/dev/null || echo "https://github.com/henri123lemoine/dotfiles.git")
sudo -u "$TEST_USER" HOME="/Users/$TEST_USER" git clone "$REMOTE_URL" /Users/"$TEST_USER"/dotfiles 2>&1 | tee "$OUTPUT_DIR/git-clone.log"

# Skip submodules - private repos won't auth and rsync will copy local content anyway

# Copy any uncommitted changes from local repo (so we test current state, not just what's on GitHub)
# Exclude: .git, dotfiles-private (test public-only setup), and external repos that setup will clone
log "Syncing local changes (public dotfiles only)..."
RSYNC_EXCLUDES="--exclude=.git --exclude=dotfiles-private"
# Read external_repos.txt and exclude those paths
if [[ -f "$SCRIPT_DIR/external_repos.txt" ]]; then
    while IFS='|' read -r rel_path _ _ || [[ -n "$rel_path" ]]; do
        [[ -z "$rel_path" || "$rel_path" =~ ^[[:space:]]*# ]] && continue
        rel_path="${rel_path#"${rel_path%%[![:space:]]*}"}"  # trim leading whitespace
        RSYNC_EXCLUDES="$RSYNC_EXCLUDES --exclude=$rel_path"
    done < "$SCRIPT_DIR/external_repos.txt"
fi
eval sudo rsync -av $RSYNC_EXCLUDES "$SCRIPT_DIR/" /Users/"$TEST_USER"/dotfiles/ 2>&1 | tail -1
sudo chown -R "$TEST_USER":staff /Users/"$TEST_USER"/dotfiles

success "Dotfiles cloned and synced"

# Install Homebrew if requested
if [[ "$INSTALL_HOMEBREW" == "1" ]]; then
    log "Installing Homebrew (this takes a while)..."
    # Homebrew install script - must set HOME explicitly
    sudo -u "$TEST_USER" HOME="/Users/$TEST_USER" bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' 2>&1 | tee "$OUTPUT_DIR/homebrew-install.log"

    # Add brew to path for subsequent commands
    if [[ -f /opt/homebrew/bin/brew ]]; then
        BREW_PREFIX="/opt/homebrew"
    else
        BREW_PREFIX="/usr/local"
    fi
    success "Homebrew installed"
else
    log "Skipping Homebrew installation"
    # Check if Homebrew exists system-wide (it might from your main user)
    if command -v brew &>/dev/null; then
        warn "System Homebrew exists - test user may be able to use it"
        BREW_PREFIX="$(brew --prefix)"
    else
        BREW_PREFIX=""
        warn "No Homebrew available - package installation will fail"
    fi
fi

# Run setup script
log "Running dotfiles setup..."
echo ""
echo "======================================" | tee "$OUTPUT_DIR/setup.log"
echo "  Setup Script Output" | tee -a "$OUTPUT_DIR/setup.log"
echo "======================================" | tee -a "$OUTPUT_DIR/setup.log"

# Build the setup command with proper PATH and HOME
setup_cmd="cd /Users/$TEST_USER/dotfiles && ./setup"
if [[ -n "$BREW_PREFIX" ]]; then
    setup_cmd="export PATH=\"$BREW_PREFIX/bin:\$PATH\" && $setup_cmd"
fi

# Run setup (allow failure so we can see what went wrong)
set +e
sudo -u "$TEST_USER" HOME="/Users/$TEST_USER" bash -c "$setup_cmd" 2>&1 | tee -a "$OUTPUT_DIR/setup.log"
setup_status=$?
set -e

echo ""
if [[ $setup_status -eq 0 ]]; then
    success "Setup completed successfully"
else
    warn "Setup exited with status $setup_status"
fi

# Run validation tests
log "Running validation tests..."
echo ""
echo "======================================" | tee "$OUTPUT_DIR/validate.log"
echo "  Validation Test Output" | tee -a "$OUTPUT_DIR/validate.log"
echo "======================================" | tee -a "$OUTPUT_DIR/validate.log"

validate_cmd="cd /Users/$TEST_USER/dotfiles && ./tests/validate-setup.sh"
if [[ -n "$BREW_PREFIX" ]]; then
    validate_cmd="export PATH=\"$BREW_PREFIX/bin:\$PATH\" && $validate_cmd"
fi

set +e
sudo -u "$TEST_USER" HOME="/Users/$TEST_USER" bash -c "$validate_cmd" 2>&1 | tee -a "$OUTPUT_DIR/validate.log"
validate_status=$?
set -e

echo ""
if [[ $validate_status -eq 0 ]]; then
    success "Validation passed"
else
    warn "Validation failed with status $validate_status"
fi

# Summary
echo ""
echo "======================================"
echo "  Test Complete"
echo "======================================"
echo ""
echo "Results saved to: $OUTPUT_DIR/"
echo "  - git-clone.log: Dotfiles clone output"
if [[ "$INSTALL_HOMEBREW" == "1" ]]; then
    echo "  - homebrew-install.log: Homebrew installation"
fi
echo "  - setup.log: Setup script output"
echo "  - validate.log: Validation test results"
echo ""

if [[ $setup_status -ne 0 ]] || [[ $validate_status -ne 0 ]]; then
    error "Issues detected! Check the logs above."
    echo ""
    echo "Quick view of failures:"
    echo "---"
    grep -E "^(✗|Failed|Error|error:)" "$OUTPUT_DIR/setup.log" "$OUTPUT_DIR/validate.log" 2>/dev/null || echo "(no obvious errors found in grep)"
    echo "---"
fi

echo ""
log "Cleanup will run automatically..."
