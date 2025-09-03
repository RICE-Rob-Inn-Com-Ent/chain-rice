#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting all Meowtopia services...${NC}"

# Start all services
docker compose up -d

echo -e "${GREEN}✅ All services started!${NC}\n"

echo -e "${YELLOW}📊 Service URLs:${NC}"
echo -e "  🔗 Blockchain RPC:    http://localhost:26657"
echo -e "  🔗 Blockchain API:    http://localhost:1317"
echo -e "  🔗 Backend API:        http://localhost:8000"
echo -e "  🔗 Web Frontend:       http://localhost:3000"
echo -e "  🔗 PostgreSQL:         localhost:5432"
echo -e "  🔗 Redis:              localhost:6379\n"

echo -e "${YELLOW}📋 Logs & Monitoring:${NC}"
echo -e "  📝 View all logs:         docker-compose logs -f"
echo -e "  📝 Blockchain logs:       docker-compose logs -f chain-rice-blockchain"
echo -e "  📝 Backend logs:          docker-compose logs -f meowtopia-backend"
echo -e "  📝 Web Frontend logs:     docker-compose logs -f meowtopia-frontend\n"

echo -e "${YELLOW}🔧 Useful Blockchain RPC commands:${NC}"
echo -e "  🟢 Check status:          curl http://localhost:26657/status"
echo -e "  🟢 View validators:       curl http://localhost:26657/validators"
echo -e "  🟢 Scan block 1:          curl http://localhost:26657/block?height=1\n"

echo -e "${YELLOW}🛑 To stop all:             docker-compose down"
echo -e "🔄 To restart all:          docker-compose restart${NC}\n"

# Open all development interfaces in browser
echo -e "${BLUE}🌐 Opening development interfaces in browser...${NC}"
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

# Open blockchain explorer/API
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:1317 &
elif command -v open > /dev/null; then
    open http://localhost:1317 &
elif command -v start > /dev/null; then
    start http://localhost:1317 &
fi

echo -e "${GREEN}✅ Development interfaces opened in browser!${NC}\n"

# Show colored logs for all services
echo -e "${BLUE}📝 Showing color-coded logs for all services...${NC}"
./scripts/colored-logs.sh all