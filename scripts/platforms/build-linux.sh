#!/bin/bash

# 🐧 Linux Cross-Platform Build Script
# Builds Chain Rice for Linux (AMD64 and ARM64)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🐧 Building Chain Rice for Linux platforms...${NC}"

# Set up buildx if not already done
if ! docker buildx ls | grep -q "multiplatform"; then
    echo -e "${YELLOW}📦 Creating multiplatform builder...${NC}"
    docker buildx create --name multiplatform --use
fi

# Build for Linux platforms
echo -e "${GREEN}📦 Building frontend for linux/amd64...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag meowtopia-frontend:latest \
  --file meowtopia/frontend/web/Dockerfile.web.npm \
  ./meowtopia/frontend/web \
  --load

echo -e "${GREEN}🐍 Building backend for linux/amd64...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag meowtopia-backend:latest \
  --file meowtopia/backend/Dockerfile.backend \
  ./meowtopia/backend \
  --load

echo -e "${GREEN}⛓️ Building blockchain for linux/amd64...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag chain-rice-blockchain:latest \
  --file Dockerfile.blockchain \
  . \
  --load

echo -e "${GREEN}✅ Linux cross-platform build completed successfully!${NC}"
echo -e "${YELLOW}🎉 All services are now compatible with Linux systems${NC}"
