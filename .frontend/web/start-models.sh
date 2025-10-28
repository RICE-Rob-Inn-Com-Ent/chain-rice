#!/bin/bash

# Start AI Models Script
# Uruchamia wszystkie 6 modeli AI w Docker

set -e

echo "🚀 Starting AI Models..."
echo ""

cd /home/mrDinkelman/rice-mono

# Kolory
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Lista modeli
MODELS=("thoth" "ra" "isis" "bastet" "maat" "khnum")

# Buduj obrazy jeśli nie istnieją
echo "📦 Building Docker images (this may take a while)..."
docker-compose build thoth ra isis bastet maat khnum

echo ""
echo "✅ Images built successfully!"
echo ""

# Uruchom kontenery
echo "🎬 Starting containers..."
docker-compose up -d thoth ra isis bastet maat khnum

echo ""
echo "⏳ Waiting for models to be ready..."
sleep 5

echo ""
echo "📊 Model Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Sprawdź status każdego modelu
for model in "${MODELS[@]}"; do
    container="rice-god-${model}"

    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "${GREEN}✓${NC} ${model^} - Running"
    else
        echo -e "${RED}✗${NC} ${model^} - Not Running"
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Model Endpoints:"
echo "  📚 Thoth  : http://localhost:8001/health"
echo "  ☀️  Ra     : http://localhost:8002/health"
echo "  ✨ Isis   : http://localhost:8003/health"
echo "  🐱 Bastet : http://localhost:8004/health"
echo "  ⚖️  Maat   : http://localhost:8005/health"
echo "  💰 Khnum  : http://localhost:8006/health"
echo ""
echo "📱 Frontend: http://localhost:3001"
echo ""
echo "💡 Tip: Use 'docker-compose logs -f [model]' to see logs"
echo "💡 Tip: Use 'docker-compose stop [model]' to stop a model"
echo ""

