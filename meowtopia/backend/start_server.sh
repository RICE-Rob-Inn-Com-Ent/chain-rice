#!/bin/bash

# Meowtopia Backend Server Startup Script
# This script starts the FastAPI server with Swagger documentation

echo "🐱 Starting Meowtopia Backend Server..."
echo ""

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "❌ Poetry is not installed. Please install Poetry first:"
    echo "   curl -sSL https://install.python-poetry.org | python3 -"
    exit 1
fi

# Check if we're in the backend directory
if [ ! -f "pyproject.toml" ]; then
    echo "❌ Please run this script from the meowtopia/backend directory"
    exit 1
fi

# Install dependencies if needed
echo "📦 Installing dependencies..."
poetry install

echo ""
echo "🚀 Starting FastAPI server..."
echo ""
echo "📚 Swagger Documentation will be available at:"
echo "   🌐 Swagger UI: http://localhost:8000/docs"
echo "   📖 ReDoc:      http://localhost:8000/redoc"
echo "   📋 OpenAPI:    http://localhost:8000/openapi.json"
echo ""
echo "🎮 API Endpoints:"
echo "   🔐 Auth:       http://localhost:8000/api/v1/auth/"
echo "   🐱 Cats:       http://localhost:8000/api/v1/cats/"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 