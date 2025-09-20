# 🌍 Rice-Dev Ecosystem - Main Management

.PHONY: help up down open install build start stop clean proto frontend go-api python-ai meowtopia docker all-services chainrice meowtopia blockchain dev bridges nix docker-all

# Default target
help:
	@echo "🌍 Rice-Dev Ecosystem - Management Commands:"
	@echo ""
	@echo "📦 Installation & Build:"
	@echo "  make up          - Install everything and start all services"
	@echo "  make install     - Install all dependencies for all applications"
	@echo "  make build       - Build all services"
	@echo "  make proto       - Generate protobuf files for all applications"
	@echo "  make nix         - Build with Nix packages"
	@echo ""
	@echo "🚀 Service Management:"
	@echo "  make start       - Start entire ecosystem"
	@echo "  make down        - Stop all containers and services"
	@echo "  make docker      - Start via Docker Compose"
	@echo "  make docker-all  - Start all services via Docker"
	@echo "  make chainrice   - Start only ChainRice"
	@echo "  make meowtopia   - Start only Meowtopia"
	@echo ""
	@echo "🔧 Individual Services:"
	@echo "  make blockchain  - Start blockchain node"
	@echo "  make frontend    - Start ChainRice frontend"
	@echo "  make meowtopia-frontend - Start Meowtopia frontend"
	@echo "  make go-api      - Start ChainRice Go API"
	@echo "  make meowtopia-api - Start Meowtopia Go API"
	@echo "  make python-ai   - Start Python AI service"
	@echo ""
	@echo "🌉 Bridge Services:"
	@echo "  make bridges     - Start all bridge services"
	@echo "  make dotnet-bridge - Start .NET bridge"
	@echo "  make beam-bridge - Start BEAM (Erlang/Elixir) bridge"
	@echo "  make python-bridge - Start Python bridge"
	@echo "  make jvm-bridge  - Start JVM bridge"
	@echo "  make php-bridge  - Start PHP bridge"
	@echo ""
	@echo "🛑 Management:"
	@echo "  make stop        - Stop all services"
	@echo "  make clean       - Clean all builds"
	@echo "  make status      - Check status of all services"
	@echo "  make check-services - Check status via script"
	@echo ""
	@echo "🌐 Interfaces:"
	@echo "  make open        - Open all interfaces in browser"
	@echo "  make open-chainrice - Open ChainRice interfaces"
	@echo "  make open-meowtopia - Open Meowtopia interfaces"
	@echo "  make open-bridges - Open bridge interfaces"
	@echo ""
	@echo "🚀 Quick Commands:"
	@echo "  make dev         - Development mode with hot reload and auto-open"
	@echo "  make quick       - Quick start (install + build + start + open)"
	@echo "  make dev-setup   - Development environment setup"
	@echo "  make full-reset  - Full ecosystem reset"
	@echo "  make backup      - Create database backup"
	@echo "  make show-logs   - Show logs of all services"

# Main commands
up: install build start open
	@echo "✅ Rice-Dev ecosystem is up and running!"

down: stop
	@echo "✅ Rice-Dev ecosystem is down"

# Installation
install:
	@echo "📦 Installing dependencies for entire ecosystem..."
	@echo "🔧 Installing ChainRice..."
	@cd apps/chain-rice && make install
	@echo "🐱 Installing Meowtopia..."
	@cd apps/meowtopia && make install
	@echo "📦 Installing Go dependencies..."
	@cd apps/chain-rice/go && go mod tidy
	@echo "📦 Installing Python dependencies..."
	@cd apps/chain-rice/python && pip install -r requirements.txt
	@echo "✅ All dependencies installed"

# Build
build: proto
	@echo "🔨 Збірка всієї екосистеми..."
	@cd apps/chain-rice && make build
	@cd apps/meowtopia && make build
	@echo "✅ Вся екосистема зібрана"

# Generate protobuf files
proto:
	@echo "📡 Генерація protobuf файлів для всіх додатків..."
	@cd apps/chain-rice && make proto
	@echo "✅ Protobuf файли згенеровано"

# Start entire ecosystem
start:
	@echo "🚀 Запуск всієї екосистеми Rice-Dev..."
	@make -j6 blockchain chainrice-go-api meowtopia-go-api python-ai chainrice-frontend meowtopia-frontend
	@echo "✅ Вся екосистема запущена"

# Docker
docker:
	@echo "🐳 Запуск через Docker Compose..."
	@cd apps/chain-rice && docker-compose up --build -d
	@echo "✅ Docker контейнери запущені"

# ChainRice ecosystem
chainrice:
	@echo "🍚 Запуск ChainRice екосистеми..."
	@make -j4 blockchain chainrice-go-api python-ai chainrice-frontend
	@echo "✅ ChainRice запущений"

# Meowtopia ecosystem
meowtopia:
	@echo "🐱 Запуск Meowtopia екосистеми..."
	@make -j3 blockchain meowtopia-go-api meowtopia-frontend
	@echo "✅ Meowtopia запущений"

# Individual services
blockchain:
	@echo "⛓️ Запуск блокчейн ноди..."
	@cd apps/chain-rice/go && ./build/chainrice start --home ./chain-data

chainrice-go-api:
	@echo "🔧 Запуск ChainRice Go API..."
	@cd apps/chain-rice/go && ./build/accounting-api

meowtopia-go-api:
	@echo "🔧 Запуск Meowtopia Go API..."
	@cd apps/chain-rice/go && ./build/meowtopia-api

python-ai:
	@echo "🤖 Запуск Python AI сервісу..."
	@cd apps/chain-rice/python && python main.py

chainrice-frontend:
	@echo "🌐 Запуск ChainRice фронтенду..."
	@cd apps/chain-rice/frontend && npm run dev

meowtopia-frontend:
	@echo "🐱 Запуск Meowtopia фронтенду..."
	@cd apps/meowtopia && npm run dev -- --port 5174

# Bridge services
bridges:
	@echo "🌉 Starting all bridge services..."
	@make -j5 dotnet-bridge beam-bridge python-bridge jvm-bridge php-bridge
	@echo "✅ All bridge services started"

dotnet-bridge:
	@echo "🔧 Starting .NET bridge..."
	@cd stacks/backend/.NET && dotnet run --project ChainRice.Bridge.csproj

beam-bridge:
	@echo "🔧 Starting BEAM bridge..."
	@cd stacks/backend/BEAM && mix run --no-halt

python-bridge:
	@echo "🔧 Starting Python bridge..."
	@cd stacks/backend/CPython && python -m chainrice_bridge

jvm-bridge:
	@echo "🔧 Starting JVM bridge..."
	@cd stacks/backend/JVM && ./gradlew run

php-bridge:
	@echo "🔧 Starting PHP bridge..."
	@cd stacks/backend/PHP && php -S localhost:8086

# Nix commands
nix:
	@echo "📦 Building with Nix packages..."
	@nix develop -f stacks/tools/DEV/packages/flake.nix
	@echo "✅ Nix development environment ready"

# Docker all services
docker-all:
	@echo "🐳 Starting all services via Docker..."
	@cd stacks/tools/DEV/docker && docker-compose up --build -d
	@echo "✅ All services started via Docker"

# Aliases for convenience
frontend: chainrice-frontend
go-api: chainrice-go-api

# Stop all services
stop:
	@echo "🛑 Зупинка всіх сервісів..."
	@pkill -f "chainrice" || true
	@pkill -f "accounting-api" || true
	@pkill -f "meowtopia-api" || true
	@pkill -f "python main.py" || true
	@pkill -f "npm run dev" || true
	@docker-compose -f apps/chain-rice/docker-compose.yml down 2>/dev/null || true
	@echo "✅ Всі сервіси зупинено"

# Clean all builds
clean:
	@echo "🧹 Очищення всіх збірок..."
	@cd apps/chain-rice && make clean
	@cd apps/meowtopia && make clean
	@rm -rf apps/chain-rice/*.db
	@rm -rf apps/meowtopia/*.db
	@echo "✅ Всі збірки очищено"

# Open interfaces
open:
	@echo "🌐 Opening all development interfaces..."
	@xdg-open http://localhost:5173 2>/dev/null || open http://localhost:5173 2>/dev/null || echo "Open http://localhost:5173 in browser"
	@xdg-open http://localhost:5174 2>/dev/null || open http://localhost:5174 2>/dev/null || echo "Open http://localhost:5174 in browser"
	@xdg-open http://localhost:1317 2>/dev/null || open http://localhost:1317 2>/dev/null || echo "Open http://localhost:1317 in browser"
	@echo ""
	@echo "🍚 ChainRice (Accounting):"
	@echo "  📊 Frontend: http://localhost:5173"
	@echo "  🔧 API: http://localhost:8004"
	@echo "  🤖 AI: http://localhost:8005"
	@echo ""
	@echo "🐱 Meowtopia (Cat Cafe):"
	@echo "  🏠 Frontend: http://localhost:5174"
	@echo "  🔧 API: http://localhost:8006"
	@echo ""
	@echo "⛓️ Blockchain:"
	@echo "  🌐 REST API: http://localhost:1317"
	@echo "  🔗 RPC: http://localhost:26657"

open-chainrice:
	@echo "🍚 Відкриття ChainRice інтерфейсів..."
	@xdg-open http://localhost:5173 2>/dev/null || open http://localhost:5173 2>/dev/null || echo "Відкрийте http://localhost:5173 в браузері"
	@xdg-open http://localhost:8004 2>/dev/null || open http://localhost:8004 2>/dev/null || echo "Відкрийте http://localhost:8004 в браузері"
	@xdg-open http://localhost:8005 2>/dev/null || open http://localhost:8005 2>/dev/null || echo "Відкрийте http://localhost:8005 в браузері"

open-meowtopia:
	@echo "🐱 Відкриття Meowtopia інтерфейсів..."
	@xdg-open http://localhost:5174 2>/dev/null || open http://localhost:5174 2>/dev/null || echo "Відкрийте http://localhost:5174 в браузері"
	@xdg-open http://localhost:8006 2>/dev/null || open http://localhost:8006 2>/dev/null || echo "Відкрийте http://localhost:8006 в браузері"

open-bridges:
	@echo "🌉 Opening bridge interfaces..."
	@xdg-open http://localhost:8082 2>/dev/null || open http://localhost:8082 2>/dev/null || echo "Open .NET bridge: http://localhost:8082"
	@xdg-open http://localhost:8083 2>/dev/null || open http://localhost:8083 2>/dev/null || echo "Open BEAM bridge: http://localhost:8083"
	@xdg-open http://localhost:8084 2>/dev/null || open http://localhost:8084 2>/dev/null || echo "Open Python bridge: http://localhost:8084"
	@xdg-open http://localhost:8085 2>/dev/null || open http://localhost:8085 2>/dev/null || echo "Open JVM bridge: http://localhost:8085"
	@xdg-open http://localhost:8086 2>/dev/null || open http://localhost:8086 2>/dev/null || echo "Open PHP bridge: http://localhost:8086"

# Status check
status:
	@echo "📊 Status of all Rice-Dev ecosystem services:"
	@echo ""
	@echo "🍚 ChainRice:"
	@echo "  Frontend (5173):" && curl -s http://localhost:5173 > /dev/null 2>&1 && echo "    ✅ Active" || echo "    ❌ Inactive"
	@echo "  API (8004):" && curl -s http://localhost:8004/health > /dev/null 2>&1 && echo "    ✅ Active" || echo "    ❌ Inactive"
	@echo "  AI (8005):" && curl -s http://localhost:8005/health > /dev/null 2>&1 && echo "    ✅ Active" || echo "    ❌ Inactive"
	@echo ""
	@echo "🐱 Meowtopia:"
	@echo "  Frontend (5174):" && curl -s http://localhost:5174 > /dev/null 2>&1 && echo "    ✅ Active" || echo "    ❌ Inactive"
	@echo "  API (8006):" && curl -s http://localhost:8006/health > /dev/null 2>&1 && echo "    ✅ Active" || echo "    ❌ Inactive"
	@echo ""
	@echo "⛓️ Blockchain:"
	@echo "  REST API (1317):" && curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null 2>&1 && echo "    ✅ Active" || echo "    ❌ Inactive"
	@echo "  RPC (26657):" && curl -s http://localhost:26657/status > /dev/null 2>&1 && echo "    ✅ Active" || echo "    ❌ Inactive"

# Development mode with hot reload and auto-open
dev:
	@echo "🔄 Starting development mode with hot reload..."
	@make install
	@make build
	@echo "🚀 Starting services with hot reload..."
	@make -j6 blockchain chainrice-go-api meowtopia-go-api python-ai chainrice-frontend meowtopia-frontend &
	@sleep 8
	@echo "🌐 Opening development interfaces..."
	@make open
	@echo "✅ Development mode active with hot reload and interfaces open"

# Test all applications
test:
	@echo "🧪 Запуск тестів для всієї екосистеми..."
	@cd apps/chain-rice && make test
	@cd apps/meowtopia && make test
	@echo "✅ Всі тести пройдені"

# Database operations
db-init:
	@echo "🗄️ Ініціалізація баз даних..."
	@cd apps/chain-rice && make db-init
	@cd apps/meowtopia && make db-init
	@echo "✅ Бази даних ініціалізовані"

# Logs
logs:
	@echo "📋 Показ логів всіх сервісів..."
	@echo "ChainRice API логі:"
	@cd apps/chain-rice && make logs 2>/dev/null || echo "Логі недоступні"
	@echo "Meowtopia API логі:"
	@cd apps/meowtopia && make logs 2>/dev/null || echo "Логі недоступні"

# Reset everything
reset: stop clean
	@echo "🔄 Повний скид екосистеми..."
	@make install
	@make build
	@echo "✅ Екосистема повністю скинута та готова до запуску"

# Quick start (install + build + start + open)
quick:
	@echo "⚡ Швидкий запуск екосистеми..."
	@make install
	@make build
	@make start &
	@sleep 10
	@make open
	@echo "✅ Екосистема запущена та відкрита в браузері"

# Check if services are running
check-services:
	@echo "🔍 Перевірка статусу сервісів..."
	@./check-status.sh

# Development setup
dev-setup:
	@echo "🛠️ Налаштування середовища розробки..."
	@make install
	@make proto
	@make build
	@echo "✅ Середовище розробки готове"

# Full reset
full-reset: stop clean
	@echo "🔄 Повний скид екосистеми..."
	@make install
	@make build
	@make db-init
	@echo "✅ Екосистема повністю скинута та готова до запуску"

# Show logs
show-logs:
	@echo "📋 Показ логів сервісів..."
	@echo "ChainRice API логі:"
	@cd apps/chain-rice && make logs 2>/dev/null || echo "Логі недоступні"
	@echo "Meowtopia API логі:"
	@cd apps/meowtopia && make logs 2>/dev/null || echo "Логі недоступні"

# Backup databases
backup:
	@echo "💾 Створення резервної копії баз даних..."
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@cp apps/chain-rice/*.db backups/$(shell date +%Y%m%d_%H%M%S)/ 2>/dev/null || echo "Немає баз даних для backup"
	@echo "✅ Backup створено"

# Restore databases
restore:
	@echo "📂 Відновлення баз даних..."
	@ls backups/ 2>/dev/null || echo "Немає backup файлів"
	@echo "Використовуйте: make restore-backup BACKUP_DIR=назва_папки"