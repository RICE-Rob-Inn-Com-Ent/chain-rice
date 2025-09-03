#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Set default environment variables
export BUILD_ENV=${BUILD_ENV:-development}
export BUILD_NUMBER=${BUILD_NUMBER:-1}
export BUILD_DATE=${BUILD_DATE:-$(date +%Y-%m-%d)}
export BUILD_VERSION=${BUILD_VERSION:-0.1.0}
export BUILD_COMMIT=${BUILD_COMMIT:-dev}
export API_PORT=${API_PORT:-8000}
export POSTGRES_DB=${POSTGRES_DB:-meowtopia}
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
export POSTGRES_HOST=${POSTGRES_HOST:-meowtopia-db}
export BLOCKCHAIN_DATA_DIR=${BLOCKCHAIN_DATA_DIR:-./blockchain-data}

show_help() {
    echo -e "${BLUE}🐳 Docker Helper Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./scripts/docker-helper.sh [command] [profile]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  up        - Start services (default: app profile)"
    echo "  down      - Stop services"
    echo "  restart   - Restart services"
    echo "  logs      - Show logs"
    echo "  build     - Build services"
    echo "  status    - Show service status"
    echo ""
    echo -e "${YELLOW}Profiles:${NC}"
    echo "  app       - Web frontend, backend, and database (default)"
    echo "  blockchain - Blockchain service only"
    echo "  all       - All services"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./scripts/docker-helper.sh up           # Start app services"
    echo "  ./scripts/docker-helper.sh up blockchain # Start blockchain only"
    echo "  ./scripts/docker-helper.sh up all       # Start all services"
    echo "  ./scripts/docker-helper.sh logs app     # Show app service logs"
}

case "${1:-up}" in
    "up")
        profile="${2:-app}"
        echo -e "${BLUE}🚀 Starting services with profile: $profile${NC}"
        docker compose --profile "$profile" up -d
        ;;
    "down")
        echo -e "${YELLOW}🛑 Stopping all services${NC}"
        docker compose down
        ;;
    "restart")
        profile="${2:-app}"
        echo -e "${BLUE}🔄 Restarting services with profile: $profile${NC}"
        docker compose --profile "$profile" restart
        ;;
    "logs")
        profile="${2:-app}"
        echo -e "${BLUE}📝 Showing logs for profile: $profile${NC}"
        if [ "$profile" = "all" ]; then
            docker compose logs -f
        else
            docker compose --profile "$profile" logs -f
        fi
        ;;
    "build")
        profile="${2:-app}"
        echo -e "${BLUE}🔨 Building services with profile: $profile${NC}"
        docker compose --profile "$profile" build
        ;;
    "status")
        echo -e "${BLUE}📊 Service Status${NC}"
        docker compose ps
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
