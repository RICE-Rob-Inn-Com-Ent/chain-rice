#!/bin/bash
# Quick start script for Docker development

echo "🐳 Egyptian AI Dashboard - Docker Dev Mode"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Ollama is running on host
echo "Checking Ollama connection..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama is running on localhost:11434"
else
    echo "⚠️  Ollama is not running. Dashboard will show 'Disconnected'."
    echo "   To start Ollama: ollama serve"
fi

echo ""
echo "Building and starting container..."
echo ""

# Build and start with docker-compose
docker-compose -f docker-compose.dev.yml up --build

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping container..."
    docker-compose -f docker-compose.dev.yml down
    echo "✅ Container stopped"
}

# Register cleanup on exit
trap cleanup EXIT

