#!/bin/bash

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       SPRAWDZENIE ZMIAN W UI-KIT (Port 3001)                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  SPRAWDZANIE PLIKÓW..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check GiPT1Training.tsx
if [ -f "app/GiPT1Training.tsx" ]; then
    lines=$(wc -l < app/GiPT1Training.tsx)
    echo -e "${GREEN}✓${NC} app/GiPT1Training.tsx istnieje ($lines linii)"
else
    echo -e "${RED}✗${NC} app/GiPT1Training.tsx NIE ISTNIEJE!"
fi

# Check Layout.tsx changes
if grep -q "gipt1-training" app/Layout.tsx; then
    echo -e "${GREEN}✓${NC} Layout.tsx ma 'gipt1-training' w navItems"
else
    echo -e "${RED}✗${NC} Layout.tsx nie ma 'gipt1-training'!"
fi

if grep -q "prices" app/Layout.tsx; then
    echo -e "${YELLOW}⚠${NC} Layout.tsx nadal ma 'prices' - powinno być usunięte"
else
    echo -e "${GREEN}✓${NC} Layout.tsx nie ma już 'prices' ✓"
fi

# Check App.tsx changes
if grep -q "GiPT1Training" app/App.tsx; then
    echo -e "${GREEN}✓${NC} App.tsx importuje GiPT1Training"
else
    echo -e "${RED}✗${NC} App.tsx nie importuje GiPT1Training!"
fi

if grep -q '"gipt1-training"' app/App.tsx; then
    echo -e "${GREEN}✓${NC} App.tsx ma route dla gipt1-training"
else
    echo -e "${RED}✗${NC} App.tsx nie ma route dla gipt1-training!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  SPRAWDZANIE DEV SERVERA..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if pgrep -f "vite.*3001" > /dev/null; then
    echo -e "${GREEN}✓${NC} Vite dev server działa na porcie 3001"
    pid=$(pgrep -f "vite.*3001")
    echo "  PID: $pid"
else
    echo -e "${RED}✗${NC} Vite dev server NIE DZIAŁA na porcie 3001!"
    echo "  Uruchom: cd /home/mrDinkelman/rice-mono/.frontend/web && yarn dev"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  SPRAWDZANIE PACKAGE.JSON..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if grep -q "publishConfig" package.json; then
    echo -e "${GREEN}✓${NC} package.json ma publishConfig (gotowy do npm)"
else
    echo -e "${YELLOW}⚠${NC} package.json nie ma publishConfig"
fi

if grep -q "build:lib" package.json; then
    echo -e "${GREEN}✓${NC} package.json ma script build:lib"
else
    echo -e "${YELLOW}⚠${NC} package.json nie ma script build:lib"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  SPRAWDZANIE LIB/ EXPORTS..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if grep -q "themes" lib/index.ts; then
    echo -e "${GREEN}✓${NC} lib/index.ts eksportuje themes"
else
    echo -e "${YELLOW}⚠${NC} lib/index.ts nie eksportuje themes"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  PODSUMOWANIE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count checks
total_checks=7
passed_checks=0

[ -f "app/GiPT1Training.tsx" ] && ((passed_checks++))
grep -q "gipt1-training" app/Layout.tsx && ((passed_checks++))
! grep -q "prices" app/Layout.tsx && ((passed_checks++))
grep -q "GiPT1Training" app/App.tsx && ((passed_checks++))
grep -q '"gipt1-training"' app/App.tsx && ((passed_checks++))
pgrep -f "vite.*3001" > /dev/null && ((passed_checks++))
grep -q "publishConfig" package.json && ((passed_checks++))

if [ $passed_checks -eq $total_checks ]; then
    echo -e "${GREEN}✅ WSZYSTKO OK!${NC} ($passed_checks/$total_checks checks passed)"
    echo ""
    echo "Zmiany są zaimplementowane poprawnie."
    echo "Jeśli nie widzisz ich w przeglądarce:"
    echo ""
    echo "1. Zrestartuj dev server:"
    echo "   pkill -f 'vite.*3001'"
    echo "   yarn dev"
    echo ""
    echo "2. Wyczyść cache przeglądarki (Ctrl+Shift+R)"
    echo ""
elif [ $passed_checks -ge 5 ]; then
    echo -e "${YELLOW}⚠ PRAWIE GOTOWE${NC} ($passed_checks/$total_checks checks passed)"
    echo ""
    echo "Większość zmian jest OK, ale sprawdź szczegóły powyżej."
else
    echo -e "${RED}✗ PROBLEMY${NC} ($passed_checks/$total_checks checks passed)"
    echo ""
    echo "Wygląda na to że zmiany nie zostały w pełni zastosowane."
    echo "Sprawdź komunikaty powyżej."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

