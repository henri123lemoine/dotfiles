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

if ! command -v docker >/dev/null 2>&1; then
  print_error "Docker is not installed or not in PATH"
  echo "Please install Docker to run the tests"
  exit 1
fi

OS_TO_TEST="${1:-all}"
VALID_OS=("ubuntu" "all")

if [[ ! " ${VALID_OS[@]} " =~ " ${OS_TO_TEST} " ]]; then
  echo "Usage: $0 [ubuntu|all]"
  echo ""
  echo "Available test targets:"
  echo "  ubuntu - Test on Ubuntu 22.04"
  echo "  all    - Test on all supported OS (default)"
  echo ""
  echo "Note: macOS testing in Docker is not supported."
  echo "      For macOS, run './setup' and './tests/validate-setup.sh' locally."
  exit 1
fi

FAILED_TESTS=()
PASSED_TESTS=()

test_os() {
  local os_name="$1"
  local dockerfile="$2"

  print_header "Testing on $os_name"

  print_info "Building Docker image..."
  if docker build -f "$dockerfile" -t "dotfiles-test-$os_name" . 2>&1; then
    print_success "Docker image built successfully"
  else
    print_error "Failed to build Docker image"
    echo "Run 'docker build -f $dockerfile -t dotfiles-test-$os_name .' to see full error"
    FAILED_TESTS+=("$os_name: image build")
    return 1
  fi

  print_info "Running setup and validation tests..."
  if docker run --rm "dotfiles-test-$os_name" 2>&1; then
    print_success "$os_name tests passed"
    PASSED_TESTS+=("$os_name")
    return 0
  else
    print_error "$os_name tests failed"
    echo "Run 'docker run --rm dotfiles-test-$os_name' to see full error"
    FAILED_TESTS+=("$os_name: validation")
    return 1
  fi
}

if [[ "$OS_TO_TEST" == "ubuntu" ]] || [[ "$OS_TO_TEST" == "all" ]]; then
  test_os "ubuntu" "tests/Dockerfile.ubuntu"
fi

# Future OS support can be added here:
# if [[ "$OS_TO_TEST" == "fedora" ]] || [[ "$OS_TO_TEST" == "all" ]]; then
#   test_os "fedora" "tests/Dockerfile.fedora"
# fi

print_header "Test Summary"

if (( ${#PASSED_TESTS[@]} > 0 )); then
  echo -e "${GREEN}Passed (${#PASSED_TESTS[@]}):${NC}"
  printf '  ✓ %s\n' "${PASSED_TESTS[@]}"
  echo ""
fi

if (( ${#FAILED_TESTS[@]} > 0 )); then
  echo -e "${RED}Failed (${#FAILED_TESTS[@]}):${NC}"
  printf '  ✗ %s\n' "${FAILED_TESTS[@]}"
  echo ""
  exit 1
else
  print_success "All tests passed!"
  exit 0
fi
