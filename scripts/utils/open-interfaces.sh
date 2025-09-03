#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🌐 Opening all development interfaces...${NC}"

# Function to open URL with cross-platform support
open_url() {
    local url="$1"
    local description="$2"
    
    echo -e "${BLUE}📱 Opening $description...${NC}"
    
    if command -v xdg-open > /dev/null; then
        xdg-open "$url" &
    elif command -v open > /dev/null; then
        open "$url" &
    elif command -v start > /dev/null; then
        start "$url" &
    else
        echo -e "${YELLOW}⚠️  Could not open browser automatically. Please open manually:${NC}"
        echo -e "   $url"
    fi
    
    sleep 0.5  # Small delay between openings
}

# Check if services are running
echo -e "${YELLOW}🔍 Checking if services are running...${NC}"

# Open all development interfaces
echo -e "${GREEN}🚀 Opening development interfaces:${NC}\n"

# Web Frontend
open_url "http://localhost:3000" "Web Frontend (React App)"

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

echo -e "\n${GREEN}✅ All development interfaces opened!${NC}\n"

echo -e "${YELLOW}📋 Development Interface URLs:${NC}"
echo -e "  🌐 Web Frontend:        http://localhost:3000"
echo -e "  📚 API Documentation:   http://localhost:8000/docs"
echo -e "  💚 Health Check:        http://localhost:8000/health"
echo -e "  ⛓️  Blockchain API:      http://localhost:1317"
echo -e "  🔗 Blockchain Status:   http://localhost:26657/status"
echo -e "  🏛️  Validators:          http://localhost:26657/validators\n"

echo -e "${YELLOW}💡 Tips:${NC}"
echo -e "  • Use Ctrl+Click to open links in new tabs"
echo -e "  • Bookmark these URLs for quick access"
echo -e "  • Check the API docs for available endpoints"
echo -e "  • Monitor blockchain status for development\n" 