#!/bin/bash
# =============================================================================
# Chain Rice Development Environment Setup Script
# =============================================================================
# This script sets up a comprehensive development environment for the Chain Rice
# project with support for multiple languages and tools.
#
# Usage: ./setup.bash [options]
# Options:
#   --help, -h          Show this help message
#   --verbose, -v       Enable verbose output
#   --skip-deps         Skip dependency installation
#   --skip-docker       Skip Docker setup
#   --skip-tools         Skip development tools installation
#   --force             Force reinstallation of existing tools
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly LOG_FILE="/tmp/chain-rice-setup.log"
readonly BACKUP_DIR="$HOME/.chain-rice-backup"

# Global variables
VERBOSE=false
SKIP_DEPS=false
SKIP_DOCKER=false
SKIP_TOOLS=false
FORCE=false

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC}  $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[✓]${NC} $message" ;;
        "STEP") echo -e "${CYAN}[STEP]${NC} $message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

check_command() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        log "DEBUG" "Command '$cmd' is available"
        return 0
    else
        log "DEBUG" "Command '$cmd' is not available"
        return 1
    fi
}

run_command() {
    local cmd="$*"
    log "DEBUG" "Executing: $cmd"
    
    if [[ "$VERBOSE" == "true" ]]; then
        eval "$cmd"
    else
        eval "$cmd" >> "$LOG_FILE" 2>&1
    fi
}

create_backup() {
    local file="$1"
    if [[ -f "$file" && ! -d "$BACKUP_DIR" ]]; then
        log "INFO" "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
    
    if [[ -f "$file" ]]; then
        local backup_file="$BACKUP_DIR/$(basename "$file").$(date +%Y%m%d_%H%M%S)"
        log "INFO" "Backing up $file to $backup_file"
        cp "$file" "$backup_file"
    fi
}

# =============================================================================
# System Detection and Requirements
# =============================================================================

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            echo "$ID"
        elif [[ -f /etc/redhat-release ]]; then
            echo "rhel"
        elif [[ -f /etc/debian_version ]]; then
            echo "debian"
        else
            echo "unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

check_requirements() {
    log "STEP" "Checking system requirements..."
    
    local os=$(detect_os)
    log "INFO" "Detected OS: $os"
    
    # Check for required commands
    local required_commands=("curl" "wget" "git" "make")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! check_command "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log "ERROR" "Missing required commands: ${missing_commands[*]}"
        log "INFO" "Please install the missing commands and run this script again"
        exit 1
    fi
    
    log "SUCCESS" "All required commands are available"
}

# =============================================================================
# Package Manager Functions
# =============================================================================

install_packages() {
    local os=$(detect_os)
    local packages=()
    
    case "$os" in
        "ubuntu"|"debian")
            packages=("build-essential" "python3" "python3-pip" "nodejs" "npm" "docker.io" "docker-compose")
            run_command "sudo apt update"
            run_command "sudo apt install -y ${packages[*]}"
            ;;
        "centos"|"rhel"|"fedora")
            packages=("gcc" "gcc-c++" "python3" "python3-pip" "nodejs" "npm" "docker" "docker-compose")
            if check_command "dnf"; then
                run_command "sudo dnf install -y ${packages[*]}"
            else
                run_command "sudo yum install -y ${packages[*]}"
            fi
            ;;
        "macos")
            if ! check_command "brew"; then
                log "INFO" "Installing Homebrew..."
                run_command '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            fi
            packages=("python3" "node" "docker" "docker-compose")
            run_command "brew install ${packages[*]}"
            ;;
        *)
            log "WARN" "Unsupported OS: $os. Please install dependencies manually."
            return 1
            ;;
    esac
    
    log "SUCCESS" "System packages installed successfully"
}

# =============================================================================
# Development Tools Installation
# =============================================================================

install_rust() {
    if check_command "rustc" && [[ "$FORCE" != "true" ]]; then
        log "INFO" "Rust is already installed"
        return 0
    fi
    
    log "STEP" "Installing Rust..."
    run_command "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    
    # Add to PATH
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
    
    log "SUCCESS" "Rust installed successfully"
}

install_go() {
    if check_command "go" && [[ "$FORCE" != "true" ]]; then
        log "INFO" "Go is already installed"
        return 0
    fi
    
    log "STEP" "Installing Go..."
    local go_version="1.21.5"
    local go_archive="go${go_version}.linux-amd64.tar.gz"
    
    run_command "wget https://golang.org/dl/${go_archive}"
    run_command "sudo tar -C /usr/local -xzf ${go_archive}"
    run_command "rm ${go_archive}"
    
    # Add to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
    export PATH=$PATH:/usr/local/go/bin
    
    log "SUCCESS" "Go installed successfully"
}

install_scala() {
    if check_command "scala" && [[ "$FORCE" != "true" ]]; then
        log "INFO" "Scala is already installed"
        return 0
    fi
    
    log "STEP" "Installing Scala and sbt..."
    
    # Install sbt
    local os=$(detect_os)
    case "$os" in
        "ubuntu"|"debian")
            run_command "echo \"deb https://repo.scala-sbt.org/scalasbt/debian all main\" | sudo tee /etc/apt/sources.list.d/sbt.list"
            run_command "echo \"deb https://repo.scala-sbt.org/scalasbt/debian /\" | sudo tee /etc/apt/sources.list.d/sbt_old.list"
            run_command "curl -sL \"https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823\" | sudo apt-key add"
            run_command "sudo apt update"
            run_command "sudo apt install -y sbt"
            ;;
        "macos")
            run_command "brew install sbt"
            ;;
        *)
            log "WARN" "Please install sbt manually for your OS"
            ;;
    esac
    
    log "SUCCESS" "Scala/sbt installed successfully"
}

install_java() {
    if check_command "java" && [[ "$FORCE" != "true" ]]; then
        log "INFO" "Java is already installed"
        return 0
    fi
    
    log "STEP" "Installing Java..."
    local os=$(detect_os)
    
    case "$os" in
        "ubuntu"|"debian")
            run_command "sudo apt install -y openjdk-17-jdk"
            ;;
        "centos"|"rhel"|"fedora")
            run_command "sudo dnf install -y java-17-openjdk-devel"
            ;;
        "macos")
            run_command "brew install openjdk@17"
            ;;
        *)
            log "WARN" "Please install Java 17 manually for your OS"
            ;;
    esac
    
    log "SUCCESS" "Java installed successfully"
}

# =============================================================================
# Docker Setup
# =============================================================================

setup_docker() {
    if [[ "$SKIP_DOCKER" == "true" ]]; then
        log "INFO" "Skipping Docker setup"
        return 0
    fi
    
    log "STEP" "Setting up Docker..."
    
    # Start Docker service
    if check_command "systemctl"; then
        run_command "sudo systemctl start docker"
        run_command "sudo systemctl enable docker"
    fi
    
    # Add user to docker group
    run_command "sudo usermod -aG docker $USER"
    
    # Test Docker installation
    if run_command "docker --version"; then
        log "SUCCESS" "Docker setup completed"
    else
        log "ERROR" "Docker setup failed"
        return 1
    fi
}

# =============================================================================
# Project Setup
# =============================================================================

setup_project() {
    log "STEP" "Setting up Chain Rice project..."
    
    # Create necessary directories
    local dirs=("logs" "data" "config" "secrets")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
            run_command "mkdir -p $PROJECT_ROOT/$dir"
            log "INFO" "Created directory: $PROJECT_ROOT/$dir"
        fi
    done
    
    # Set up environment file
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        log "INFO" "Creating .env file..."
        cat > "$PROJECT_ROOT/.env" << EOF
# Chain Rice Environment Configuration
NODE_ENV=development
LOG_LEVEL=info
API_PORT=8080
DB_HOST=localhost
DB_PORT=5432
DB_NAME=chain_rice
DB_USER=chain_rice
DB_PASSWORD=password
REDIS_HOST=localhost
REDIS_PORT=6379
EOF
        log "SUCCESS" "Created .env file"
    fi
    
    # Set up Git hooks
    if [[ -d "$PROJECT_ROOT/.git" ]]; then
        log "INFO" "Setting up Git hooks..."
        run_command "chmod +x $PROJECT_ROOT/.git/hooks/*" 2>/dev/null || true
    fi
}

# =============================================================================
# Shell Configuration
# =============================================================================

setup_shell_config() {
    log "STEP" "Setting up shell configuration..."
    
    local shell_config="$HOME/.bashrc"
    create_backup "$shell_config"
    
    # Add project-specific aliases and functions
    cat >> "$shell_config" << 'EOF'

# Chain Rice Development Aliases
alias cr='cd /media/mrdinkelman/Dev/chain-rice'
alias cr-build='make build'
alias cr-test='make test'
alias cr-run='make run'
alias cr-docker='docker-compose up -d'
alias cr-logs='docker-compose logs -f'
alias cr-clean='make clean'

# Development shortcuts
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Function to quickly navigate to project
cr() {
    cd /media/mrdinkelman/Dev/chain-rice
}

# Function to run project tests
cr-test() {
    cd /media/mrdinkelman/Dev/chain-rice
    make test
}

# Function to build project
cr-build() {
    cd /media/mrdinkelman/Dev/chain-rice
    make build
}

EOF
    
    log "SUCCESS" "Shell configuration updated"
}

# =============================================================================
# Main Setup Function
# =============================================================================

main() {
    log "INFO" "Starting Chain Rice development environment setup..."
    log "INFO" "Log file: $LOG_FILE"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --skip-docker)
                SKIP_DOCKER=true
                shift
                ;;
            --skip-tools)
                SKIP_TOOLS=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Run setup steps
    check_requirements
    
    if [[ "$SKIP_DEPS" != "true" ]]; then
        install_packages
    fi
    
    if [[ "$SKIP_TOOLS" != "true" ]]; then
        install_rust
        install_go
        install_scala
        install_java
    fi
    
    setup_docker
    setup_project
    setup_shell_config
    
    log "SUCCESS" "Chain Rice development environment setup completed!"
    log "INFO" "Please restart your terminal or run 'source ~/.bashrc' to apply changes"
    log "INFO" "You can now use commands like 'cr', 'cr-build', 'cr-test'"
}

show_help() {
    cat << EOF
Chain Rice Development Environment Setup Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help, -h          Show this help message
    --verbose, -v       Enable verbose output
    --skip-deps         Skip dependency installation
    --skip-docker       Skip Docker setup
    --skip-tools        Skip development tools installation
    --force             Force reinstallation of existing tools

EXAMPLES:
    $0                  # Full setup
    $0 --verbose        # Full setup with verbose output
    $0 --skip-deps      # Skip system package installation
    $0 --force          # Force reinstall all tools

DESCRIPTION:
    This script sets up a comprehensive development environment for the Chain Rice
    project, including:
    - System dependencies (build tools, Python, Node.js)
    - Development languages (Rust, Go, Scala, Java)
    - Docker and containerization tools
    - Project-specific configuration
    - Shell aliases and shortcuts

EOF
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
