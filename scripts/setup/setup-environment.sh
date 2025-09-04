#!/bin/bash

# 🛠️ Universal Environment Setup Script
# Prepares the development environment for all platforms

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🛠️ Setting up Chain Rice development environment...${NC}"

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*)    echo "windows";;
        MINGW*)     echo "windows";;
        MSYS*)      echo "windows";;
        *)          echo "unknown";;
    esac
}

OS=$(detect_os)
echo -e "${YELLOW}🖥️  Detected OS: $OS${NC}"

# Check if running in WSL
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    echo -e "${YELLOW}🐧 Running in WSL: $WSL_DISTRO_NAME${NC}"
    OS="wsl"
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Docker installation and status
check_docker() {
    echo -e "${YELLOW}🐳 Checking Docker installation...${NC}"
    
    if ! command_exists docker; then
        echo -e "${RED}❌ Docker is not installed!${NC}"
        echo -e "${YELLOW}📥 Please install Docker:${NC}"
        case $OS in
            "linux")
                echo "  • Ubuntu/Debian: sudo apt-get install docker.io"
                echo "  • CentOS/RHEL: sudo yum install docker"
                echo "  • Or visit: https://docs.docker.com/engine/install/"
                ;;
            "macos")
                echo "  • Download Docker Desktop from: https://www.docker.com/products/docker-desktop"
                ;;
            "windows"|"wsl")
                echo "  • Install Docker Desktop for Windows"
                echo "  • Enable WSL2 integration if using WSL"
                echo "  • Download from: https://www.docker.com/products/docker-desktop"
                ;;
        esac
        return 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running!${NC}"
        case $OS in
            "linux")
                echo -e "${YELLOW}🔧 Try: sudo systemctl start docker${NC}"
                echo -e "${YELLOW}🔧 Or: sudo service docker start${NC}"
                ;;
            "macos"|"windows"|"wsl")
                echo -e "${YELLOW}🔧 Please start Docker Desktop${NC}"
                ;;
        esac
        return 1
    fi
    
    echo -e "${GREEN}✅ Docker is installed and running${NC}"
    return 0
}

# Check Docker Compose
check_docker_compose() {
    echo -e "${YELLOW}🐳 Checking Docker Compose...${NC}"
    
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker Compose is not available!${NC}"
        echo -e "${YELLOW}📥 Please install Docker Compose or update Docker Desktop${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Docker Compose is available${NC}"
    return 0
}

# Check Git
check_git() {
    echo -e "${YELLOW}📝 Checking Git...${NC}"
    
    if ! command_exists git; then
        echo -e "${RED}❌ Git is not installed!${NC}"
        echo -e "${YELLOW}📥 Please install Git:${NC}"
        case $OS in
            "linux")
                echo "  • Ubuntu/Debian: sudo apt-get install git"
                echo "  • CentOS/RHEL: sudo yum install git"
                ;;
            "macos")
                echo "  • Install Xcode Command Line Tools: xcode-select --install"
                echo "  • Or install via Homebrew: brew install git"
                ;;
            "windows"|"wsl")
                echo "  • Download from: https://git-scm.com/download/win"
                echo "  • Or install via WSL: sudo apt-get install git"
                ;;
        esac
        return 1
    fi
    
    echo -e "${GREEN}✅ Git is installed${NC}"
    return 0
}

# Check Go (for blockchain)
check_go() {
    echo -e "${YELLOW}🐹 Checking Go...${NC}"
    
    if ! command_exists go; then
        echo -e "${YELLOW}⚠️  Go is not installed (needed for blockchain development)${NC}"
        echo -e "${YELLOW}📥 To install Go:${NC}"
        case $OS in
            "linux")
                echo "  • Download from: https://golang.org/dl/"
                echo "  • Or via package manager: sudo apt-get install golang-go"
                ;;
            "macos")
                echo "  • Download from: https://golang.org/dl/"
                echo "  • Or via Homebrew: brew install go"
                ;;
            "windows"|"wsl")
                echo "  • Download from: https://golang.org/dl/"
                echo "  • Or via WSL: sudo apt-get install golang-go"
                ;;
        esac
        return 1
    fi
    
    echo -e "${GREEN}✅ Go is installed${NC}"
    return 0
}

# Setup Docker buildx for multi-platform builds
setup_docker_buildx() {
    echo -e "${YELLOW}🔧 Setting up Docker Buildx for multi-platform builds...${NC}"
    
    if ! docker buildx ls | grep -q "multiplatform"; then
        echo -e "${YELLOW}📦 Creating multiplatform builder...${NC}"
        docker buildx create --name multiplatform --use
    else
        echo -e "${GREEN}✅ Multiplatform builder already exists${NC}"
    fi
}

# Create necessary directories
create_directories() {
    echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
    
    mkdir -p blockchain-data
    mkdir -p meowtopia/backend/logs
    mkdir -p meowtopia/frontend/web/logs
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Set up environment file if it doesn't exist
setup_env_file() {
    echo -e "${YELLOW}⚙️  Setting up environment configuration...${NC}"
    
    if [[ ! -f .env ]]; then
        if [[ -f env.example ]]; then
            cp env.example .env
            echo -e "${GREEN}✅ Created .env file from env.example${NC}"
        else
            cat > .env << EOF
# Chain Rice Development Environment
BUILD_ENV=development
BUILD_NUMBER=1
BUILD_DATE=$(date +%Y-%m-%d)
BUILD_VERSION=0.1.0
BUILD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")

# Database Configuration
POSTGRES_DB=meowtopia
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=meowtopia-db

# Blockchain Configuration
BLOCKCHAIN_DATA_DIR=./blockchain-data
EOF
            echo -e "${GREEN}✅ Created .env file with default values${NC}"
        fi
    else
        echo -e "${GREEN}✅ .env file already exists${NC}"
    fi
}

# Main setup function
main() {
    local errors=0
    
    echo -e "${BLUE}🔍 Running system checks...${NC}"
    
    # Essential checks
    check_docker || ((errors++))
    check_docker_compose || ((errors++))
    check_git || ((errors++))
    
    # Optional checks (warn but don't fail)
    check_go || echo -e "${YELLOW}⚠️  Go check failed (optional for web development)${NC}"
    
    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}❌ Setup failed with $errors error(s)${NC}"
        echo -e "${YELLOW}🔧 Please fix the errors above and run setup again${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All essential checks passed!${NC}"
    
    # Setup tasks
    echo -e "${BLUE}🔧 Running setup tasks...${NC}"
    setup_docker_buildx
    create_directories
    setup_env_file
    
    echo -e "${GREEN}🎉 Environment setup completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}🚀 You can now run:${NC}"
    echo -e "  • make dev     - Start complete development environment"
    echo -e "  • make web     - Start web services only"
    echo -e "  • make up      - Start all services"
    echo -e "  • make build-all - Build for all platforms"
    echo ""
    echo -e "${YELLOW}📚 For more commands, run: make help${NC}"
}

# Run main function
main "$@"
