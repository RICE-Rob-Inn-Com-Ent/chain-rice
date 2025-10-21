#!/bin/bash

# Rice-Mono Flutter SDK Setup Script
# This script installs Flutter SDK for mobile development

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Rice-Mono Flutter SDK Setup         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Check if Flutter is already installed
if command -v flutter &>/dev/null; then
  CURRENT_VERSION=$(flutter --version 2>/dev/null | head -n 1 | awk '{print $2}')
  echo -e "${GREEN}✓${NC} Flutter is already installed: ${CURRENT_VERSION}"
  echo
  flutter --version
  exit 0
fi

FLUTTER_INSTALL_DIR="/opt/flutter"
FLUTTER_CHANNEL="stable"

echo -e "${YELLOW}!${NC} Flutter SDK is not installed"
echo -e "${BLUE}Installing Flutter ${FLUTTER_CHANNEL} channel...${NC}"
echo

# Check dependencies
echo -e "${BLUE}Checking dependencies...${NC}"

MISSING_DEPS=()
for dep in git curl unzip xz; do
  if ! command -v $dep &>/dev/null; then
    MISSING_DEPS+=("$dep")
  fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
  echo -e "${YELLOW}!${NC} Missing dependencies: ${MISSING_DEPS[*]}"
  echo -e "${BLUE}Installing dependencies...${NC}"

  if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm git curl unzip xz
  elif command -v apt &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y git curl unzip xz-utils
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y git curl unzip xz
  else
    echo -e "${RED}✗${NC} Unsupported package manager. Please install: ${MISSING_DEPS[*]}"
    exit 1
  fi
fi

echo -e "${GREEN}✓${NC} Dependencies installed"
echo

# Download Flutter SDK
echo -e "${BLUE}Downloading Flutter SDK...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"
echo

# Use /opt/flutter for system-wide installation
sudo mkdir -p /opt
cd /opt

if [ -d "flutter" ]; then
  echo -e "${YELLOW}!${NC} Flutter directory exists, removing old installation..."
  sudo rm -rf flutter
fi

# Clone Flutter repository
sudo git clone https://github.com/flutter/flutter.git -b ${FLUTTER_CHANNEL} --depth 1

echo -e "${GREEN}✓${NC} Flutter SDK downloaded"
echo

# Set permissions
sudo chown -R $USER:$USER /opt/flutter

# Add Flutter to PATH
SHELL_RC="$HOME/.bashrc"
if [ -n "$ZSH_VERSION" ]; then
  SHELL_RC="$HOME/.zshrc"
fi

if ! grep -q "FLUTTER_HOME" "$SHELL_RC"; then
  echo
  echo -e "${BLUE}Adding Flutter to PATH in ${SHELL_RC}...${NC}"

  cat >>"$SHELL_RC" <<'EOF'

# ============================================================================
# FLUTTER CONFIGURATION (Added by rice-mono setup)
# ============================================================================
export FLUTTER_HOME="/opt/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"
export PATH="$HOME/.pub-cache/bin:$PATH"
EOF

  echo -e "${GREEN}✓${NC} Added Flutter to ${SHELL_RC}"
else
  echo -e "${YELLOW}!${NC} Flutter already exists in ${SHELL_RC}"
fi

# Load Flutter into current session
export FLUTTER_HOME="/opt/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"

# Run flutter doctor to complete installation
echo
echo -e "${BLUE}Completing Flutter setup...${NC}"
flutter precache
flutter config --no-analytics
flutter doctor

# Update VS Code settings
VSCODE_SETTINGS="/home/mrDinkelman/rice-mono/.vscode/settings.json"
if [ -f "$VSCODE_SETTINGS" ]; then
  echo
  echo -e "${BLUE}Updating VS Code settings...${NC}"

  # Backup settings
  cp "$VSCODE_SETTINGS" "${VSCODE_SETTINGS}.backup-flutter"

  # Update Flutter SDK path
  if grep -q "dart.flutterSdkPath" "$VSCODE_SETTINGS"; then
    sed -i "s|\"dart.flutterSdkPath\": \".*\"|\"dart.flutterSdkPath\": \"/opt/flutter\"|g" "$VSCODE_SETTINGS"
    echo -e "${GREEN}✓${NC} Updated VS Code Flutter SDK path"
  fi
fi

echo
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Setup Complete! ✓              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo

# Show Flutter version
if command -v flutter &>/dev/null; then
  echo -e "${GREEN}✓${NC} Flutter installed successfully"
  echo
  flutter --version
  echo
else
  echo -e "${RED}✗${NC} Flutter installation verification failed"
  exit 1
fi

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Restart your terminal or run: ${BLUE}source ${SHELL_RC}${NC}"
echo -e "  2. Restart VS Code/Cursor"
echo -e "  3. Run: ${BLUE}flutter doctor${NC} to check for additional requirements"
echo
echo -e "${BLUE}Optional - Install Android/iOS tools:${NC}"
echo -e "  ${CYAN}Android Studio${NC} - for Android development"
echo -e "  ${CYAN}Xcode${NC} - for iOS development (macOS only)"
echo
echo -e "${BLUE}Verify installation:${NC}"
echo -e "  flutter --version"
echo -e "  flutter doctor"
echo
