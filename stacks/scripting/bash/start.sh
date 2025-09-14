#!/bin/bash
# =============================================================================
# Chain Rice Application Startup and Management Script
# =============================================================================
# This script provides comprehensive application lifecycle management for the
# Chain Rice project, including startup, monitoring, and maintenance operations.
#
# Usage: ./start.sh [command] [options]
# Commands:
#   start           Start all services
#   stop            Stop all services
#   restart         Restart all services
#   status          Show status of all services
#   logs            Show logs for services
#   build           Build all components
#   test            Run tests
#   clean           Clean build artifacts
#   deploy          Deploy to production
#   backup          Create backup
#   restore         Restore from backup
# =============================================================================

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly PID_DIR="$PROJECT_ROOT/.pids"
readonly LOG_DIR="$PROJECT_ROOT/logs"
readonly CONFIG_DIR="$PROJECT_ROOT/config"
readonly DATA_DIR="$PROJECT_ROOT/data"
readonly BACKUP_DIR="$PROJECT_ROOT/backups"

# Service configurations
declare -A SERVICES=(
    ["rust-api"]="examples/rust"
    ["scala-api"]="examples/scala"
    ["go-service"]="examples/go"
    ["python-service"]="examples/python"
    ["node-service"]="examples/node"
    ["docker-services"]="."
)

declare -A SERVICE_PORTS=(
    ["rust-api"]="8080"
    ["scala-api"]="8081"
    ["go-service"]="8082"
    ["python-service"]="8083"
    ["node-service"]="8084"
)

declare -A SERVICE_COMMANDS=(
    ["rust-api"]="cargo run"
    ["scala-api"]="sbt run"
    ["go-service"]="go run main.go"
    ["python-service"]="python main.py"
    ["node-service"]="npm start"
)

# Global variables
VERBOSE=false
FOREGROUND=false
SERVICE_NAME=""
TIMEOUT=30

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
    
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/startup.log"
}

create_directories() {
    local dirs=("$PID_DIR" "$LOG_DIR" "$CONFIG_DIR" "$DATA_DIR" "$BACKUP_DIR")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log "DEBUG" "Created directory: $dir"
        fi
    done
}

check_port() {
    local port="$1"
    if lsof -i ":$port" >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

wait_for_port() {
    local port="$1"
    local timeout="${2:-30}"
    local count=0
    
    log "DEBUG" "Waiting for port $port to be available..."
    
    while [[ $count -lt $timeout ]]; do
        if check_port "$port"; then
            log "SUCCESS" "Port $port is now available"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log "ERROR" "Timeout waiting for port $port"
    return 1
}

get_service_pid() {
    local service="$1"
    local pid_file="$PID_DIR/${service}.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "$pid"
            return 0
        else
            rm -f "$pid_file"
            return 1
        fi
    fi
    return 1
}

save_service_pid() {
    local service="$1"
    local pid="$2"
    local pid_file="$PID_DIR/${service}.pid"
    
    echo "$pid" > "$pid_file"
    log "DEBUG" "Saved PID $pid for service $service"
}

remove_service_pid() {
    local service="$1"
    local pid_file="$PID_DIR/${service}.pid"
    
    if [[ -f "$pid_file" ]]; then
        rm -f "$pid_file"
        log "DEBUG" "Removed PID file for service $service"
    fi
}

# =============================================================================
# Service Management Functions
# =============================================================================

start_service() {
    local service="$1"
    local service_dir="$PROJECT_ROOT/${SERVICES[$service]}"
    local port="${SERVICE_PORTS[$service]}"
    local command="${SERVICE_COMMANDS[$service]}"
    
    log "STEP" "Starting service: $service"
    
    # Check if service is already running
    if get_service_pid "$service" >/dev/null; then
        log "WARN" "Service $service is already running"
        return 0
    fi
    
    # Check if port is available
    if check_port "$port"; then
        log "ERROR" "Port $port is already in use"
        return 1
    fi
    
    # Change to service directory
    if [[ ! -d "$service_dir" ]]; then
        log "ERROR" "Service directory not found: $service_dir"
        return 1
    fi
    
    cd "$service_dir"
    
    # Start service
    log "INFO" "Starting $service on port $port..."
    log "DEBUG" "Command: $command"
    log "DEBUG" "Directory: $service_dir"
    
    if [[ "$FOREGROUND" == "true" ]]; then
        # Run in foreground
        exec $command
    else
        # Run in background
        nohup $command > "$LOG_DIR/${service}.log" 2>&1 &
        local pid=$!
        save_service_pid "$service" "$pid"
        
        # Wait for service to start
        if wait_for_port "$port" "$TIMEOUT"; then
            log "SUCCESS" "Service $service started successfully (PID: $pid)"
        else
            log "ERROR" "Service $service failed to start"
            kill "$pid" 2>/dev/null || true
            remove_service_pid "$service"
            return 1
        fi
    fi
}

stop_service() {
    local service="$1"
    local pid
    
    log "STEP" "Stopping service: $service"
    
    if pid=$(get_service_pid "$service"); then
        log "INFO" "Stopping service $service (PID: $pid)"
        
        # Try graceful shutdown first
        if kill -TERM "$pid" 2>/dev/null; then
            # Wait for graceful shutdown
            local count=0
            while [[ $count -lt 10 ]]; do
                if ! kill -0 "$pid" 2>/dev/null; then
                    log "SUCCESS" "Service $service stopped gracefully"
                    remove_service_pid "$service"
                    return 0
                fi
                sleep 1
                ((count++))
            done
            
            # Force kill if graceful shutdown failed
            log "WARN" "Force killing service $service"
            kill -KILL "$pid" 2>/dev/null || true
            remove_service_pid "$service"
            log "SUCCESS" "Service $service stopped"
        else
            log "ERROR" "Failed to stop service $service"
            return 1
        fi
    else
        log "WARN" "Service $service is not running"
    fi
}

restart_service() {
    local service="$1"
    
    log "STEP" "Restarting service: $service"
    stop_service "$service"
    sleep 2
    start_service "$service"
}

get_service_status() {
    local service="$1"
    local pid
    
    if pid=$(get_service_pid "$service"); then
        local port="${SERVICE_PORTS[$service]}"
        local status="RUNNING"
        local uptime=""
        
        # Calculate uptime
        if [[ -f "/proc/$pid" ]]; then
            local start_time=$(stat -c %Y "/proc/$pid" 2>/dev/null || echo "0")
            local current_time=$(date +%s)
            local uptime_seconds=$((current_time - start_time))
            uptime=$(printf "%02d:%02d:%02d" $((uptime_seconds/3600)) $((uptime_seconds%3600/60)) $((uptime_seconds%60)))
        fi
        
        echo -e "${GREEN}✓${NC} $service (PID: $pid, Port: $port, Uptime: $uptime)"
    else
        echo -e "${RED}✗${NC} $service (STOPPED)"
    fi
}

# =============================================================================
# Docker Management
# =============================================================================

start_docker_services() {
    log "STEP" "Starting Docker services..."
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "docker-compose.yml" ]]; then
        if [[ "$FOREGROUND" == "true" ]]; then
            docker-compose up
        else
            docker-compose up -d
            log "SUCCESS" "Docker services started"
        fi
    else
        log "WARN" "docker-compose.yml not found"
    fi
}

stop_docker_services() {
    log "STEP" "Stopping Docker services..."
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "docker-compose.yml" ]]; then
        docker-compose down
        log "SUCCESS" "Docker services stopped"
    else
        log "WARN" "docker-compose.yml not found"
    fi
}

# =============================================================================
# Build and Test Functions
# =============================================================================

build_all() {
    log "STEP" "Building all components..."
    
    cd "$PROJECT_ROOT"
    
    # Build Rust components
    if [[ -d "examples/rust" ]]; then
        log "INFO" "Building Rust components..."
        cd "examples/rust"
        cargo build --release
        cd "$PROJECT_ROOT"
    fi
    
    # Build Scala components
    if [[ -d "examples/scala" ]]; then
        log "INFO" "Building Scala components..."
        cd "examples/scala"
        sbt compile
        cd "$PROJECT_ROOT"
    fi
    
    # Build Go components
    if [[ -d "examples/go" ]]; then
        log "INFO" "Building Go components..."
        cd "examples/go"
        go build -o bin/service .
        cd "$PROJECT_ROOT"
    fi
    
    # Build Node.js components
    if [[ -d "examples/node" ]]; then
        log "INFO" "Building Node.js components..."
        cd "examples/node"
        npm install
        npm run build
        cd "$PROJECT_ROOT"
    fi
    
    # Build Python components
    if [[ -d "examples/python" ]]; then
        log "INFO" "Building Python components..."
        cd "examples/python"
        pip install -r requirements.txt
        cd "$PROJECT_ROOT"
    fi
    
    log "SUCCESS" "All components built successfully"
}

run_tests() {
    log "STEP" "Running tests..."
    
    cd "$PROJECT_ROOT"
    
    # Run Rust tests
    if [[ -d "examples/rust" ]]; then
        log "INFO" "Running Rust tests..."
        cd "examples/rust"
        cargo test
        cd "$PROJECT_ROOT"
    fi
    
    # Run Scala tests
    if [[ -d "examples/scala" ]]; then
        log "INFO" "Running Scala tests..."
        cd "examples/scala"
        sbt test
        cd "$PROJECT_ROOT"
    fi
    
    # Run Go tests
    if [[ -d "examples/go" ]]; then
        log "INFO" "Running Go tests..."
        cd "examples/go"
        go test ./...
        cd "$PROJECT_ROOT"
    fi
    
    # Run Node.js tests
    if [[ -d "examples/node" ]]; then
        log "INFO" "Running Node.js tests..."
        cd "examples/node"
        npm test
        cd "$PROJECT_ROOT"
    fi
    
    # Run Python tests
    if [[ -d "examples/python" ]]; then
        log "INFO" "Running Python tests..."
        cd "examples/python"
        python -m pytest
        cd "$PROJECT_ROOT"
    fi
    
    log "SUCCESS" "All tests completed"
}

clean_build() {
    log "STEP" "Cleaning build artifacts..."
    
    cd "$PROJECT_ROOT"
    
    # Clean Rust artifacts
    if [[ -d "examples/rust" ]]; then
        cd "examples/rust"
        cargo clean
        cd "$PROJECT_ROOT"
    fi
    
    # Clean Scala artifacts
    if [[ -d "examples/scala" ]]; then
        cd "examples/scala"
        sbt clean
        cd "$PROJECT_ROOT"
    fi
    
    # Clean Go artifacts
    if [[ -d "examples/go" ]]; then
        cd "examples/go"
        go clean
        rm -f bin/*
        cd "$PROJECT_ROOT"
    fi
    
    # Clean Node.js artifacts
    if [[ -d "examples/node" ]]; then
        cd "examples/node"
        rm -rf node_modules dist
        cd "$PROJECT_ROOT"
    fi
    
    # Clean Python artifacts
    if [[ -d "examples/python" ]]; then
        cd "examples/python"
        find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find . -type f -name "*.pyc" -delete 2>/dev/null || true
        cd "$PROJECT_ROOT"
    fi
    
    # Clean Docker artifacts
    docker system prune -f 2>/dev/null || true
    
    log "SUCCESS" "Build artifacts cleaned"
}

# =============================================================================
# Backup and Restore Functions
# =============================================================================

create_backup() {
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "STEP" "Creating backup: $backup_name"
    
    mkdir -p "$backup_path"
    
    # Backup configuration
    if [[ -d "$CONFIG_DIR" ]]; then
        cp -r "$CONFIG_DIR" "$backup_path/"
    fi
    
    # Backup data
    if [[ -d "$DATA_DIR" ]]; then
        cp -r "$DATA_DIR" "$backup_path/"
    fi
    
    # Backup environment files
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        cp "$PROJECT_ROOT/.env" "$backup_path/"
    fi
    
    # Create backup manifest
    cat > "$backup_path/manifest.txt" << EOF
Backup created: $(date)
Project root: $PROJECT_ROOT
Services: ${!SERVICES[*]}
EOF
    
    log "SUCCESS" "Backup created: $backup_path"
}

restore_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ ! -d "$backup_path" ]]; then
        log "ERROR" "Backup not found: $backup_name"
        return 1
    fi
    
    log "STEP" "Restoring backup: $backup_name"
    
    # Stop all services first
    stop_all_services
    
    # Restore configuration
    if [[ -d "$backup_path/config" ]]; then
        cp -r "$backup_path/config"/* "$CONFIG_DIR/"
    fi
    
    # Restore data
    if [[ -d "$backup_path/data" ]]; then
        cp -r "$backup_path/data"/* "$DATA_DIR/"
    fi
    
    # Restore environment file
    if [[ -f "$backup_path/.env" ]]; then
        cp "$backup_path/.env" "$PROJECT_ROOT/"
    fi
    
    log "SUCCESS" "Backup restored: $backup_name"
}

# =============================================================================
# Main Command Functions
# =============================================================================

start_all_services() {
    log "STEP" "Starting all services..."
    
    create_directories
    
    # Start Docker services first
    start_docker_services
    
    # Start individual services
    for service in "${!SERVICES[@]}"; do
        if [[ "$service" != "docker-services" ]]; then
            start_service "$service"
        fi
    done
    
    log "SUCCESS" "All services started"
}

stop_all_services() {
    log "STEP" "Stopping all services..."
    
    # Stop individual services
    for service in "${!SERVICES[@]}"; do
        if [[ "$service" != "docker-services" ]]; then
            stop_service "$service"
        fi
    done
    
    # Stop Docker services
    stop_docker_services
    
    log "SUCCESS" "All services stopped"
}

restart_all_services() {
    log "STEP" "Restarting all services..."
    stop_all_services
    sleep 3
    start_all_services
}

show_status() {
    log "STEP" "Service Status:"
    echo
    
    for service in "${!SERVICES[@]}"; do
        if [[ "$service" != "docker-services" ]]; then
            get_service_status "$service"
        fi
    done
    
    echo
    log "INFO" "Docker services:"
    cd "$PROJECT_ROOT"
    if [[ -f "docker-compose.yml" ]]; then
        docker-compose ps
    else
        echo "No docker-compose.yml found"
    fi
}

show_logs() {
    local service="$1"
    local lines="${2:-100}"
    
    if [[ -z "$service" ]]; then
        log "ERROR" "Service name required for logs command"
        return 1
    fi
    
    local log_file="$LOG_DIR/${service}.log"
    
    if [[ -f "$log_file" ]]; then
        log "INFO" "Showing last $lines lines of $service logs:"
        echo
        tail -n "$lines" "$log_file"
    else
        log "WARN" "No log file found for service: $service"
    fi
}

# =============================================================================
# Command Line Interface
# =============================================================================

show_help() {
    cat << EOF
Chain Rice Application Management Script

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    start [service]     Start all services or specific service
    stop [service]      Stop all services or specific service
    restart [service]   Restart all services or specific service
    status              Show status of all services
    logs <service>       Show logs for specific service
    build               Build all components
    test                Run all tests
    clean               Clean build artifacts
    backup              Create backup
    restore <name>      Restore from backup
    deploy              Deploy to production

OPTIONS:
    --verbose, -v       Enable verbose output
    --foreground, -f    Run services in foreground
    --timeout <sec>     Timeout for service startup (default: 30)
    --help, -h          Show this help message

EXAMPLES:
    $0 start                    # Start all services
    $0 start rust-api          # Start specific service
    $0 stop                    # Stop all services
    $0 restart scala-api       # Restart specific service
    $0 status                  # Show service status
    $0 logs rust-api           # Show logs for rust-api
    $0 build                   # Build all components
    $0 test                    # Run all tests
    $0 clean                   # Clean build artifacts
    $0 backup                  # Create backup
    $0 restore backup_20240101_120000  # Restore backup

SERVICES:
    rust-api          Rust API service (port 8080)
    scala-api         Scala API service (port 8081)
    go-service        Go service (port 8082)
    python-service    Python service (port 8083)
    node-service      Node.js service (port 8084)
    docker-services   Docker Compose services

EOF
}

main() {
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
            --foreground|-f)
                FOREGROUND=true
                shift
                ;;
            --timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            start|stop|restart|status|logs|build|test|clean|backup|restore|deploy)
                COMMAND="$1"
                shift
                break
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Handle command arguments
    case "${COMMAND:-}" in
        start)
            if [[ $# -gt 0 ]]; then
                SERVICE_NAME="$1"
                if [[ "$SERVICE_NAME" == "docker-services" ]]; then
                    start_docker_services
                else
                    start_service "$SERVICE_NAME"
                fi
            else
                start_all_services
            fi
            ;;
        stop)
            if [[ $# -gt 0 ]]; then
                SERVICE_NAME="$1"
                if [[ "$SERVICE_NAME" == "docker-services" ]]; then
                    stop_docker_services
                else
                    stop_service "$SERVICE_NAME"
                fi
            else
                stop_all_services
            fi
            ;;
        restart)
            if [[ $# -gt 0 ]]; then
                SERVICE_NAME="$1"
                if [[ "$SERVICE_NAME" == "docker-services" ]]; then
                    stop_docker_services
                    start_docker_services
                else
                    restart_service "$SERVICE_NAME"
                fi
            else
                restart_all_services
            fi
            ;;
        status)
            show_status
            ;;
        logs)
            if [[ $# -gt 0 ]]; then
                show_logs "$1" "${2:-100}"
            else
                log "ERROR" "Service name required for logs command"
                exit 1
            fi
            ;;
        build)
            build_all
            ;;
        test)
            run_tests
            ;;
        clean)
            clean_build
            ;;
        backup)
            create_backup
            ;;
        restore)
            if [[ $# -gt 0 ]]; then
                restore_backup "$1"
            else
                log "ERROR" "Backup name required for restore command"
                exit 1
            fi
            ;;
        deploy)
            log "STEP" "Deploying to production..."
            build_all
            run_tests
            log "SUCCESS" "Deployment completed"
            ;;
        *)
            log "ERROR" "No command specified"
            show_help
            exit 1
            ;;
    esac
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
