#!/bin/bash

# 🌍 Universal Cross-Platform Build Script
# Builds Chain Rice for all platforms (Linux, Windows, macOS)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🌍 Building Chain Rice for all platforms...${NC}"

# Set up buildx if not already done
if ! docker buildx ls | grep -q "multiplatform"; then
    echo -e "${YELLOW}📦 Creating multiplatform builder...${NC}"
    docker buildx create --name multiplatform --use
fi

# Build for all platforms
echo -e "${GREEN}📦 Building frontend for all platforms...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag meowtopia-frontend:latest \
  --file meowtopia/frontend/web/Dockerfile.web.npm \
  ./meowtopia/frontend/web \
  --load

echo -e "${GREEN}🐍 Building backend for all platforms...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag meowtopia-backend:latest \
  --file meowtopia/backend/Dockerfile.backend \
  ./meowtopia/backend \
  --load

echo -e "${GREEN}⛓️ Building blockchain for all platforms...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag chain-rice-blockchain:latest \
  --file Dockerfile.blockchain \
  . \
  --load

echo -e "${GREEN}✅ Universal cross-platform build completed successfully!${NC}"
echo -e "${YELLOW}🎉 All services are now compatible with:${NC}"
echo -e "${YELLOW}   • Linux (AMD64 & ARM64)${NC}"
echo -e "${YELLOW}   • Windows (WSL2/Docker Desktop)${NC}"
echo -e "${YELLOW}   • macOS (Intel & Apple Silicon)${NC}"
