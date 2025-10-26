#!/bin/bash

echo "🏛️ Building All Egyptian Gods..."
echo "================================"
echo ""

cd /home/mrDinkelman/rice-mono/.devcontainer

# Build each god
GODS=("thoth" "ra" "isis" "bastet" "maat" "khnum")

for god in "${GODS[@]}"; do
  echo "📦 Building $god..."
  docker-compose build $god
  if [ $? -eq 0 ]; then
    echo "✅ $god built successfully"
  else
    echo "❌ $god build failed!"
  fi
  echo ""
done

echo "🎉 All gods built!"
echo ""
echo "📊 To see in Docker addon:"
echo "   docker-compose up -d thoth    # Start Thoth only (6GB VRAM)"
echo "   docker-compose --profile all up -d   # Start ALL (24GB+ VRAM)"
echo ""
echo "📋 Check status:"
echo "   docker-compose ps"
echo ""
