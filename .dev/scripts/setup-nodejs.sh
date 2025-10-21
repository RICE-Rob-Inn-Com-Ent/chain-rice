#!/bin/bash

# Rice-Mono Node.js Setup Script
# This script installs Node.js 20.x LTS for development

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Rice-Mono Node.js Environment Setup ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Check if Node.js is already installed
if command -v node &>/dev/null; then
  CURRENT_VERSION=$(node --version | sed 's/v//')
  MAJOR_VERSION=$(echo "$CURRENT_VERSION" | cut -d. -f1)

  if [ "$MAJOR_VERSION" -ge 20 ]; then
    echo -e "${GREEN}✓${NC} Node.js ${CURRENT_VERSION} is already installed (>= 20.x)"
    echo
    node --version
    npm --version
    exit 0
  else
    echo -e "${YELLOW}!${NC} Node.js ${CURRENT_VERSION} is installed but version < 20.x"
    echo -e "${BLUE}Upgrading to Node.js 20.x LTS...${NC}"
  fi
else
  echo -e "${YELLOW}!${NC} Node.js is not installed"
  echo -e "${BLUE}Installing Node.js 20.x LTS...${NC}"
fi

echo

# Install Node.js based on package manager
if command -v pacman &>/dev/null; then
  echo "Using pacman (Arch Linux)..."
  echo

  # Check if nodejs package exists
  if pacman -Ss nodejs | grep -q "extra/nodejs"; then
    sudo pacman -S --needed --noconfirm nodejs npm
    echo -e "${GREEN}✓${NC} Node.js installed via pacman"
  else
    echo -e "${RED}✗${NC} nodejs package not found in repositories"
    echo "Falling back to nvm installation..."
    USE_NVM=true
  fi

elif command -v apt &>/dev/null; then
  echo "Using apt (Debian/Ubuntu)..."
  echo

  # Install Node.js 20.x from NodeSource
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo -e "${GREEN}✓${NC} Node.js installed via apt"

elif command -v dnf &>/dev/null; then
  echo "Using dnf (Fedora)..."
  echo

  # Install Node.js 20.x
  sudo dnf install -y nodejs npm
  echo -e "${GREEN}✓${NC} Node.js installed via dnf"

else
  echo -e "${YELLOW}!${NC} Unsupported package manager"
  echo "Will install using nvm..."
  USE_NVM=true
fi

# Fallback to nvm if needed
if [ "$USE_NVM" = true ]; then
  echo
  echo -e "${BLUE}Installing nvm (Node Version Manager)...${NC}"

  # Install nvm
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

  # Load nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Install Node.js 20 LTS
  nvm install 20
  nvm use 20
  nvm alias default 20

  echo -e "${GREEN}✓${NC} Node.js installed via nvm"

  # Add nvm to shell config
  SHELL_RC="$HOME/.bashrc"
  if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
  fi

  if ! grep -q "NVM_DIR" "$SHELL_RC"; then
    cat >>"$SHELL_RC" <<'EOF'

# ============================================================================
# NVM CONFIGURATION (Added by rice-mono setup)
# ============================================================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Load nvm bash_completion
EOF
    echo -e "${GREEN}✓${NC} Added nvm to ${SHELL_RC}"
  fi
fi

echo
echo -e "${BLUE}Verifying installation...${NC}"

# Reload environment
export PATH="$PATH:$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node/ 2>/dev/null | tail -1)/bin" 2>/dev/null || true

if command -v node &>/dev/null; then
  NODE_VERSION=$(node --version)
  NPM_VERSION=$(npm --version)

  echo -e "${GREEN}✓${NC} Node.js ${NODE_VERSION}"
  echo -e "${GREEN}✓${NC} npm ${NPM_VERSION}"

  # Check version meets requirement
  MAJOR_VERSION=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
  MINOR_VERSION=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f2)

  if [ "$MAJOR_VERSION" -ge 20 ] && [ "$MINOR_VERSION" -ge 12 ]; then
    echo -e "${GREEN}✓${NC} Version meets SonarQube requirement (>= 20.12.0)"
  elif [ "$MAJOR_VERSION" -ge 20 ]; then
    echo -e "${YELLOW}!${NC} Version is 20.x but might be < 20.12.0"
    echo -e "${YELLOW}!${NC} Consider updating: ${BLUE}nvm install 20 --reinstall-packages-from=current${NC}"
  else
    echo -e "${RED}✗${NC} Version does not meet requirement (need >= 20.12.0)"
  fi
else
  echo -e "${RED}✗${NC} Node.js installation verification failed"
  exit 1
fi

# Install global packages commonly used in the project
echo
echo -e "${BLUE}Installing essential global packages...${NC}"

# Use sudo for global installation to avoid EACCES errors
if sudo npm install -g pnpm yarn typescript ts-node @types/node 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Installed: pnpm, yarn, typescript, ts-node"
else
  echo -e "${YELLOW}!${NC} Could not install global packages (not critical)"
  echo -e "${BLUE}You can install them later with:${NC}"
  echo -e "  sudo npm install -g pnpm yarn typescript ts-node @types/node"
fi

echo
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Setup Complete! ✓              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Restart your terminal or run: ${BLUE}source ~/.bashrc${NC}"
echo -e "  2. Restart VS Code/Cursor"
echo -e "  3. SonarQube should now work!"
echo
echo -e "${BLUE}Verify installation:${NC}"
echo -e "  node --version"
echo -e "  npm --version"
echo
