#!/bin/bash

# ChainRice Test Runner Script
# This script runs tests for all components of the ChainRice ecosystem

set -e

echo "🧪 Running ChainRice Test Suite..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

print_coverage() {
    echo -e "${PURPLE}[COVERAGE]${NC} $1"
}

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run tests and track results
run_test_suite() {
    local test_name="$1"
    local test_command="$2"
    local test_dir="$3"
    
    print_test "Running $test_name tests..."
    
    if [ -n "$test_dir" ]; then
        cd "$test_dir"
    fi
    
    if eval "$test_command"; then
        print_success "$test_name tests passed"
        ((PASSED_TESTS++))
    else
        print_error "$test_name tests failed"
        ((FAILED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
    
    if [ -n "$test_dir" ]; then
        cd - > /dev/null
    fi
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Start test database and services
print_status "Starting test environment..."
docker-compose -f docker-compose.test.yml up -d postgres redis blockchain

# Wait for services to be ready
print_status "Waiting for test services to be ready..."
sleep 10

# Run blockchain tests
print_status "Running blockchain tests..."
if [ -f "Makefile" ]; then
    run_test_suite "Blockchain" "make test" "."
else
    print_warning "Blockchain tests not found"
fi

# Run backend tests
print_status "Running backend tests..."
if [ -d "backend" ] && [ -f "backend/package.json" ]; then
    run_test_suite "Backend" "npm test" "backend"
else
    print_warning "Backend tests not found"
fi

# Run mobile backend tests
print_status "Running mobile backend tests..."
if [ -d "mobile-backend" ] && [ -f "mobile-backend/package.json" ]; then
    run_test_suite "Mobile Backend" "npm test" "mobile-backend"
else
    print_warning "Mobile backend tests not found"
fi

# Run web frontend tests
print_status "Running web frontend tests..."
if [ -d "web-frontend" ] && [ -f "web-frontend/package.json" ]; then
    run_test_suite "Web Frontend" "npm test" "web-frontend"
else
    print_warning "Web frontend tests not found"
fi

# Run integration tests
print_status "Running integration tests..."
if [ -d "tests" ]; then
    run_test_suite "Integration" "npm test" "tests"
else
    print_warning "Integration tests not found"
fi

# Run E2E tests if available
print_status "Running E2E tests..."
if [ -d "e2e" ]; then
    run_test_suite "E2E" "npm run test:e2e" "e2e"
else
    print_warning "E2E tests not found"
fi

# Generate coverage reports
print_status "Generating coverage reports..."

# Backend coverage
if [ -d "backend" ]; then
    cd backend
    if npm run test:coverage > /dev/null 2>&1; then
        print_coverage "Backend coverage report generated"
    fi
    cd - > /dev/null
fi

# Mobile backend coverage
if [ -d "mobile-backend" ]; then
    cd mobile-backend
    if npm run test:coverage > /dev/null 2>&1; then
        print_coverage "Mobile backend coverage report generated"
    fi
    cd - > /dev/null
fi

# Web frontend coverage
if [ -d "web-frontend" ]; then
    cd web-frontend
    if npm run test:coverage > /dev/null 2>&1; then
        print_coverage "Web frontend coverage report generated"
    fi
    cd - > /dev/null
fi

# Stop test services
print_status "Stopping test environment..."
docker-compose -f docker-compose.test.yml down

# Display test results
echo ""
echo "🧪 Test Results Summary:"
echo "========================"
echo "Total Test Suites: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    print_success "All tests passed! 🎉"
    exit 0
else
    print_error "Some tests failed! ❌"
    exit 1
fi 