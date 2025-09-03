#!/bin/bash

# 🪟 Windows Cross-Platform Build Script
# Builds Chain Rice for Windows (WSL2/Docker Desktop)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🪟 Building Chain Rice for Windows platforms...${NC}"

# Check if running on Windows or WSL
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
    echo -e "${YELLOW}🪟 Detected Windows/WSL environment${NC}"
else
    echo -e "${YELLOW}⚠️  This script is optimized for Windows/WSL environments${NC}"
fi

# Set up buildx if not already done
if ! docker buildx ls | grep -q "multiplatform"; then
    echo -e "${YELLOW}📦 Creating multiplatform builder...${NC}"
    docker buildx create --name multiplatform --use
fi

# Build for Windows-compatible Linux containers
echo -e "${GREEN}📦 Building frontend for Windows Docker Desktop...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag meowtopia-frontend:latest \
  --file meowtopia/frontend/web/Dockerfile.web.npm \
  ./meowtopia/frontend/web \
  --load

echo -e "${GREEN}🐍 Building backend for Windows Docker Desktop...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag meowtopia-backend:latest \
  --file meowtopia/backend/Dockerfile.backend \
  ./meowtopia/backend \
  --load

echo -e "${GREEN}⛓️ Building blockchain for Windows Docker Desktop...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag chain-rice-blockchain:latest \
  --file Dockerfile.blockchain \
  . \
  --load

echo -e "${GREEN}✅ Windows cross-platform build completed successfully!${NC}"
echo -e "${YELLOW}🎉 All services are now compatible with Windows Docker Desktop${NC}"
echo -e "${YELLOW}💡 Make sure Docker Desktop is running with WSL2 backend enabled${NC}"
