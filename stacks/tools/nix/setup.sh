#!/usr/bin/env bash

# ChainRice Nix Development Environment Setup Script
# This script helps you get started with the ChainRice development environment

set -e

echo "🌾 ChainRice Nix Development Environment Setup"
echo "=============================================="
echo ""

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo "❌ Nix is not installed. Please install Nix first:"
    echo "   curl -L https://nixos.org/nix/install | sh"
    exit 1
fi

# Check if flakes are enabled
if ! nix flake --help &> /dev/null; then
    echo "⚠️  Nix flakes are not enabled. Please enable them in your Nix configuration."
    echo "   Add this to ~/.config/nix/nix.conf:"
    echo "   experimental-features = nix-command flakes"
    exit 1
fi

echo "✅ Nix with flakes support detected"
echo ""

# Check project structure
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "📁 Project root: $PROJECT_ROOT"

# Validate project structure
required_dirs=(
    "backend/go"
    "frontend/react"
    "frontend/next"
    "contracts/rust"
    "functions/julia"
    "infrastructure/nix"
)

missing_dirs=()
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$PROJECT_ROOT/$dir" ]; then
        missing_dirs+=("$dir")
    fi
done

if [ ${#missing_dirs[@]} -gt 0 ]; then
    echo "⚠️  Some expected directories are missing:"
    for dir in "${missing_dirs[@]}"; do
        echo "   • $dir"
    done
    echo ""
    echo "Creating missing directories..."
    for dir in "${missing_dirs[@]}"; do
        mkdir -p "$PROJECT_ROOT/$dir"
        echo "   ✅ Created $dir"
    done
fi

echo ""
echo "🔧 Setting up development environment..."

# Change to the Nix directory
cd "$PROJECT_ROOT/infrastructure/nix"

# Update flake inputs
echo "📦 Updating Nix flake inputs..."
nix flake update

# Build the development shell to cache packages
echo "🏗️  Building development environment (this may take a while on first run)..."
nix develop --command echo "Development environment ready!"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Available development environments:"
echo "   • nix develop                # Complete environment (all stacks)"
echo "   • nix develop .#go          # Go development"
echo "   • nix develop .#react       # React frontend"
echo "   • nix develop .#nextjs      # Next.js full-stack"
echo "   • nix develop .#rust        # Rust smart contracts"
echo "   • nix develop .#julia       # Julia functions"
echo "   • nix develop .#python      # Python backend"
echo "   • nix develop .#infra       # Infrastructure tools"
echo ""
echo "🚀 Quick start commands:"
echo "   • make help                 # Show all available commands"
echo "   • make dev                  # Enter complete development environment"
echo "   • make install              # Install all dependencies"
echo "   • make build                # Build all components"
echo "   • make test                 # Run all tests"
echo ""
echo "📚 Documentation:"
echo "   • README.md                 # Detailed documentation"
echo "   • make info                 # Environment information"
echo ""

# Check for direnv
if command -v direnv &> /dev/null; then
    echo "💡 Tip: You have direnv installed! Run 'direnv allow' to auto-load the environment."
else
    echo "💡 Tip: Install direnv for automatic environment loading:"
    echo "   https://direnv.net/docs/installation.html"
fi

echo ""
echo "🌾 Happy coding with ChainRice! ✨"