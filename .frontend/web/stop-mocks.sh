#!/bin/bash

echo "🛑 Stopping mock AI servers..."
pkill -f "node mock-models.js" 2>/dev/null || true
sleep 1
echo "✅ Mock servers stopped!"

# Sprawdź czy prawdziwe modele działają
echo ""
echo "📊 Checking real Docker models..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "rice-god|NAMES"

echo ""
echo "💡 To start real models: make gods"
echo "💡 Or run: docker-compose up -d thoth ra isis bastet maat khnum"

