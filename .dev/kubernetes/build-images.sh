#!/bin/bash

# Rice-Mono Docker Images Build Script
# Builds all Docker images and loads them into kind cluster

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Building Rice-Mono Docker Images${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

CLUSTER_NAME="rice-mono"
REGISTRY="rice-mono"
VERSION="${1:-latest}"

cd "$(dirname "$0")/../.."
PROJECT_ROOT=$(pwd)

# Check if kind cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "${RED}✗${NC} kind cluster '${CLUSTER_NAME}' not found"
  echo -e "${YELLOW}Run: ./dev/kubernetes/setup-cluster.sh${NC}"
  exit 1
fi

echo -e "${BLUE}Building images with version: ${VERSION}${NC}"
echo

# Build Backend
echo -e "${BLUE}[1/3] Building Backend (Go)...${NC}"
cd "${PROJECT_ROOT}/.backend"
docker build -t ${REGISTRY}/backend:${VERSION} \
  -f Dockerfile \
  --build-arg VERSION=${VERSION} \
  .
echo -e "${GREEN}✓${NC} Backend image built"
echo

# Build Bot
echo -e "${BLUE}[2/3] Building Bot (Python AI)...${NC}"
cd "${PROJECT_ROOT}/.bot"
docker build -t ${REGISTRY}/bot:${VERSION} \
  -f Dockerfile \
  --target production \
  --build-arg VERSION=${VERSION} \
  .
echo -e "${GREEN}✓${NC} Bot image built"
echo

# Build Frontend (if Dockerfile exists)
if [ -f "${PROJECT_ROOT}/.frontend/web/next/Dockerfile" ]; then
  echo -e "${BLUE}[3/3] Building Frontend (Next.js)...${NC}"
  cd "${PROJECT_ROOT}/.frontend/web/next"
  docker build -t ${REGISTRY}/frontend:${VERSION} \
    -f Dockerfile \
    --build-arg VERSION=${VERSION} \
    .
  echo -e "${GREEN}✓${NC} Frontend image built"
  echo
else
  echo -e "${YELLOW}!${NC} Frontend Dockerfile not found, skipping..."
  echo
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Loading images into kind cluster${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

kind load docker-image ${REGISTRY}/backend:${VERSION} --name ${CLUSTER_NAME}
echo -e "${GREEN}✓${NC} Backend image loaded"

kind load docker-image ${REGISTRY}/bot:${VERSION} --name ${CLUSTER_NAME}
echo -e "${GREEN}✓${NC} Bot image loaded"

if [ -f "${PROJECT_ROOT}/.frontend/web/next/Dockerfile" ]; then
  kind load docker-image ${REGISTRY}/frontend:${VERSION} --name ${CLUSTER_NAME}
  echo -e "${GREEN}✓${NC} Frontend image loaded"
fi

echo
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          🎉  All Images Built & Loaded!  🎉               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${CYAN}Built images:${NC}"
docker images | grep ${REGISTRY} | head -10
echo

echo -e "${YELLOW}Next step:${NC} Deploy to cluster"
echo -e "  ${BLUE}./dev/kubernetes/deploy-all.sh${NC}"
echo
