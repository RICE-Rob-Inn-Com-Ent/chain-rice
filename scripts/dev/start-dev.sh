#!/bin/bash

# 🚀 Development Environment Startup Script
# Starts the complete development environment (blockchain optional via settings.json)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting Chain Rice Development Environment...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Set environment variables
export BUILD_ENV=development
export BUILD_NUMBER=1
export BUILD_DATE=$(date +%Y-%m-%d)
export BUILD_VERSION=0.1.0
export BUILD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")

SETTINGS_FILE="$(dirname "$0")/../../settings.json"
ENABLE_BLOCKCHAIN=true
REBUILD=false

if [ -f "$SETTINGS_FILE" ]; then
    # Parse minimal JSON without jq to keep memory/dep low
    raw=$(cat "$SETTINGS_FILE")
    case "$raw" in *"enableBlockchain"*false*) ENABLE_BLOCKCHAIN=false;; esac
    case "$raw" in *"rebuildOnDev"*true*) REBUILD=true;; esac
fi

echo -e "${YELLOW}📦 Building services...${NC}"
if [ "$REBUILD" = true ]; then
    docker compose build --no-cache || docker-compose build --no-cache
else
    docker compose build || docker-compose build
fi

echo -e "${GREEN}🚀 Starting services...${NC}"
if [ "$ENABLE_BLOCKCHAIN" = true ]; then
    docker compose --profile app --profile blockchain up -d || docker-compose --profile app --profile blockchain up -d
else
    docker compose --profile app up -d || docker-compose --profile app up -d
fi

echo -e "${GREEN}⏳ Waiting for services to be ready...${NC}"
sleep 10

echo -e "${GREEN}✅ Development environment is ready!${NC}"
echo ""
echo -e "${YELLOW}🌐 Available services:${NC}"
echo -e "  • Web Frontend:     http://localhost:3000"
echo -e "  • Backend API:      http://localhost:8000"
echo -e "  • API Docs:         http://localhost:8000/docs"
if [ "$ENABLE_BLOCKCHAIN" = true ]; then
  echo -e "  • Blockchain API:   http://localhost:1317"
  echo -e "  • Blockchain RPC:   http://localhost:26657"
else
  echo -e "  • Blockchain:       disabled by settings.json"
fi
echo ""
echo -e "${YELLOW}📝 Useful commands:${NC}"
echo -e "  • View logs:        make logs"
echo -e "  • Stop services:    make stop"
echo -e "  • Restart:          make restart"
echo -e "  • Open interfaces:  make open"
echo ""
echo -e "${GREEN}🎉 Happy coding!${NC}"
