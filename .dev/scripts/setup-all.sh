#!/bin/bash

# Rice-Mono Complete Development Environment Setup
# This script installs all required dependencies

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear

echo -e "${PURPLE}"
cat <<"EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     ██████╗ ██╗ ██████╗███████╗    ███╗   ███╗ ██████╗      ║
║     ██╔══██╗██║██╔════╝██╔════╝    ████╗ ████║██╔═══██╗     ║
║     ██████╔╝██║██║     █████╗      ██╔████╔██║██║   ██║     ║
║     ██╔══██╗██║██║     ██╔══╝      ██║╚██╔╝██║██║   ██║     ║
║     ██║  ██║██║╚██████╗███████╗    ██║ ╚═╝ ██║╚██████╔╝     ║
║     ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝    ╚═╝     ╚═╝ ╚═════╝      ║
║                                                               ║
║          Complete Development Environment Setup              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo
echo -e "${CYAN}This script will install:${NC}"
echo -e "  ${GREEN}✓${NC} Java JDK 17 (for Android/Kotlin/Gradle)"
echo -e "  ${GREEN}✓${NC} Node.js 20.x LTS (for frontend/SonarQube)"
echo -e "  ${GREEN}✓${NC} Bazel/Bazelisk (for monorepo build system)"
echo -e "  ${GREEN}✓${NC} kind (Kubernetes in Docker)"
echo -e "  ${GREEN}✓${NC} Development tools and dependencies"
echo

read -p "$(echo -e ${YELLOW}Continue with installation? [Y/n]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
  echo "Installation cancelled."
  exit 0
fi

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 1/4: Installing Java JDK 17${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

if [ -f "$SCRIPT_DIR/setup-java.sh" ]; then
  bash "$SCRIPT_DIR/setup-java.sh"
else
  echo -e "${RED}✗${NC} setup-java.sh not found"
  exit 1
fi

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 2/4: Installing Node.js 20.x LTS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

if [ -f "$SCRIPT_DIR/setup-nodejs.sh" ]; then
  bash "$SCRIPT_DIR/setup-nodejs.sh"
else
  echo -e "${RED}✗${NC} setup-nodejs.sh not found"
  exit 1
fi

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 3/5: Installing Bazel (Build System)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

if [ -f "$SCRIPT_DIR/setup-bazel.sh" ]; then
  bash "$SCRIPT_DIR/setup-bazel.sh"
else
  echo -e "${RED}✗${NC} setup-bazel.sh not found"
  exit 1
fi

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 4/5: Installing kind (Kubernetes in Docker)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

if command -v kind &>/dev/null; then
  echo -e "${GREEN}✓${NC} kind is already installed"
  kind --version
else
  echo -e "${BLUE}Installing kind...${NC}"

  if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm kind
  else
    # Download binary
    curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
    chmod +x /tmp/kind
    sudo mv /tmp/kind /usr/local/bin/kind
  fi

  echo -e "${GREEN}✓${NC} kind installed"
  kind --version
fi

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 5/5: Installing additional development tools${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Install kubectl if not present
if ! command -v kubectl &>/dev/null; then
  echo -e "${BLUE}Installing kubectl...${NC}"
  if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm kubectl
  else
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
  fi
  echo -e "${GREEN}✓${NC} kubectl installed"
else
  echo -e "${GREEN}✓${NC} kubectl already installed"
fi

# Install helm if not present
if ! command -v helm &>/dev/null; then
  echo -e "${BLUE}Installing helm...${NC}"
  if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm helm
  else
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
  echo -e "${GREEN}✓${NC} helm installed"
else
  echo -e "${GREEN}✓${NC} helm already installed"
fi

# Install docker if not present
if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}!${NC} Docker not found. kind requires Docker to be installed."
  echo -e "${BLUE}Please install Docker manually:${NC}"
  echo -e "  Arch Linux: ${CYAN}sudo pacman -S docker${NC}"
  echo -e "  Then enable: ${CYAN}sudo systemctl enable --now docker${NC}"
fi

echo
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║             🎉  Setup Complete!  🎉                       ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${CYAN}Installed components:${NC}"
echo

# Show versions
if command -v java &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Java:     $(java -version 2>&1 | head -n 1)"
fi

if command -v node &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Node.js:  $(node --version)"
fi

if command -v npm &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} npm:      $(npm --version)"
fi

if command -v bazel &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Bazel:    $(bazel --version 2>&1 | head -n 1)"
fi

if command -v kind &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} kind:     $(kind --version)"
fi

if command -v kubectl &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} kubectl:  $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

if command -v helm &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} helm:     $(helm version --short)"
fi

echo
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  IMPORTANT: Next Steps${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "  ${CYAN}1.${NC} Restart your terminal or run:"
echo -e "     ${BLUE}source ~/.bashrc${NC}"
echo
echo -e "  ${CYAN}2.${NC} Restart VS Code/Cursor for Language Servers to work"
echo
echo -e "  ${CYAN}3.${NC} Verify installations:"
echo -e "     ${BLUE}java -version${NC}"
echo -e "     ${BLUE}node --version${NC}"
echo -e "     ${BLUE}echo \$JAVA_HOME${NC}"
echo
echo -e "  ${CYAN}4.${NC} Optional - Create a kind cluster:"
echo -e "     ${BLUE}kind create cluster --name rice-mono${NC}"
echo
echo -e "  ${CYAN}5.${NC} Optional - Install Flutter SDK (for mobile development):"
echo -e "     ${BLUE}./.dev/scripts/setup-flutter.sh${NC}"
echo
echo -e "${GREEN}Happy coding! 🚀${NC}"
echo
