#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🌐 Opening all development interfaces...${NC}"

# Read settings.json to optionally skip opening
SETTINGS_FILE="$(dirname "$0")/../../settings.json"
OPEN_ON_START=true
if [ -f "$SETTINGS_FILE" ]; then
    raw=$(cat "$SETTINGS_FILE")
    case "$raw" in *"openOnStart"*false*) OPEN_ON_START=false;; esac
fi

if [ "$OPEN_ON_START" != true ]; then
    echo -e "${YELLOW}⚠️  Skipping browser opening (settings.json openOnStart=false)${NC}"
    exit 0
fi

# Function to check if URL is accessible
check_url() {
    local url="$1"
    local timeout=2
    
    if command -v curl > /dev/null; then
        curl -s --connect-timeout $timeout --max-time $timeout "$url" >/dev/null 2>&1
    elif command -v wget > /dev/null; then
        wget --timeout=$timeout --tries=1 --spider "$url" >/dev/null 2>&1
    else
        # If no curl/wget, assume it's accessible
        return 0
    fi
}

# Function to open URL with cross-platform support
open_url() {
    local url="$1"
    local description="$2"
    
    # Check if URL is accessible
    if ! check_url "$url"; then
        echo -e "${YELLOW}⚠️  $description is not accessible (service may be starting up)${NC}"
        echo -e "   URL: $url"
        return
    fi
    
    echo -e "${BLUE}📱 Opening $description...${NC}"
    
    if command -v xdg-open > /dev/null; then
        # Suppress GTK warnings and Chrome errors
        GTK_MODULES="" \
        QT_QPA_PLATFORM="" \
        FONTCONFIG_FILE="" \
        xdg-open "$url" 2>/dev/null &
    elif command -v open > /dev/null; then
        open "$url" 2>/dev/null &
    elif command -v start > /dev/null; then
        start "$url" 2>/dev/null &
    else
        echo -e "${YELLOW}⚠️  Could not open browser automatically. Please open manually:${NC}"
        echo -e "   $url"
    fi
    
    sleep 0.5  # Small delay between openings
}

# Check if services are running
echo -e "${YELLOW}🔍 Checking if services are running...${NC}"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if services are up
services_running=true
if ! docker ps --format "table {{.Names}}" | grep -q "meowtopia-frontend"; then
    echo -e "${YELLOW}⚠️  Frontend service is not running${NC}"
    services_running=false
fi

if ! docker ps --format "table {{.Names}}" | grep -q "meowtopia-backend"; then
    echo -e "${YELLOW}⚠️  Backend service is not running${NC}"
    services_running=false
fi

if ! docker ps --format "table {{.Names}}" | grep -q "chain-rice-blockchain"; then
    echo -e "${YELLOW}⚠️  Blockchain service is not running${NC}"
    services_running=false
fi

if [ "$services_running" = false ]; then
    echo -e "${YELLOW}💡 Run 'make dev' to start all services first${NC}"
    echo -e "${YELLOW}   Or run 'make up' to start services without building${NC}\n"
fi

# Open all development interfaces
echo -e "${GREEN}🚀 Opening development interfaces:${NC}\n"

# Web Frontend
open_url "http://localhost:3000/sign-in" "Web Frontend Sign-in Page"

# Backend API Documentation
open_url "http://localhost:8000/docs" "Backend API Documentation (Swagger)"

# Backend Health Check
open_url "http://localhost:8000/health" "Backend Health Check"

# Blockchain REST API
open_url "http://localhost:1317" "Blockchain REST API"

# Blockchain RPC Status
open_url "http://localhost:26657/status" "Blockchain RPC Status"

# Blockchain Validators
open_url "http://localhost:26657/validators" "Blockchain Validators"

# Additional Blockchain Interfaces
open_url "http://localhost:26657/block?height=1" "Genesis Block"
open_url "http://localhost:26657/blockchain" "Blockchain Info"
open_url "http://localhost:26657/net_info" "Network Information"
open_url "http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info" "Node Information (REST)"

echo -e "\n${GREEN}✅ All development interfaces opened!${NC}\n"

echo -e "${YELLOW}📋 Development Interface URLs:${NC}"
echo -e "  🌐 Web Frontend:        http://localhost:3000/sign-in"
echo -e "  📚 API Documentation:   http://localhost:8000/docs"
echo -e "  💚 Health Check:        http://localhost:8000/health"
echo -e "  ⛓️  Blockchain API:      http://localhost:1317"
echo -e "  🔗 Blockchain Status:   http://localhost:26657/status"
echo -e "  🏛️  Validators:          http://localhost:26657/validators"
echo -e "  🧬 Genesis Block:       http://localhost:26657/block?height=1"
echo -e "  📊 Blockchain Info:     http://localhost:26657/blockchain"
echo -e "  🌐 Network Info:        http://localhost:26657/net_info"
echo -e "  🔧 Node Info (REST):    http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info\n"

# --- Autodetect and open all published container ports (best-effort) ---
echo -e "${PURPLE}🔎 Autodetecting published container ports and opening base URLs...${NC}"

# Gather name|ports lines, extract host ports like 0.0.0.0:PORT->, [::]:PORT-> or :::PORT->
docker ps --format '{{.Names}}|{{.Ports}}' | while IFS='|' read -r cname cports; do
    # Skip empty mappings
    [ -z "$cports" ] && continue
    # Split by comma
    IFS=',' read -ra mappings <<< "$cports"
    for m in "${mappings[@]}"; do
        # Trim leading/trailing spaces
        m="${m## }"; m="${m%% }"
        # Extract host port before ->
        host_port=$(echo "$m" | sed -nE 's/.*\[::\]:([0-9]+)->.*/\1/p; s/.*0\.0\.0\.0:([0-9]+)->.*/\1/p; s/.*:::([0-9]+)->.*/\1/p')
        if [ -n "$host_port" ]; then
            # Try opening the base URL; many services expose HTTP on these ports
            open_url "http://localhost:${host_port}" "${cname} on :${host_port} (auto)"
        fi
    done
done

echo -e "${YELLOW}💡 Tips:${NC}"
echo -e "  • Use Ctrl+Click to open links in new tabs"
echo -e "  • Bookmark these URLs for quick access"
echo -e "  • Check the API docs for available endpoints"
echo -e "  • Monitor blockchain status for development"
echo -e "  • Run 'make status' to check service health"
echo -e "  • Run 'make logs' to view service logs\n" 