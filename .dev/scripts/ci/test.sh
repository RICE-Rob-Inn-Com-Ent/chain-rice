#!/bin/bash
# =============================================================================
# TEST SCRIPT - Run Tests in CI/CD Pipeline
# =============================================================================

set -euo pipefail

# Default values
SERVICE_NAME="${SERVICE_NAME:-}"
TEST_TYPE="${TEST_TYPE:-all}"
COVERAGE="${COVERAGE:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

run_unit_tests() {
  log_info "Running unit tests..."

  # Detect test framework and run tests
  if [ -f "package.json" ]; then
    npm test
  elif [ -f "go.mod" ]; then
    go test -v ./...
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    pytest tests/
  elif [ -f "Cargo.toml" ]; then
    cargo test
  else
    log_warning "No test framework detected"
    return 1
  fi

  log_success "Unit tests passed"
}

run_integration_tests() {
  log_info "Running integration tests..."

  if [ -d "tests/integration" ]; then
    if [ -f "package.json" ]; then
      npm run test:integration
    elif [ -f "go.mod" ]; then
      go test -v -tags=integration ./tests/integration/...
    elif [ -f "pyproject.toml" ]; then
      pytest tests/integration/
    fi
    log_success "Integration tests passed"
  else
    log_warning "No integration tests found"
  fi
}

run_e2e_tests() {
  log_info "Running E2E tests..."

  if [ -d "tests/e2e" ]; then
    if [ -f "package.json" ]; then
      npm run test:e2e
    elif [ -f "pyproject.toml" ]; then
      pytest tests/e2e/
    fi
    log_success "E2E tests passed"
  else
    log_warning "No E2E tests found"
  fi
}

generate_coverage() {
  if [ "$COVERAGE" = "true" ]; then
    log_info "Generating coverage report..."

    if [ -f "package.json" ]; then
      npm run test:coverage
    elif [ -f "go.mod" ]; then
      go test -coverprofile=coverage.out ./...
      go tool cover -html=coverage.out -o coverage.html
    elif [ -f "pyproject.toml" ]; then
      pytest --cov=. --cov-report=html --cov-report=xml
    fi

    log_success "Coverage report generated"
  fi
}

# Main execution
case "$TEST_TYPE" in
  unit)
    run_unit_tests
    ;;
  integration)
    run_integration_tests
    ;;
  e2e)
    run_e2e_tests
    ;;
  all)
    run_unit_tests
    run_integration_tests || true
    run_e2e_tests || true
    ;;
  *)
    log_error "Unknown test type: $TEST_TYPE"
    exit 1
    ;;
esac

generate_coverage

log_success "All tests completed successfully"
