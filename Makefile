.PHONY: help up down restart logs ps clean web-dev web-build backend gods monitoring all

# Default target
help:
	@echo "🐳 Rice Mono - Docker & Development Commands"
	@echo ""
	@echo "📦 Docker Commands:"
	@echo "  make up           - Start backend + gods + monitoring (19 services)"
	@echo "  make down         - Stop all services"
	@echo "  make restart      - Restart all services"
	@echo "  make logs         - View logs (all services)"
	@echo "  make ps           - Show service status"
	@echo "  make clean        - Stop and remove everything (including volumes)"
	@echo ""
	@echo "🎨 Frontend Commands:"
	@echo "  make web-dev      - Start frontend locally (yarn dev) + AI models"
	@echo "  make web-build    - Build frontend locally"
	@echo "  make web-docker   - Start frontend in Docker (--profile web)"
	@echo ""
	@echo "🎯 Profile Commands:"
	@echo "  make backend      - Start only backend core services"
	@echo "  make gods         - Start only gods AI services"
	@echo "  make monitoring   - Start only monitoring stack"
	@echo "  make all          - Start everything (backend + gods + monitoring + web)"
	@echo ""
	@echo "🔧 Utility Commands:"
	@echo "  make build        - Rebuild all services"
	@echo "  make build-nocache- Rebuild without cache"
	@echo "  make prune        - Clean Docker system"

# Start default services (backend + gods + monitoring)
up:
	@echo "🚀 Starting backend + gods + monitoring (19 services)..."
	docker-compose up -d

# Stop all services
down:
	@echo "🛑 Stopping all services..."
	docker-compose --profile web down

# Restart all services
restart:
	@echo "🔄 Restarting services..."
	docker-compose restart

# View logs
logs:
	docker-compose logs -f

# Show status
ps:
	docker-compose --profile web ps

# Clean everything
clean:
	@echo "🗑️  Removing all containers and volumes..."
	docker-compose --profile web down -v
	@echo "✅ Cleaned!"

# Start frontend locally with yarn dev + AI models
web-dev:
	@echo "🎨 Starting frontend locally (yarn dev + AI models)..."
	@echo "🤖 Starting AI models in Docker..."
	@docker-compose up -d thoth ra isis bastet maat khnum
	@echo "📦 Installing dependencies..."
	@cd . && yarn install
	@echo ""
	@echo "✅ AI Models started in Docker!"
	@echo "🚀 Starting UI Kit (Vite) and Next.js..."
	@cd . && yarn dev

# Build frontend locally
web-build:
	@echo "🏗️  Building frontend locally..."
	@cd . && yarn build

# Start frontend in Docker
web-docker:
	@echo "🐳 Starting frontend in Docker..."
	docker-compose --profile web up -d ui-kit nextjs-web

# Start only backend services
backend:
	@echo "🔧 Starting backend core services..."
	docker-compose up -d mongodb postgres data graphql bot-core bot-integrations

# Start only gods services
gods:
	@echo "⚱️  Starting gods AI services..."
	docker-compose up -d thoth ra isis bastet maat khnum

# Start only monitoring stack
monitoring:
	@echo "📊 Starting monitoring stack..."
	docker-compose up -d traefik prometheus loki grafana elasticsearch logstash jaeger

# Start everything (including web in Docker)
all:
	@echo "🚀 Starting ALL services (21 services)..."
	docker-compose --profile web up -d

# Rebuild all services
build:
	@echo "🏗️  Rebuilding all services..."
	docker-compose --profile web build

# Rebuild without cache
build-nocache:
	@echo "🏗️  Rebuilding all services (no cache)..."
	docker-compose --profile web build --no-cache

# Clean Docker system
prune:
	@echo "🧹 Cleaning Docker system..."
	docker system prune -af --volumes
	@echo "✅ Docker system cleaned!"
