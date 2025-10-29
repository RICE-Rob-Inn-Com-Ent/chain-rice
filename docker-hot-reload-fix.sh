#!/bin/bash

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  🐳 DOCKER HOT RELOAD FIX - Automatyczne Czyszczenie Cache      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Sprawdzam status kontenera..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker ps | grep -q "rice-ui-kit"; then
    echo -e "${GREEN}✓${NC} Kontener rice-ui-kit działa"
else
    echo -e "${YELLOW}⚠${NC} Kontener rice-ui-kit nie działa!"
    echo "   Uruchom: docker-compose up ui-kit"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Czyszczę Vite cache w kontenerze..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Wyczyść Vite cache
echo -e "${BLUE}→${NC} Usuwam node_modules/.vite..."
docker-compose exec -T ui-kit rm -rf /app/.frontend/web/node_modules/.vite 2>/dev/null || true
docker-compose exec -T ui-kit rm -rf /app/node_modules/.vite 2>/dev/null || true

echo -e "${GREEN}✓${NC} Cache wyczyszczony"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Restartuję kontener..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker-compose restart ui-kit

echo ""
echo -e "${GREEN}✓${NC} Kontener zrestartowany"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Sprawdzam czy nowe pliki są w kontenerze..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Sprawdź czy GiPT1Training.tsx istnieje w kontenerze
if docker-compose exec -T ui-kit test -f /app/.frontend/web/app/GiPT1Training.tsx; then
    lines=$(docker-compose exec -T ui-kit wc -l < /app/.frontend/web/app/GiPT1Training.tsx)
    echo -e "${GREEN}✓${NC} GiPT1Training.tsx w kontenerze ($lines linii)"
else
    echo -e "${YELLOW}⚠${NC} GiPT1Training.tsx NIE ZNALEZIONY w kontenerze!"
fi

# Sprawdź czy Layout.tsx ma zmiany
if docker-compose exec -T ui-kit grep -q "gipt1-training" /app/.frontend/web/app/Layout.tsx; then
    echo -e "${GREEN}✓${NC} Layout.tsx ma 'gipt1-training'"
else
    echo -e "${YELLOW}⚠${NC} Layout.tsx nie ma 'gipt1-training'!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Monitoruję logi (Ctrl+C aby zatrzymać)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Czekam 3 sekundy na restart Vite..."
sleep 3

echo ""
echo -e "${GREEN}✓ GOTOWE!${NC}"
echo ""
echo "Teraz:"
echo "1. Otwórz: http://localhost:3001"
echo "2. Wyczyść cache przeglądarki (Ctrl+Shift+R)"
echo "3. Powinieneś zobaczyć 'GiPT-1 Training' w sidebar"
echo ""
echo "Jeśli nadal nie widzisz zmian, uruchom full rebuild:"
echo "  docker-compose down"
echo "  docker-compose build --no-cache ui-kit"
echo "  docker-compose up ui-kit"
echo ""

# Pokaż ostatnie 20 linii logów
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Ostatnie logi z Vite:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose logs --tail=20 ui-kit

