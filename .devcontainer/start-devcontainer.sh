#!/bin/bash

echo "🚀 Starting Rice-Mono Dev Container..."

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
  echo "❌ Docker is not installed!"
  echo "Please install Docker first:"
  echo "sudo pacman -S docker docker-compose docker-buildx"
  echo "sudo systemctl enable docker.service"
  echo "sudo systemctl start docker.service"
  echo "sudo usermod -aG docker \$USER"
  echo "Then log out and log back in, or run: newgrp docker"
  exit 1
fi

# Check if Docker is running
if ! docker info &>/dev/null; then
  echo "❌ Docker is not running!"
  echo "Please start Docker:"
  echo "sudo systemctl start docker.service"
  exit 1
fi

echo "✅ Docker is available"

# Build and start services
echo "🔨 Building devcontainer..."
docker compose build devcontainer

echo "🚀 Starting all services..."
docker compose up -d

echo "📊 Service Status:"
docker compose ps

echo ""
echo "🎉 Devcontainer is ready!"
echo ""
echo "📋 Service URLs & Credentials:"
echo "PostgreSQL: localhost:5432 (rice_user/rice_password)"
echo "MongoDB: localhost:27017 (rice_user/rice_password)"
echo "Redis: localhost:6379 (password: rice_password)"
echo "Grafana: http://localhost:3000 (admin/admin)"
echo "Prometheus: http://localhost:9090"
echo ""
echo "💻 To enter the container:"
echo "docker compose exec devcontainer bash"
