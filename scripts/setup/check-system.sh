#!/bin/bash

# 🔍 System Check Script
# Checks if the system is ready for Chain Rice development

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 Checking Chain Rice development environment...${NC}"

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
echo -e "${YELLOW}🖥️  OS: $OS${NC}"

# Check if running in WSL
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    echo -e "${YELLOW}🐧 WSL: $WSL_DISTRO_NAME${NC}"
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version
check_version() {
    local cmd="$1"
    local min_version="$2"
    local current_version="$3"
    
    if [[ -z "$min_version" ]]; then
        echo -e "${GREEN}✅ $cmd is available${NC}"
        return 0
    fi
    
    # Simple version comparison (works for most cases)
    if [[ "$current_version" > "$min_version" ]] || [[ "$current_version" == "$min_version" ]]; then
        echo -e "${GREEN}✅ $cmd version $current_version (required: $min_version)${NC}"
        return 0
    else
        echo -e "${RED}❌ $cmd version $current_version is too old (required: $min_version)${NC}"
        return 1
    fi
}

# Check Docker
check_docker() {
    echo -e "${YELLOW}🐳 Checking Docker...${NC}"
    
    if ! command_exists docker; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        return 1
    fi
    
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    check_version "Docker" "20.10.0" "$docker_version"
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Docker is running${NC}"
    return 0
}

# Check Docker Compose
check_docker_compose() {
    echo -e "${YELLOW}🐳 Checking Docker Compose...${NC}"
    
    if docker compose version >/dev/null 2>&1; then
        local compose_version=$(docker compose version --short)
        check_version "Docker Compose" "2.0.0" "$compose_version"
    elif command_exists docker-compose; then
        local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        check_version "Docker Compose" "1.29.0" "$compose_version"
    else
        echo -e "${RED}❌ Docker Compose is not available${NC}"
        return 1
    fi
    
    return 0
}

# Check Git
check_git() {
    echo -e "${YELLOW}📝 Checking Git...${NC}"
    
    if ! command_exists git; then
        echo -e "${RED}❌ Git is not installed${NC}"
        return 1
    fi
    
    local git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    check_version "Git" "2.20.0" "$git_version"
    
    return 0
}

# Check Go (optional)
check_go() {
    echo -e "${YELLOW}🐹 Checking Go...${NC}"
    
    if ! command_exists go; then
        echo -e "${YELLOW}⚠️  Go is not installed (optional for web development)${NC}"
        return 1
    fi
    
    local go_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
    check_version "Go" "1.19" "$go_version"
    
    return 0
}

# Check Node.js (for frontend development)
check_node() {
    echo -e "${YELLOW}📦 Checking Node.js...${NC}"
    
    if ! command_exists node; then
        echo -e "${YELLOW}⚠️  Node.js is not installed (needed for frontend development)${NC}"
        return 1
    fi
    
    local node_version=$(node --version | sed 's/v//')
    check_version "Node.js" "16.0.0" "$node_version"
    
    return 0
}

# Check required files
check_files() {
    echo -e "${YELLOW}📁 Checking required files...${NC}"
    
    local files=(
        "docker-compose.yml"
        "Dockerfile.blockchain"
        "meowtopia/backend/Dockerfile.backend"
        "meowtopia/frontend/web/Dockerfile.web.npm"
    )
    
    local missing_files=()
    
    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required files:${NC}"
        for file in "${missing_files[@]}"; do
            echo -e "${RED}   • $file${NC}"
        done
        return 1
    fi
    
    echo -e "${GREEN}✅ All required files present${NC}"
    return 0
}

# Check environment file
check_env() {
    echo -e "${YELLOW}⚙️  Checking environment configuration...${NC}"
    
    if [[ ! -f ".env" ]]; then
        echo -e "${YELLOW}⚠️  .env file not found (will be created automatically)${NC}"
        return 0
    fi
    
    echo -e "${GREEN}✅ .env file exists${NC}"
    return 0
}

# Check Docker buildx
check_docker_buildx() {
    echo -e "${YELLOW}🔧 Checking Docker Buildx...${NC}"
    
    if ! docker buildx ls | grep -q "multiplatform"; then
        echo -e "${YELLOW}⚠️  Multiplatform builder not found (will be created automatically)${NC}"
        return 0
    fi
    
    echo -e "${GREEN}✅ Multiplatform builder available${NC}"
    return 0
}

# Main check function
main() {
    local errors=0
    local warnings=0
    
    # Essential checks
    check_docker || ((errors++))
    check_docker_compose || ((errors++))
    check_git || ((errors++))
    check_files || ((errors++))
    
    # Optional checks
    if ! check_go; then ((warnings++)); fi
    if ! check_node; then ((warnings++)); fi
    if ! check_env; then ((warnings++)); fi
    if ! check_docker_buildx; then ((warnings++)); fi
    
    echo ""
    echo -e "${BLUE}📊 System Check Summary:${NC}"
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✅ System is ready for development!${NC}"
        if [[ $warnings -gt 0 ]]; then
            echo -e "${YELLOW}⚠️  $warnings warning(s) - some features may not be available${NC}"
        fi
        echo ""
        echo -e "${YELLOW}🚀 You can now run:${NC}"
        echo -e "  • make dev     - Start complete development environment"
        echo -e "  • make web     - Start web services only"
        echo -e "  • make up      - Start all services"
    else
        echo -e "${RED}❌ System check failed with $errors error(s)${NC}"
        if [[ $warnings -gt 0 ]]; then
            echo -e "${YELLOW}⚠️  $warnings warning(s)${NC}"
        fi
        echo ""
        echo -e "${YELLOW}🔧 To fix issues, run:${NC}"
        echo -e "  • make setup   - Run automatic setup"
        echo -e "  • make prepare - Prepare environment"
        exit 1
    fi
}

# Run main function
main "$@"
