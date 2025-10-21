#!/bin/bash

# Rice-Mono Java Setup Script
# This script configures Java environment for development

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Rice-Mono Java Environment Setup    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Check if Java is installed
if command -v java &>/dev/null; then
  echo -e "${GREEN}✓${NC} Java is already installed"
  java -version
  echo
else
  echo -e "${YELLOW}!${NC} Java is not installed"
  echo -e "${BLUE}Installing JDK 17...${NC}"

  if command -v pacman &>/dev/null; then
    echo "Using pacman (Arch Linux)..."
    sudo pacman -S --needed --noconfirm jdk17-openjdk
  elif command -v apt &>/dev/null; then
    echo "Using apt (Debian/Ubuntu)..."
    sudo apt update
    sudo apt install -y openjdk-17-jdk
  elif command -v dnf &>/dev/null; then
    echo "Using dnf (Fedora)..."
    sudo dnf install -y java-17-openjdk-devel
  else
    echo -e "${RED}✗${NC} Unsupported package manager. Please install JDK 17 manually."
    exit 1
  fi
fi

# Detect Java installation path
echo -e "${BLUE}Detecting Java installation...${NC}"

JAVA_PATHS=(
  "/usr/lib/jvm/java-17-openjdk"
  "/usr/lib/jvm/java-17-openjdk-amd64"
  "/usr/lib/jvm/jdk-17"
  "/usr/lib/jvm/java-17"
)

JAVA_HOME_PATH=""
for path in "${JAVA_PATHS[@]}"; do
  if [ -d "$path" ]; then
    JAVA_HOME_PATH="$path"
    break
  fi
done

if [ -z "$JAVA_HOME_PATH" ]; then
  # Try to find it dynamically
  JAVA_HOME_PATH=$(readlink -f $(which java) | sed 's:/bin/java::')
  JAVA_HOME_PATH=$(dirname $(dirname "$JAVA_HOME_PATH"))
fi

if [ -z "$JAVA_HOME_PATH" ]; then
  echo -e "${RED}✗${NC} Could not detect Java installation path"
  echo "Please set JAVA_HOME manually in your .bashrc or .zshrc"
  exit 1
fi

echo -e "${GREEN}✓${NC} Found Java at: ${JAVA_HOME_PATH}"

# Add to .bashrc if not already present
SHELL_RC="$HOME/.bashrc"
if [ -n "$ZSH_VERSION" ]; then
  SHELL_RC="$HOME/.zshrc"
fi

if ! grep -q "JAVA_HOME" "$SHELL_RC"; then
  echo
  echo -e "${BLUE}Adding JAVA_HOME to ${SHELL_RC}...${NC}"

  cat >>"$SHELL_RC" <<EOF

# ============================================================================
# JAVA CONFIGURATION (Added by rice-mono setup)
# ============================================================================
export JAVA_HOME="${JAVA_HOME_PATH}"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF

  echo -e "${GREEN}✓${NC} Added JAVA_HOME to ${SHELL_RC}"
else
  echo -e "${YELLOW}!${NC} JAVA_HOME already exists in ${SHELL_RC}"
fi

# Update VS Code settings
VSCODE_SETTINGS="/home/mrDinkelman/rice-mono/.vscode/settings.json"
if [ -f "$VSCODE_SETTINGS" ]; then
  echo
  echo -e "${BLUE}Updating VS Code settings...${NC}"

  # Backup settings
  cp "$VSCODE_SETTINGS" "${VSCODE_SETTINGS}.backup"

  # Update Java home paths (using sed)
  sed -i "s|\"java.home\": \".*\"|\"java.home\": \"${JAVA_HOME_PATH}\"|g" "$VSCODE_SETTINGS"
  sed -i "s|\"java.jdt.ls.java.home\": \".*\"|\"java.jdt.ls.java.home\": \"${JAVA_HOME_PATH}\"|g" "$VSCODE_SETTINGS"

  echo -e "${GREEN}✓${NC} Updated VS Code Java settings"
fi

echo
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Setup Complete! ✓              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Restart your terminal or run: ${BLUE}source ${SHELL_RC}${NC}"
echo -e "  2. Restart VS Code/Cursor"
echo -e "  3. Gradle and Kotlin Language Servers should now work!"
echo
echo -e "${BLUE}Verify installation:${NC}"
echo -e "  java -version"
echo -e "  echo \$JAVA_HOME"
echo
