#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREY='\033[0;37m'
LIGHT_GREY='\033[0;90m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to colorize logs
colorize_logs() {
    while IFS= read -r line; do
        # Blockchain logs (grey)
        if echo "$line" | grep -q "chain-rice-blockchain"; then
            echo -e "${GREY}$line${NC}"
        # Backend logs (yellow)
        elif echo "$line" | grep -q "meowtopia-backend"; then
            echo -e "${YELLOW}$line${NC}"
        # Web frontend logs (blue)
        elif echo "$line" | grep -q "meowtopia-frontend"; then
            echo -e "${BLUE}$line${NC}"
        # Mobile Android logs (green)
        elif echo "$line" | grep -q "android\|Android"; then
            echo -e "${GREEN}$line${NC}"
        # Mobile iOS logs (light grey)
        elif echo "$line" | grep -q "ios\|iOS\|iphone\|iPhone"; then
            echo -e "${LIGHT_GREY}$line${NC}"
        # Mobile general logs (red)
        elif echo "$line" | grep -q "mobile\|Mobile"; then
            echo -e "${RED}$line${NC}"
        # Default (no color)
        else
            echo "$line"
        fi
    done
}

# Function to show logs for specific services
show_colored_logs() {
    local services="$1"
    
    if [ -z "$services" ]; then
        # Show all services
        echo -e "${PURPLE}📝 Showing color-coded logs for all services...${NC}"
        echo -e "${GREY}🔗 Blockchain (Grey)${NC} | ${YELLOW}🔧 Backend (Yellow)${NC} | ${BLUE}🌐 Web (Blue)${NC} | ${RED}📱 Mobile (Red)${NC} | ${GREEN}🤖 Android (Green)${NC} | ${LIGHT_GREY}🍎 iOS (Light Grey)${NC}"
        echo ""
        docker-compose logs -f | colorize_logs
    else
        # Show specific services
        echo -e "${PURPLE}📝 Showing color-coded logs for: $services${NC}"
        docker-compose logs -f $services | colorize_logs
    fi
}

# Main script logic
case "${1:-all}" in
    "all")
        show_colored_logs ""
        ;;
    "blockchain")
        show_colored_logs "chain-rice-blockchain"
        ;;
    "backend")
        show_colored_logs "meowtopia-backend"
        ;;
    "web")
        show_colored_logs "meowtopia-frontend meowtopia-backend"
        ;;
    "mobile")
        show_colored_logs "meowtopia-backend chain-rice-blockchain"
        ;;
    "help"|"-h"|"--help")
        echo -e "${BLUE}🎨 Colored Logs Script${NC}"
        echo ""
        echo -e "${YELLOW}Usage:${NC}"
        echo "  ./scripts/colored-logs.sh [service]"
        echo ""
        echo -e "${YELLOW}Services:${NC}"
        echo -e "  ${GREY}blockchain${NC}  - Show blockchain logs (Grey)"
        echo -e "  ${YELLOW}backend${NC}    - Show backend logs (Yellow)"
        echo -e "  ${BLUE}web${NC}        - Show web frontend + backend logs (Blue + Yellow)"
        echo -e "  ${RED}mobile${NC}      - Show mobile backend + blockchain logs (Red + Grey)"
        echo -e "  ${GREEN}all${NC}        - Show all services (Default)"
        echo ""
        echo -e "${YELLOW}Color Legend:${NC}"
        echo -e "  ${GREY}🔗 Blockchain${NC}     - Grey"
        echo -e "  ${YELLOW}🔧 Backend${NC}       - Yellow"
        echo -e "  ${BLUE}🌐 Web Frontend${NC}   - Blue"
        echo -e "  ${RED}📱 Mobile${NC}         - Red"
        echo -e "  ${GREEN}🤖 Android${NC}       - Green"
        echo -e "  ${LIGHT_GREY}🍎 iOS${NC}         - Light Grey"
        ;;
    *)
        echo -e "${RED}❌ Unknown service: $1${NC}"
        echo -e "Use './scripts/colored-logs.sh help' for usage information"
        exit 1
        ;;
esac 