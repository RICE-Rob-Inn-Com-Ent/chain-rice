#!/usr/bin/env bash
# ==============================================================================
# DOCKER INSTALLATION SCRIPT FOR ARCH LINUX
# ==============================================================================
# Installs Docker, Docker Compose, and related tools
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          DOCKER INSTALLATION FOR ARCH LINUX                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}✗ Please don't run this script as root. Run as your normal user.${NC}"
    echo -e "${YELLOW}  The script will use sudo when needed.${NC}"
    exit 1
fi

# Check if on Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${YELLOW}⚠ This script is designed for Arch Linux.${NC}"
    echo -e "${YELLOW}  It may not work on other distributions.${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo -e "${BLUE}═══ Updating system packages...${NC}"
if sudo pacman -Syu --noconfirm; then
    echo -e "${GREEN}✓ System updated${NC}"
else
    echo -e "${RED}✗ Failed to update system${NC}"
    exit 1
fi

# Install Docker
echo ""
echo -e "${BLUE}═══ Installing Docker...${NC}"
if sudo pacman -S --noconfirm docker docker-compose docker-buildx; then
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${RED}✗ Failed to install Docker${NC}"
    exit 1
fi

# Enable Docker service
echo ""
echo -e "${BLUE}═══ Enabling Docker service...${NC}"
if sudo systemctl enable docker.service; then
    echo -e "${GREEN}✓ Docker service enabled${NC}"
else
    echo -e "${YELLOW}⚠ Failed to enable Docker service${NC}"
fi

# Start Docker service
echo ""
echo -e "${BLUE}═══ Starting Docker service...${NC}"
if sudo systemctl start docker.service; then
    echo -e "${GREEN}✓ Docker service started${NC}"
else
    echo -e "${RED}✗ Failed to start Docker service${NC}"
    exit 1
fi

# Add user to docker group
echo ""
echo -e "${BLUE}═══ Adding user to docker group...${NC}"
if sudo usermod -aG docker $USER; then
    echo -e "${GREEN}✓ User added to docker group${NC}"
    echo -e "${YELLOW}⚠ You need to log out and log back in for this to take effect!${NC}"
    echo -e "${YELLOW}  Or run: newgrp docker${NC}"
else
    echo -e "${RED}✗ Failed to add user to docker group${NC}"
    exit 1
fi

# Verify installation
echo ""
echo -e "${BLUE}═══ Verifying Docker installation...${NC}"
if sudo docker --version; then
    echo -e "${GREEN}✓ Docker version:${NC}"
    sudo docker --version
else
    echo -e "${RED}✗ Docker verification failed${NC}"
    exit 1
fi

if sudo docker compose version; then
    echo -e "${GREEN}✓ Docker Compose version:${NC}"
    sudo docker compose version
else
    echo -e "${RED}✗ Docker Compose verification failed${NC}"
    exit 1
fi

# Test Docker
echo ""
echo -e "${BLUE}═══ Testing Docker...${NC}"
if sudo docker run --rm hello-world > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker is working correctly!${NC}"
else
    echo -e "${YELLOW}⚠ Docker test had issues, but Docker is installed${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            DOCKER INSTALLATION COMPLETE! 🎉                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠ IMPORTANT: You must log out and log back in (or restart)${NC}"
echo -e "${YELLOW}   for the docker group membership to take effect.${NC}"
echo ""
echo -e "${BLUE}After logging back in, test Docker with:${NC}"
echo -e "  ${YELLOW}docker --version${NC}"
echo -e "  ${YELLOW}docker run hello-world${NC}"
echo ""
echo -e "${BLUE}Then you can start the devcontainer with:${NC}"
echo -e "  ${YELLOW}cd /home/mrDinkelman/rice-mono/.devcontainer${NC}"
echo -e "  ${YELLOW}./start-devcontainer.sh${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
