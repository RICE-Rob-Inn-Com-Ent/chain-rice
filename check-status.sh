#!/bin/bash

# 🌍 Rice-Dev Ecosystem Status Checker

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🌍 Rice-Dev Ecosystem - Перевірка статусу${NC}"
echo "=============================================="
echo ""

# Function to check service status
check_service() {
    local name=$1
    local url=$2
    local color=$3
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name${NC} - Активний"
        return 0
    else
        echo -e "${RED}❌ $name${NC} - Неактивний"
        return 1
    fi
}

# Check ChainRice services
echo -e "${BLUE}🍚 ChainRice (Бухгалтерія):${NC}"
check_service "Фронтенд (5173)" "http://localhost:5173" "$BLUE"
check_service "API (8004)" "http://localhost:8004/health" "$BLUE"
check_service "AI (8005)" "http://localhost:8005/health" "$BLUE"
echo ""

# Check Meowtopia services
echo -e "${PURPLE}🐱 Meowtopia (Кафе з котами):${NC}"
check_service "Фронтенд (5174)" "http://localhost:5174" "$PURPLE"
check_service "API (8006)" "http://localhost:8006/health" "$PURPLE"
echo ""

# Check Blockchain services
echo -e "${YELLOW}⛓️ Блокчейн:${NC}"
check_service "REST API (1317)" "http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info" "$YELLOW"
check_service "RPC (26657)" "http://localhost:26657/status" "$YELLOW"
echo ""

# Summary
echo -e "${CYAN}📊 Підсумок:${NC}"
active_count=0
total_count=6

services=(
    "http://localhost:5173"
    "http://localhost:8004/health"
    "http://localhost:8005/health"
    "http://localhost:5174"
    "http://localhost:8006/health"
    "http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info"
)

for service in "${services[@]}"; do
    if curl -s "$service" > /dev/null 2>&1; then
        ((active_count++))
    fi
done

echo "Активних сервісів: $active_count/$total_count"

if [ $active_count -eq $total_count ]; then
    echo -e "${GREEN}🎉 Всі сервіси працюють!${NC}"
elif [ $active_count -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Частково працюють${NC}"
else
    echo -e "${RED}💥 Нічого не працює${NC}"
fi

echo ""
echo -e "${CYAN}🔗 Швидкі посилання:${NC}"
echo "🍚 ChainRice: http://localhost:5173"
echo "🐱 Meowtopia: http://localhost:5174"
echo "⛓️ Блокчейн: http://localhost:1317"
