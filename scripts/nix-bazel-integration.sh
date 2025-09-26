#!/usr/bin/env bash
# Nix-Bazel Integration Script
# This script provides seamless integration between Nix flakes and Bazel

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLAKE_PATH="."
BAZEL_CONFIG=".bazelrc.nix"

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

# Function to check if Nix is available
check_nix() {
    if ! command -v nix >/dev/null 2>&1; then
        print_error "Nix is not installed or not in PATH"
        print_status "Please install Nix first: https://nixos.org/download.html"
        exit 1
    fi
    print_success "Nix is available"
}

# Function to check if Bazel is available
check_bazel() {
    if ! command -v bazel >/dev/null 2>&1; then
        print_warning "Bazel is not available in current environment"
        print_status "Entering Nix development shell with Bazel..."
        return 1
    fi
    print_success "Bazel is available"
}

# Function to enter Nix development shell
enter_nix_shell() {
    local shell_name="${1:-default}"
    print_status "Entering Nix development shell: $shell_name"
    
    if [ -f "$BAZEL_CONFIG" ]; then
        print_status "Using Bazel configuration: $BAZEL_CONFIG"
        export BAZEL_USE_CPP_ONLY_TOOLCHAIN=1
    fi
    
    exec nix --extra-experimental-features 'nix-command flakes' develop "$FLAKE_PATH#$shell_name" --command "$0" "$@"
}

# Function to build with Nix environment
build_with_nix() {
    local shell_name="${1:-default}"
    local targets="${2:-//...}"
    
    print_status "Building targets '$targets' with Nix shell: $shell_name"
    
    nix --extra-experimental-features 'nix-command flakes' develop "$FLAKE_PATH#$shell_name" --command bazel build $targets
}

# Function to test with Nix environment
test_with_nix() {
    local shell_name="${1:-default}"
    local targets="${2:-//...}"
    
    print_status "Testing targets '$targets' with Nix shell: $shell_name"
    
    nix --extra-experimental-features 'nix-command flakes' develop "$FLAKE_PATH#$shell_name" --command bazel test $targets
}

# Function to run with Nix environment
run_with_nix() {
    local shell_name="${1:-default}"
    local target="${2:-//:dev}"
    
    print_status "Running target '$target' with Nix shell: $shell_name"
    
    nix --extra-experimental-features 'nix-command flakes' develop "$FLAKE_PATH#$shell_name" --command bazel run $target
}

# Function to show available shells
show_shells() {
    print_status "Available Nix development shells:"
    echo ""
    echo "  🔧 Development Tools:"
    echo "    bazel-dev          - Bazel development environment"
    echo "    proto-tools        - Protobuf compilation tools"
    echo ""
    echo "  🤖 AI & Bot Development:"
    echo "    bot-core           - AI models (PyTorch, TensorFlow, JAX, CUDA)"
    echo "    bot-integration    - Bot APIs/SDKs/middleware"
    echo "    bot-julia-models   - Julia simulations/FinTech"
    echo "    bot-finance-reporting - Analytics/reporting/visualization"
    echo ""
    echo "  🏗️ Backend Development:"
    echo "    go-backend         - Go + Cosmos SDK + gRPC"
    echo ""
    echo "  🌉 Connection Bridges:"
    echo "    dotnet-bridge      - .NET to Go backend"
    echo "    beam-bridge        - Elixir/Erlang to Go backend"
    echo "    python-fastapi-bridge - Python FastAPI bridges"
    echo "    jvm-bridge         - Java/Kotlin to Go backend"
    echo "    php-bridge         - PHP to Go backend"
    echo ""
    echo "  ⛓️ Blockchain & Smart Contracts:"
    echo "    rust-cosmos        - Rust + Cosmos SDK"
    echo "    solidity-evm      - Solidity + EVM chains"
    echo ""
    echo "  🎨 Frontend Development:"
    echo "    flutter-dart       - Flutter/Dart mobile"
    echo "    kotlin-android     - Kotlin Android"
    echo "    swift-ios          - Swift iOS/macOS"
    echo "    angular-frontend   - Angular + TypeScript"
    echo "    next-frontend      - Next.js + React + TypeScript"
    echo "    nuxt-frontend      - Nuxt + Vue + TypeScript"
    echo "    ts-shared          - Shared TypeScript tooling"
    echo ""
    echo "  🚀 DevOps & Infrastructure:"
    echo "    ansible            - Ansible automation"
    echo "    k8s                - Kubernetes management"
    echo "    terraform          - Infrastructure as Code"
    echo ""
    echo "  📦 Default:"
    echo "    default            - Basic development environment"
}

# Function to show help
show_help() {
    echo "Nix-Bazel Integration Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  shell [SHELL_NAME]     Enter a Nix development shell"
    echo "  build [SHELL] [TARGETS] Build targets with Nix environment"
    echo "  test [SHELL] [TARGETS]  Test targets with Nix environment"
    echo "  run [SHELL] [TARGET]    Run target with Nix environment"
    echo "  shells                  Show available Nix shells"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 shell bazel-dev     # Enter Bazel development shell"
    echo "  $0 shell go-backend     # Enter Go development shell"
    echo "  $0 build bazel-dev //... # Build all targets with Bazel shell"
    echo "  $0 test python-fastapi-bridge //bots/core/... # Test Python targets"
    echo "  $0 run bazel-dev //:dev # Run development shell target"
    echo ""
    echo "Environment Variables:"
    echo "  FLAKE_PATH             Path to Nix flake (default: .)"
    echo "  BAZEL_CONFIG           Bazel configuration file (default: .bazelrc.nix)"
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "shell")
            local shell_name="${2:-default}"
            check_nix
            enter_nix_shell "$shell_name"
            ;;
        "build")
            local shell_name="${2:-default}"
            local targets="${3:-//...}"
            check_nix
            build_with_nix "$shell_name" "$targets"
            ;;
        "test")
            local shell_name="${2:-default}"
            local targets="${3:-//...}"
            check_nix
            test_with_nix "$shell_name" "$targets"
            ;;
        "run")
            local shell_name="${2:-default}"
            local target="${3:-//:dev}"
            check_nix
            run_with_nix "$shell_name" "$target"
            ;;
        "shells")
            show_shells
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

