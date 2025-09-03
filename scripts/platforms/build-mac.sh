#!/bin/bash

# 🍎 macOS Cross-Platform Build Script
# Builds Chain Rice for macOS (Intel and Apple Silicon)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🍎 Building Chain Rice for macOS platforms...${NC}"

# Detect Apple Silicon vs Intel
if [[ $(uname -m) == "arm64" ]]; then
    echo -e "${YELLOW}🍎 Detected Apple Silicon (M1/M2) Mac${NC}"
    PLATFORMS="linux/arm64,linux/amd64"
else
    echo -e "${YELLOW}🍎 Detected Intel Mac${NC}"
    PLATFORMS="linux/amd64"
fi

# Set up buildx if not already done
if ! docker buildx ls | grep -q "multiplatform"; then
    echo -e "${YELLOW}📦 Creating multiplatform builder...${NC}"
    docker buildx create --name multiplatform --use
fi

# Build for macOS-compatible platforms
echo -e "${GREEN}📦 Building frontend for macOS...${NC}"
docker buildx build \
  --platform "$PLATFORMS" \
  --tag meowtopia-frontend:latest \
  --file meowtopia/frontend/web/Dockerfile.web.npm \
  ./meowtopia/frontend/web \
  --load

echo -e "${GREEN}🐍 Building backend for macOS...${NC}"
docker buildx build \
  --platform "$PLATFORMS" \
  --tag meowtopia-backend:latest \
  --file meowtopia/backend/Dockerfile.backend \
  ./meowtopia/backend \
  --load

echo -e "${GREEN}⛓️ Building blockchain for macOS...${NC}"
docker buildx build \
  --platform "$PLATFORMS" \
  --tag chain-rice-blockchain:latest \
  --file Dockerfile.blockchain \
  . \
  --load

echo -e "${GREEN}✅ macOS cross-platform build completed successfully!${NC}"
echo -e "${YELLOW}🎉 All services are now compatible with macOS${NC}"
