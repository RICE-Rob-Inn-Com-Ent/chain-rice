#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Host logic (start container) ---
echo -e "${BLUE}⛓️  Starting Blockchain service...${NC}"
docker-compose up -d chain-rice-blockchain
echo -e "${GREEN}✅ Blockchain started!${NC}\n"
echo -e "${YELLOW}🔗 Blockchain Endpoints:${NC}"
echo -e "  🟢 RPC:        http://localhost:26657"
echo -e "  🟢 API:        http://localhost:1317"\n
echo -e "${YELLOW}📋 Logs & Monitoring:${NC}"
echo -e "  📝 View logs:           docker-compose logs -f chain-rice-blockchain"\n
# Open blockchain interfaces in browser
echo -e "${BLUE}🌐 Opening blockchain interfaces in browser...${NC}"
sleep 3  # Wait for services to be ready

# Open blockchain explorer/API
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:1317 &
elif command -v open > /dev/null; then
    open http://localhost:1317 &
elif command -v start > /dev/null; then
    start http://localhost:1317 &
fi

# Open blockchain RPC endpoint info
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:26657/status &
elif command -v open > /dev/null; then
    open http://localhost:26657/status &
elif command -v start > /dev/null; then
    start http://localhost:26657/status &
fi

echo -e "${GREEN}✅ Blockchain interfaces opened in browser!${NC}\n"

# Show colored blockchain logs
echo -e "${BLUE}📝 Showing color-coded blockchain logs...${NC}"
./scripts/colored-logs.sh blockchain