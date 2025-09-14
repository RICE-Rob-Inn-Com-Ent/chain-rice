#!/bin/bash

# 🌍 Rice-Dev Ecosystem Quick Start Script

set -e

echo "🌍 Rice-Dev Ecosystem - Швидкий запуск"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    print_error "Makefile не знайдено. Запустіть скрипт з кореневого каталогу rice-dev"
    exit 1
fi

# Check system requirements
print_info "Перевірка системних вимог..."

# Check Go
if ! command -v go &> /dev/null; then
    print_error "Go не встановлено. Встановіть Go 1.21+"
    exit 1
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js не встановлено. Встановіть Node.js 18+"
    exit 1
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    print_error "Python3 не встановлено. Встановіть Python 3.11+"
    exit 1
fi

print_status "Системні вимоги перевірені"

# Ask user what they want to do
echo ""
echo "Що ви хочете зробити?"
echo "1) Швидкий запуск (встановити + запустити все)"
echo "2) Тільки встановити залежності"
echo "3) Тільки запустити сервіси"
echo "4) Запустити через Docker"
echo "5) Показати статус сервісів"
echo "6) Зупинити всі сервіси"
echo "7) Очистити збірки"
echo ""

read -p "Виберіть опцію (1-7): " choice

case $choice in
    1)
        print_info "Швидкий запуск екосистеми..."
        make install
        make build
        print_info "Запуск сервісів..."
        make start &
        print_info "Очікування запуску сервісів..."
        sleep 15
        print_info "Відкриття інтерфейсів..."
        make open
        print_status "Екосистема запущена та готова до використання!"
        ;;
    2)
        print_info "Встановлення залежностей..."
        make install
        print_status "Залежності встановлено"
        ;;
    3)
        print_info "Запуск сервісів..."
        make start
        ;;
    4)
        print_info "Запуск через Docker..."
        make docker
        print_info "Очікування запуску контейнерів..."
        sleep 20
        print_info "Відкриття інтерфейсів..."
        make open
        print_status "Docker контейнери запущені!"
        ;;
    5)
        print_info "Перевірка статусу сервісів..."
        make status
        ;;
    6)
        print_info "Зупинка всіх сервісів..."
        make stop
        print_status "Сервіси зупинено"
        ;;
    7)
        print_info "Очищення збірок..."
        make clean
        print_status "Збірки очищено"
        ;;
    *)
        print_error "Невірний вибір"
        exit 1
        ;;
esac

echo ""
print_info "Доступні інтерфейси:"
echo -e "${CYAN}🍚 ChainRice (Бухгалтерія):${NC}"
echo "  📊 Фронтенд: http://localhost:5173"
echo "  🔧 API: http://localhost:8004"
echo "  🤖 AI: http://localhost:8005"
echo ""
echo -e "${PURPLE}🐱 Meowtopia (Кафе з котами):${NC}"
echo "  🏠 Фронтенд: http://localhost:5174"
echo "  🔧 API: http://localhost:8006"
echo ""
echo -e "${YELLOW}⛓️ Блокчейн:${NC}"
echo "  🌐 REST API: http://localhost:1317"
echo "  🔗 RPC: http://localhost:26657"
echo ""
print_info "Для управління використовуйте: make help"
