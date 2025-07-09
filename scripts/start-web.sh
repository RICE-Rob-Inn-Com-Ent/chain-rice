#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🌐 Starting Web Frontend and Backend services...${NC}"

# Start only web frontend and backend
docker-compose up -d meowtopia-frontend meowtopia-backend

echo -e "${GREEN}✅ Web Frontend and Backend started!${NC}\n"

echo -e "${YELLOW}🔗 Web & API Endpoints:${NC}"
echo -e "  🟢 Web Frontend:    http://localhost:3000"
echo -e "  🟢 Backend API:     http://localhost:8000"\n

echo -e "${YELLOW}📋 Logs & Monitoring:${NC}"
echo -e "  📝 View web logs:   docker-compose logs -f meowtopia-frontend"
echo -e "  📝 View backend:    docker-compose logs -f meowtopia-backend"\n
# Open web development interfaces in browser
echo -e "${BLUE}🌐 Opening web development interfaces in browser...${NC}"
sleep 3  # Wait for services to be ready

# Open web frontend
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:3000 &
elif command -v open > /dev/null; then
    open http://localhost:3000 &
elif command -v start > /dev/null; then
    start http://localhost:3000 &
fi

# Open backend API docs
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:8000/docs &
elif command -v open > /dev/null; then
    open http://localhost:8000/docs &
elif command -v start > /dev/null; then
    start http://localhost:8000/docs &
fi

echo -e "${GREEN}✅ Web development interfaces opened in browser!${NC}\n"

# Show colored logs for web development
echo -e "${BLUE}📝 Showing color-coded web development logs...${NC}"
./scripts/colored-logs.sh web