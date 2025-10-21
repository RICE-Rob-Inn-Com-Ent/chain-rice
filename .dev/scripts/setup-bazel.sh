#!/bin/bash

# Rice-Mono Bazel Setup Script
# This script installs Bazel and Bazelisk for build automation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Rice-Mono Bazel Setup                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Check if Bazel/Bazelisk is already installed
if command -v bazel &>/dev/null; then
  CURRENT_VERSION=$(bazel version 2>&1 | grep "Build label" | awk '{print $3}' || bazel --version)
  echo -e "${GREEN}✓${NC} Bazel is already installed: ${CURRENT_VERSION}"
  echo
  bazel --version
  exit 0
fi

echo -e "${YELLOW}!${NC} Bazel is not installed"
echo -e "${BLUE}Installing Bazelisk (Bazel version manager)...${NC}"
echo

# Install Bazelisk (recommended over direct Bazel installation)
# Bazelisk automatically uses the correct Bazel version for the project
if command -v pacman &>/dev/null; then
  # Arch Linux
  echo "Using pacman (Arch Linux)..."

  # Try to install from AUR helper if available
  if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm bazelisk
  elif command -v paru &>/dev/null; then
    paru -S --needed --noconfirm bazelisk
  else
    # Install bazelisk manually
    echo -e "${YELLOW}!${NC} No AUR helper found. Installing Bazelisk manually..."
    BAZELISK_VERSION="v1.19.0"
    curl -Lo /tmp/bazelisk "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-amd64"
    chmod +x /tmp/bazelisk
    sudo mv /tmp/bazelisk /usr/local/bin/bazelisk
    sudo ln -sf /usr/local/bin/bazelisk /usr/local/bin/bazel
  fi

elif command -v apt &>/dev/null; then
  # Debian/Ubuntu
  echo "Using apt (Debian/Ubuntu)..."

  # Install dependencies
  sudo apt-get update
  sudo apt-get install -y curl

  # Install Bazelisk
  BAZELISK_VERSION="v1.19.0"
  curl -Lo /tmp/bazelisk "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-amd64"
  chmod +x /tmp/bazelisk
  sudo mv /tmp/bazelisk /usr/local/bin/bazelisk
  sudo ln -sf /usr/local/bin/bazelisk /usr/local/bin/bazel

elif command -v dnf &>/dev/null; then
  # Fedora
  echo "Using dnf (Fedora)..."

  # Install Bazelisk
  BAZELISK_VERSION="v1.19.0"
  curl -Lo /tmp/bazelisk "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-amd64"
  chmod +x /tmp/bazelisk
  sudo mv /tmp/bazelisk /usr/local/bin/bazelisk
  sudo ln -sf /usr/local/bin/bazelisk /usr/local/bin/bazel

else
  echo -e "${RED}✗${NC} Unsupported package manager"
  echo "Please install Bazelisk manually from: https://github.com/bazelbuild/bazelisk"
  exit 1
fi

echo -e "${GREEN}✓${NC} Bazelisk installed"
echo

# Add Bazel to PATH (if not already there)
SHELL_RC="$HOME/.bashrc"
if [ -n "$ZSH_VERSION" ]; then
  SHELL_RC="$HOME/.zshrc"
fi

if ! grep -q "BAZEL_HOME" "$SHELL_RC"; then
  echo
  echo -e "${BLUE}Adding Bazel configuration to ${SHELL_RC}...${NC}"

  cat >>"$SHELL_RC" <<'EOF'

# ============================================================================
# BAZEL CONFIGURATION (Added by rice-mono setup)
# ============================================================================
# Use Bazelisk to manage Bazel versions
export USE_BAZEL_VERSION="7.0.0"

# Bazel user cache
export BAZEL_USER_ROOT="$HOME/.cache/bazel"

# Performance optimizations
export BAZEL_BUILD_OPTS="--jobs=auto --experimental_enable_bzlmod"
EOF

  echo -e "${GREEN}✓${NC} Added Bazel configuration to ${SHELL_RC}"
else
  echo -e "${YELLOW}!${NC} Bazel configuration already exists in ${SHELL_RC}"
fi

# Create .bazelversion file if it doesn't exist
BAZEL_VERSION_FILE="/home/mrDinkelman/rice-mono/.bazelversion"
if [ ! -f "$BAZEL_VERSION_FILE" ]; then
  echo "7.0.0" >"$BAZEL_VERSION_FILE"
  echo -e "${GREEN}✓${NC} Created .bazelversion file (7.0.0)"
fi

# Create WORKSPACE file for backward compatibility
WORKSPACE_FILE="/home/mrDinkelman/rice-mono/WORKSPACE"
if [ ! -f "$WORKSPACE_FILE" ]; then
  cat >"$WORKSPACE_FILE" <<'EOF'
# Rice-Mono Bazel Workspace
#
# This workspace uses Bzlmod (MODULE.bazel) for dependency management.
# This file exists for backward compatibility with tools that expect WORKSPACE.
#
# For the actual build configuration, see MODULE.bazel

workspace(name = "rice_mono")
EOF
  echo -e "${GREEN}✓${NC} Created WORKSPACE file for compatibility"
fi

# Reload environment
export USE_BAZEL_VERSION="7.0.0"

echo
echo -e "${BLUE}Verifying installation...${NC}"

if command -v bazel &>/dev/null; then
  echo -e "${GREEN}✓${NC} Bazel installed successfully"
  echo
  bazel --version
else
  echo -e "${RED}✗${NC} Bazel installation verification failed"
  exit 1
fi

echo
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Setup Complete! ✓              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Restart your terminal or run: ${BLUE}source ${SHELL_RC}${NC}"
echo -e "  2. Restart VS Code/Cursor"
echo -e "  3. Test Bazel: ${BLUE}bazel version${NC}"
echo
echo -e "${BLUE}Build the project:${NC}"
echo -e "  ${CYAN}bazel build //...${NC}         # Build everything"
echo -e "  ${CYAN}bazel test //...${NC}          # Run all tests"
echo -e "  ${CYAN}bazel run //app:main${NC}      # Run an application"
echo
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  ${CYAN}bazel clean${NC}               # Clean build artifacts"
echo -e "  ${CYAN}bazel query //...${NC}         # List all targets"
echo -e "  ${CYAN}bazel build --config=opt${NC}  # Optimized build"
echo
