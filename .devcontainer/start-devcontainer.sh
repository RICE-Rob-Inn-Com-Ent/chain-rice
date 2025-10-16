#!/usr/bin/env bash
# ==============================================================================
# RICE-MONO DEVCONTAINER STARTUP SCRIPT
# ==============================================================================
# This script builds and starts the comprehensive development environment
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     RICE-MONO ULTIMATE DEVELOPMENT ENVIRONMENT STARTUP        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"

# Check available disk space
AVAILABLE_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 30 ]; then
    echo -e "${YELLOW}⚠ Warning: Less than 30GB available. This setup requires significant disk space.${NC}"
fi
echo -e "${GREEN}✓ Available disk space: ${AVAILABLE_SPACE}GB${NC}"

# Stop existing containers
echo ""
echo -e "${BLUE}═══ Stopping existing containers...${NC}"
docker compose down 2>/dev/null || true
echo -e "${GREEN}✓ Stopped existing containers${NC}"

# Build the devcontainer
echo ""
echo -e "${BLUE}═══ Building devcontainer (this may take 30-60 minutes)...${NC}"
echo -e "${YELLOW}☕ Time to grab a coffee! This is going to take a while...${NC}"
echo ""

if docker compose build --progress=plain devcontainer; then
    echo -e "${GREEN}✓ Devcontainer built successfully!${NC}"
else
    echo -e "${RED}✗ Failed to build devcontainer${NC}"
    exit 1
fi

# Start all services
echo ""
echo -e "${BLUE}═══ Starting all services...${NC}"
if docker compose up -d; then
    echo -e "${GREEN}✓ All services started successfully!${NC}"
else
    echo -e "${RED}✗ Failed to start services${NC}"
    exit 1
fi

# Wait for services to be healthy
echo ""
echo -e "${BLUE}═══ Waiting for services to be healthy...${NC}"
sleep 10

# Show service status
echo ""
echo -e "${BLUE}═══ Service Status${NC}"
docker compose ps

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            DEVELOPMENT ENVIRONMENT IS READY! 🚀                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Available Services:${NC}"
echo ""
echo -e "  ${GREEN}■${NC} DevContainer:        Development environment with all tools"
echo -e "  ${GREEN}■${NC} PostgreSQL:          localhost:5432  (user: rice_user, pass: rice_password)"
echo -e "  ${GREEN}■${NC} MySQL:               localhost:3306  (user: rice_user, pass: rice_password)"
echo -e "  ${GREEN}■${NC} Redis:               localhost:6379  (pass: rice_password)"
echo -e "  ${GREEN}■${NC} MongoDB:             localhost:27017 (user: rice_user, pass: rice_password)"
echo -e "  ${GREEN}■${NC} Elasticsearch:       localhost:9200"
echo -e "  ${GREEN}■${NC} Kafka:               localhost:9092"
echo -e "  ${GREEN}■${NC} RabbitMQ:            localhost:15672 (user: rice_user, pass: rice_password)"
echo -e "  ${GREEN}■${NC} MinIO:               localhost:9001  (user: rice_admin, pass: rice_password_123)"
echo -e "  ${GREEN}■${NC} Grafana:             localhost:3000  (user: admin, pass: admin)"
echo -e "  ${GREEN}■${NC} Prometheus:          localhost:9090"
echo -e "  ${GREEN}■${NC} Jaeger:              localhost:16686"
echo -e "  ${GREEN}■${NC} Traefik Dashboard:   localhost:8080"
echo -e "  ${GREEN}■${NC} Adminer:             localhost:8081"
echo -e "  ${GREEN}■${NC} Redis Commander:     localhost:8082"
echo -e "  ${GREEN}■${NC} Mongo Express:       localhost:8083"
echo -e "  ${GREEN}■${NC} MailHog:             localhost:8025"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Open VS Code"
echo -e "  2. Click 'Dev Containers: Reopen in Container' from Command Palette"
echo -e "  3. Or run: ${YELLOW}docker-compose exec devcontainer bash${NC}"
echo ""

echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  ${YELLOW}docker compose logs -f${NC}              # View all logs"
echo -e "  ${YELLOW}docker compose ps${NC}                   # List all containers"
echo -e "  ${YELLOW}docker compose down${NC}                 # Stop all services"
echo -e "  ${YELLOW}docker compose down -v${NC}              # Stop and remove volumes"
echo -e "  ${YELLOW}docker compose restart devcontainer${NC} # Restart dev container"
echo ""

echo -e "${GREEN}Happy coding! 💻${NC}"
