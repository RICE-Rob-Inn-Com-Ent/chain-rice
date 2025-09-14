# 🌍 Rice-Dev Ecosystem - Головне управління

.PHONY: help install build start stop clean proto frontend go-api python-ai meowtopia docker all-services chainrice meowtopia blockchain

# Default target
help:
	@echo "🌍 Rice-Dev Ecosystem - Команди управління:"
	@echo ""
	@echo "📦 Встановлення та збірка:"
	@echo "  make install     - Встановити всі залежності для всіх додатків"
	@echo "  make build       - Зібрати всі сервіси"
	@echo "  make proto       - Генерувати protobuf файли для всіх додатків"
	@echo ""
	@echo "🚀 Запуск екосистеми:"
	@echo "  make start       - Запустити всю екосистему"
	@echo "  make docker      - Запустити через Docker Compose"
	@echo "  make chainrice   - Запустити тільки ChainRice"
	@echo "  make meowtopia   - Запустити тільки Meowtopia"
	@echo ""
	@echo "🔧 Окремі сервіси:"
	@echo "  make blockchain  - Запустити блокчейн ноду"
	@echo "  make frontend    - Запустити ChainRice фронтенд"
	@echo "  make meowtopia-frontend - Запустити Meowtopia фронтенд"
	@echo "  make go-api      - Запустити ChainRice Go API"
	@echo "  make meowtopia-api - Запустити Meowtopia Go API"
	@echo "  make python-ai   - Запустити Python AI сервіс"
	@echo ""
	@echo "🛑 Управління:"
	@echo "  make stop        - Зупинити всі сервіси"
	@echo "  make clean       - Очистити всі збірки"
	@echo "  make status      - Перевірити статус всіх сервісів"
	@echo "  make check-services - Перевірити статус через скрипт"
	@echo ""
	@echo "🌐 Інтерфейси:"
	@echo "  make open        - Відкрити всі інтерфейси в браузері"
	@echo "  make open-chainrice - Відкрити ChainRice інтерфейси"
	@echo "  make open-meowtopia - Відкрити Meowtopia інтерфейси"
	@echo ""
	@echo "🚀 Швидкі команди:"
	@echo "  make quick       - Швидкий запуск (встановити + запустити + відкрити)"
	@echo "  make dev-setup   - Налаштування середовища розробки"
	@echo "  make full-reset  - Повний скид екосистеми"
	@echo "  make backup      - Створити backup баз даних"
	@echo "  make show-logs   - Показати логи всіх сервісів"

# Installation
install:
	@echo "📦 Встановлення залежностей для всієї екосистеми..."
	@echo "🔧 Встановлення ChainRice..."
	@cd apps/chain-rice && make install
	@echo "🐱 Встановлення Meowtopia..."
	@cd apps/meowtopia && make install
	@echo "📦 Встановлення Go залежностей..."
	@cd apps/chain-rice/go && go mod tidy
	@echo "📦 Встановлення Python залежностей..."
	@cd apps/chain-rice/python && pip install -r requirements.txt
	@echo "✅ Всі залежності встановлено"

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
	@echo "🌐 Відкриття всіх інтерфейсів..."
	@xdg-open http://localhost:5173 2>/dev/null || open http://localhost:5173 2>/dev/null || echo "Відкрийте http://localhost:5173 в браузері"
	@xdg-open http://localhost:5174 2>/dev/null || open http://localhost:5174 2>/dev/null || echo "Відкрийте http://localhost:5174 в браузері"
	@xdg-open http://localhost:1317 2>/dev/null || open http://localhost:1317 2>/dev/null || echo "Відкрийте http://localhost:1317 в браузері"
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

open-chainrice:
	@echo "🍚 Відкриття ChainRice інтерфейсів..."
	@xdg-open http://localhost:5173 2>/dev/null || open http://localhost:5173 2>/dev/null || echo "Відкрийте http://localhost:5173 в браузері"
	@xdg-open http://localhost:8004 2>/dev/null || open http://localhost:8004 2>/dev/null || echo "Відкрийте http://localhost:8004 в браузері"
	@xdg-open http://localhost:8005 2>/dev/null || open http://localhost:8005 2>/dev/null || echo "Відкрийте http://localhost:8005 в браузері"

open-meowtopia:
	@echo "🐱 Відкриття Meowtopia інтерфейсів..."
	@xdg-open http://localhost:5174 2>/dev/null || open http://localhost:5174 2>/dev/null || echo "Відкрийте http://localhost:5174 в браузері"
	@xdg-open http://localhost:8006 2>/dev/null || open http://localhost:8006 2>/dev/null || echo "Відкрийте http://localhost:8006 в браузері"

# Status check
status:
	@echo "📊 Статус всіх сервісів Rice-Dev екосистеми:"
	@echo ""
	@echo "🍚 ChainRice:"
	@echo "  Фронтенд (5173):" && curl -s http://localhost:5173 > /dev/null 2>&1 && echo "    ✅ Активний" || echo "    ❌ Неактивний"
	@echo "  API (8004):" && curl -s http://localhost:8004/health > /dev/null 2>&1 && echo "    ✅ Активний" || echo "    ❌ Неактивний"
	@echo "  AI (8005):" && curl -s http://localhost:8005/health > /dev/null 2>&1 && echo "    ✅ Активний" || echo "    ❌ Неактивний"
	@echo ""
	@echo "🐱 Meowtopia:"
	@echo "  Фронтенд (5174):" && curl -s http://localhost:5174 > /dev/null 2>&1 && echo "    ✅ Активний" || echo "    ❌ Неактивний"
	@echo "  API (8006):" && curl -s http://localhost:8006/health > /dev/null 2>&1 && echo "    ✅ Активний" || echo "    ❌ Неактивний"
	@echo ""
	@echo "⛓️ Блокчейн:"
	@echo "  REST API (1317):" && curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null 2>&1 && echo "    ✅ Активний" || echo "    ❌ Неактивний"
	@echo "  RPC (26657):" && curl -s http://localhost:26657/status > /dev/null 2>&1 && echo "    ✅ Активний" || echo "    ❌ Неактивний"

# Development mode
dev:
	@echo "🔄 Запуск в режимі розробки..."
	@make start

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