#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
  echo ""
  echo -e "${BLUE}======================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}======================================${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${YELLOW}→${NC} $1"
}

if [[ "$OSTYPE" != "darwin"* ]]; then
  print_error "This script is for macOS only"
  echo "Detected OSTYPE: $OSTYPE"
  exit 1
fi

print_header "macOS Dotfiles Tests"

if [[ ! -L "$HOME/.zshenv" ]]; then
  print_info "Setup hasn't been run yet. Running ./setup first..."
  if ./setup; then
    print_success "Setup completed successfully"
  else
    print_error "Setup failed"
    exit 1
  fi
else
  print_info "Setup appears to have been run (symlinks exist)"
fi

print_header "Running Validation Tests"
if ./tests/validate-setup.sh; then
  print_success "All validation tests passed!"
  exit 0
else
  print_error "Some validation tests failed"
  echo ""
  echo "This is normal if some optional packages aren't installed."
  echo "Check the output above to see what's missing."
  exit 1
fi
