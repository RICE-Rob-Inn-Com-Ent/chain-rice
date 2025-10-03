#!/bin/bash
# ChainRice Development Environment Startup
# Uses Nix to create isolated development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"
}

print_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

print_success() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')] SUCCESS:${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    print_error "Please run this script from the rice-dev root directory"
    exit 1
fi

print_status "🌾 Starting ChainRice Development Environment"
print_status "============================================="

# Check if nix is available
if ! command -v nix &> /dev/null; then
    print_warning "Nix not found, trying nix-portable..."
    
    # Try nix-portable
    NP_DIR="$PWD/.nix-portable"
    mkdir -p "$NP_DIR"
    
    if [ ! -f "$NP_DIR/nix-portable" ]; then
        print_info "Downloading nix-portable..."
        curl -L -o "$NP_DIR/nix-portable" https://github.com/DavHau/nix-portable/releases/download/v010/nix-portable
        chmod +x "$NP_DIR/nix-portable"
    fi
    
    print_info "Using nix-portable..."
    NIX_CMD="$NP_DIR/nix-portable nix"
else
    print_info "Using system nix..."
    NIX_CMD="nix"
fi

# Enter Nix development shell and start ChainRice
print_status "Entering Nix development shell..."
print_info "This will start ChainRice frontend with blockchain and smart contracts"

# Use the development flake
if [ -f "flake-dev.nix" ]; then
    print_info "Using flake-dev.nix for ChainRice development"
    $NIX_CMD --extra-experimental-features 'nix-command flakes' develop -f flake-dev.nix --impure -c "./scripts/start-chainrice.sh"
else
    print_info "Using main flake.nix"
    $NIX_CMD --extra-experimental-features 'nix-command flakes' develop .#monorepo --impure -c "./scripts/start-chainrice.sh"
fi
