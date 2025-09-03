#!/bin/bash

# 🚀 Cross-platform Docker build script for Chain Rice
# This script ensures builds work on Windows, macOS, and Linux

set -e

echo "🔧 Building Chain Rice for multiple platforms..."

# 🔧 Set up buildx if not already done
if ! docker buildx ls | grep -q "multiplatform"; then
    echo "📦 Creating multiplatform builder..."
    docker buildx create --name multiplatform --use
fi

# 🎯 Build for multiple platforms
echo "📦 Building frontend for linux/amd64 and linux/arm64..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag meowtopia-frontend:latest \
  --file meowtopia/frontend/web/Dockerfile.web.npm \
  ./meowtopia/frontend/web \
  --load

echo "🐍 Building backend for linux/amd64 and linux/arm64..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag meowtopia-backend:latest \
  --file meowtopia/backend/Dockerfile.backend \
  ./meowtopia/backend \
  --load

echo "⛓️ Building blockchain for linux/amd64 and linux/arm64..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag chain-rice-blockchain:latest \
  --file Dockerfile.blockchain \
  . \
  --load

echo "✅ Cross-platform build completed successfully!"
echo "🎉 All services are now compatible with Windows, macOS, and Linux"
echo ""
echo "🚀 To start the services, run:"
echo "   docker-compose --profile app up"
echo "   docker-compose --profile blockchain up"