# ChainRice Ecosystem - Accounting & Cat Cafe System

.PHONY: help install build start stop clean proto frontend go-api python-ai meowtopia docker all-services

# Default target
help:
	@echo "🐱🍚 ChainRice Ecosystem - Команди:"
	@echo ""
	@echo "📦 Встановлення та збірка:"
	@echo "  make install     - Встановити всі залежності"
	@echo "  make build       - Зібрати всі сервіси"
	@echo "  make proto       - Генерувати protobuf файли"
	@echo ""
	@echo "🚀 Запуск сервісів:"
	@echo "  make start       - Запустити всі сервіси"
	@echo "  make docker      - Запустити через Docker"
	@echo "  make chainrice   - Запустити ChainRice (бухгалтерія)"
	@echo "  make meowtopia   - Запустити Meowtopia (кафе з котами)"
	@echo ""
	@echo "🔧 Окремі сервіси:"
	@echo "  make frontend    - Запустити ChainRice фронтенд (порт 5173)"
	@echo "  make meowtopia-frontend - Запустити Meowtopia фронтенд (порт 5174)"
	@echo "  make go-api      - Запустити Go API (порт 8004)"
	@echo "  make python-ai   - Запустити Python AI (порт 8005)"
	@echo "  make blockchain  - Запустити блокчейн ноду (порт 1317)"
	@echo ""
	@echo "🛑 Зупинка:"
	@echo "  make stop        - Зупинити всі сервіси"
	@echo "  make clean       - Очистити збірку"
	@echo ""
	@echo "🌐 Відкрити інтерфейси:"
	@echo "  make open        - Відкрити всі інтерфейси в браузері"

# Installation
install:
	@echo "📦 Встановлення залежностей..."
	@cd frontend && npm install
	@cd ../meowtopia && npm install
	@cd go && go mod tidy
	@cd python && pip install -r requirements.txt
	@echo "✅ Всі залежності встановлено"

# Build
build: proto
	@echo "🔨 Збірка сервісів..."
	@cd go && go build -o build/accounting-api ./cmd/accounting-api
	@echo "✅ Збірка завершена"

# Generate protobuf files
proto:
	@echo "📡 Генерація protobuf файлів..."
	@cd proto && buf generate
	@echo "✅ Protobuf файли згенеровано"

# Start services
start:
	@echo "🚀 Запуск всіх сервісів..."
	@make -j5 blockchain go-api python-ai frontend meowtopia-frontend
	@echo "✅ Всі сервіси запущено"

# Docker
docker:
	@echo "🐳 Запуск через Docker..."
	@docker-compose up --build

# ChainRice services
chainrice:
	@echo "🍚 Запуск ChainRice (бухгалтерія)..."
	@make -j3 blockchain go-api python-ai frontend

# Meowtopia services  
meowtopia:
	@echo "🐱 Запуск Meowtopia (кафе з котами)..."
	@make -j2 blockchain meowtopia-api meowtopia-frontend

# Frontend
frontend:
	@echo "🌐 Запуск ChainRice фронтенду..."
	@cd frontend && npm run dev

# Meowtopia Frontend
meowtopia-frontend:
	@echo "🐱 Запуск Meowtopia фронтенду..."
	@cd ../meowtopia && npm run dev -- --port 5174

# Blockchain
blockchain:
	@echo "⛓️ Запуск блокчейн ноди..."
	@cd go && ./build/chainrice start --home ./chain-data

# Go API
go-api: build
	@echo "🔧 Запуск Go API сервера..."
	@cd go && ./build/accounting-api

# Python AI
python-ai:
	@echo "🤖 Запуск Python AI сервісу..."
	@cd python && python main.py

# Stop services
stop:
	@echo "🛑 Зупинка всіх сервісів..."
	@pkill -f "npm run dev" || true
	@pkill -f "accounting-api" || true
	@pkill -f "python main.py" || true
	@echo "✅ Всі сервіси зупинено"

# Clean
clean:
	@echo "🧹 Очищення збірки..."
	@rm -rf go/build
	@rm -rf frontend/dist
	@rm -rf python/__pycache__
	@rm -f *.db
	@echo "✅ Очищення завершено"

# Open interfaces
open:
	@echo "🌐 Відкриття інтерфейсів..."
	@xdg-open http://localhost:5173 2>/dev/null || open http://localhost:5173 2>/dev/null || echo "Відкрийте http://localhost:5173 в браузері"
	@xdg-open http://localhost:5174 2>/dev/null || open http://localhost:5174 2>/dev/null || echo "Відкрийте http://localhost:5174 в браузері"
	@echo ""
	@echo "🍚 ChainRice (Бухгалтерія):"
	@echo "  📊 Фронтенд: http://localhost:5173"
	@echo "  🔧 API: http://localhost:8004"
	@echo "  🤖 AI: http://localhost:8005"
	@echo ""
	@echo "🐱 Meowtopia (Кафе з котами):"
	@echo "  🏠 Фронтенд: http://localhost:5174"
	@echo "  🔧 API: http://localhost:8006"
	@echo ""
	@echo "⛓️ Блокчейн:"
	@echo "  🌐 REST API: http://localhost:1317"
	@echo "  🔗 RPC: http://localhost:26657"

# Development mode with auto-reload
dev:
	@echo "🔄 Запуск в режимі розробки..."
	@make start

# Database operations
db-init:
	@echo "🗄️ Ініціалізація бази даних..."
	@cd go && go run cmd/accounting-api/main.go --init-db

# Test
test:
	@echo "🧪 Запуск тестів..."
	@cd go && go test ./...
	@cd frontend && npm test

# Status check
status:
	@echo "📊 Статус сервісів:"
	@echo "ChainRice Фронтенд (5173):" && curl -s http://localhost:5173 > /dev/null && echo "✅ Активний" || echo "❌ Неактивний"
	@echo "Meowtopia Фронтенд (5174):" && curl -s http://localhost:5174 > /dev/null && echo "✅ Активний" || echo "❌ Неактивний"
	@echo "ChainRice API (8004):" && curl -s http://localhost:8004/health > /dev/null && echo "✅ Активний" || echo "❌ Неактивний"
	@echo "Meowtopia API (8006):" && curl -s http://localhost:8006/health > /dev/null && echo "✅ Активний" || echo "❌ Неактивний"
	@echo "Python AI (8005):" && curl -s http://localhost:8005/health > /dev/null && echo "✅ Активний" || echo "❌ Неактивний"
	@echo "Блокчейн (1317):" && curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null && echo "✅ Активний" || echo "❌ Неактивний"
