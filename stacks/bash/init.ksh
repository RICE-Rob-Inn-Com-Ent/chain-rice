#!/usr/bin/env ksh
# =============================================================================
# Chain Rice Korn Shell Initialization Script
# =============================================================================
# This script provides comprehensive Korn shell (ksh) initialization for the
# Chain Rice development environment, including aliases, functions, and utilities.
#
# Usage: source init.ksh
# Or add to your .kshrc: . /path/to/init.ksh
# =============================================================================

# =============================================================================
# Configuration Variables
# =============================================================================

# Colors (ANSI escape codes)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project paths
CHAIN_RICE_ROOT="/media/mrdinkelman/Dev/chain-rice"
CHAIN_RICE_SCRIPTS="$CHAIN_RICE_ROOT/examples/scripts"

# Shell options
set -o emacs                    # Use emacs key bindings
set -o ignoreeof               # Don't exit on Ctrl+D
set -o noclobber              # Don't overwrite files with >
set -o notify                  # Notify of background job completion

# =============================================================================
# Utility Functions
# =============================================================================

log_info() {
    print -u2 "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    print -u2 "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    print -u2 "${RED}[ERROR]${NC} $1"
}

log_debug() {
    [[ "$DEBUG" == "true" ]] && print -u2 "${BLUE}[DEBUG]${NC} $1"
}

# =============================================================================
# Environment Setup
# =============================================================================

setup_environment() {
    log_info "Setting up environment variables..."
    
    # Editor and pager
    export EDITOR='vi'
    export VISUAL='vi'
    export PAGER='less'
    export LESS='-R'
    
    # Language settings
    export LANG='en_US.UTF-8'
    export LC_ALL='en_US.UTF-8'
    
    # Path configuration
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="$HOME/.cargo/bin:$PATH"
    export PATH="$HOME/.go/bin:$PATH"
    export PATH="/usr/local/go/bin:$PATH"
    
    # Chain Rice specific
    export CHAIN_RICE_ROOT="$CHAIN_RICE_ROOT"
    export CHAIN_RICE_SCRIPTS="$CHAIN_RICE_SCRIPTS"
    
    # Development tools
    export RUST_BACKTRACE=1
    export CARGO_TARGET_DIR="$CHAIN_RICE_ROOT/target"
    
    # Node.js
    export NODE_ENV=development
    
    # Python
    export PYTHONPATH="$CHAIN_RICE_ROOT:$PYTHONPATH"
    
    # Go
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"
    export PATH="$GOBIN:$PATH"
    
    # Java
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    # Scala
    export SCALA_HOME="/usr/local/scala"
    export PATH="$SCALA_HOME/bin:$PATH"
    
    log_info "Environment variables configured successfully"
}

# =============================================================================
# Aliases
# =============================================================================

setup_aliases() {
    log_info "Setting up aliases..."
    
    # Chain Rice specific aliases
    alias cr='cd $CHAIN_RICE_ROOT'
    alias cr-build='cd $CHAIN_RICE_ROOT && make build'
    alias cr-test='cd $CHAIN_RICE_ROOT && make test'
    alias cr-run='cd $CHAIN_RICE_ROOT && make run'
    alias cr-docker='cd $CHAIN_RICE_ROOT && docker-compose up -d'
    alias cr-logs='cd $CHAIN_RICE_ROOT && docker-compose logs -f'
    alias cr-clean='cd $CHAIN_RICE_ROOT && make clean'
    alias cr-start='$CHAIN_RICE_SCRIPTS/start.sh'
    alias cr-stop='$CHAIN_RICE_SCRIPTS/start.sh stop'
    alias cr-status='$CHAIN_RICE_SCRIPTS/start.sh status'
    alias cr-restart='$CHAIN_RICE_SCRIPTS/start.sh restart'
    
    # General aliases
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    
    # Git aliases
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git log --oneline'
    alias gd='git diff'
    alias gb='git branch'
    alias gco='git checkout'
    alias gcb='git checkout -b'
    alias gm='git merge'
    alias gr='git rebase'
    alias gf='git fetch'
    alias gpull='git pull'
    alias gstash='git stash'
    alias gpop='git stash pop'
    
    # Docker aliases
    alias d='docker'
    alias dc='docker-compose'
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias drm='docker rm'
    alias drmi='docker rmi'
    alias dlog='docker logs'
    alias dexec='docker exec -it'
    
    # System aliases
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias .....='cd ../../../..'
    alias ~='cd ~'
    alias -- -='cd -'
    
    # Network aliases
    alias ports='netstat -tuln'
    alias myip='curl -s https://ipinfo.io/ip'
    alias localip='ip route get 1 | awk "{print \$7}"'
    
    # Process aliases
    alias psg='ps aux | grep'
    alias killg='killall -9'
    
    log_info "Aliases configured successfully"
}

# =============================================================================
# Functions
# =============================================================================

setup_functions() {
    log_info "Setting up custom functions..."
    
    # Function to quickly navigate to Chain Rice project
    cr() {
        cd "$CHAIN_RICE_ROOT"
    }
    
    # Function to run project tests
    cr-test() {
        cd "$CHAIN_RICE_ROOT"
        make test
    }
    
    # Function to build project
    cr-build() {
        cd "$CHAIN_RICE_ROOT"
        make build
    }
    
    # Function to start services
    cr-start() {
        "$CHAIN_RICE_SCRIPTS/start.sh" start "$@"
    }
    
    # Function to stop services
    cr-stop() {
        "$CHAIN_RICE_SCRIPTS/start.sh" stop "$@"
    }
    
    # Function to show service status
    cr-status() {
        "$CHAIN_RICE_SCRIPTS/start.sh" status
    }
    
    # Function to show logs
    cr-logs() {
        "$CHAIN_RICE_SCRIPTS/start.sh" logs "$@"
    }
    
    # Function to create a new git branch
    gcb() {
        local branch_name="$1"
        if [[ -z "$branch_name" ]]; then
            print "Usage: gcb <branch-name>"
            return 1
        fi
        git checkout -b "$branch_name"
    }
    
    # Function to find files
    ff() {
        local pattern="$1"
        if [[ -z "$pattern" ]]; then
            print "Usage: ff <pattern>"
            return 1
        fi
        find . -type f -name "*$pattern*" 2>/dev/null
    }
    
    # Function to find directories
    fd() {
        local pattern="$1"
        if [[ -z "$pattern" ]]; then
            print "Usage: fd <pattern>"
            return 1
        fi
        find . -type d -name "*$pattern*" 2>/dev/null
    }
    
    # Function to search in files
    sg() {
        local pattern="$1"
        local path="${2:-.}"
        if [[ -z "$pattern" ]]; then
            print "Usage: sg <pattern> [path]"
            return 1
        fi
        grep -r "$pattern" "$path" 2>/dev/null
    }
    
    # Function to extract archives
    extract() {
        if [[ -f "$1" ]]; then
            case "$1" in
                *.tar.bz2)   tar xjf "$1"     ;;
                *.tar.gz)    tar xzf "$1"     ;;
                *.bz2)       bunzip2 "$1"      ;;
                *.rar)       unrar e "$1"      ;;
                *.gz)        gunzip "$1"       ;;
                *.tar)       tar xf "$1"       ;;
                *.tbz2)      tar xjf "$1"      ;;
                *.tgz)       tar xzf "$1"      ;;
                *.zip)       unzip "$1"        ;;
                *.Z)         uncompress "$1"   ;;
                *.7z)        7z x "$1"         ;;
                *)           print "'$1' cannot be extracted via extract()" ;;
            esac
        else
            print "'$1' is not a valid file"
        fi
    }
    
    # Function to create directory and cd into it
    mkcd() {
        local dir="$1"
        if [[ -z "$dir" ]]; then
            print "Usage: mkcd <directory>"
            return 1
        fi
        mkdir -p "$dir" && cd "$dir"
    }
    
    # Function to show weather
    weather() {
        local city="${1:-}"
        if [[ -n "$city" ]]; then
            curl -s "wttr.in/$city"
        else
            curl -s "wttr.in"
        fi
    }
    
    # Function to show system info
    sysinfo() {
        print "=== System Information ==="
        print "OS: $(uname -s)"
        print "Kernel: $(uname -r)"
        print "Architecture: $(uname -m)"
        print "Hostname: $(hostname)"
        print "Uptime: $(uptime)"
        print "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
        print "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
        print "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    }
    
    # Function to show directory size
    dirsize() {
        local dir="${1:-.}"
        du -sh "$dir" 2>/dev/null || print "Cannot access directory: $dir"
    }
    
    # Function to show largest files
    largest() {
        local dir="${1:-.}"
        local count="${2:-10}"
        find "$dir" -type f -exec ls -lh {} \; 2>/dev/null | \
            awk '{print $5 " " $9}' | sort -hr | head -n "$count"
    }
    
    # Function to show process tree
    pstree() {
        local pid="${1:-$$}"
        ps -ef | awk -v pid="$pid" '
            BEGIN { print "Process Tree for PID " pid }
            $2 == pid { print "  " $0 }
            $3 == pid { print "    " $0 }
        '
    }
    
    # Function to show network connections
    netstat() {
        local port="${1:-}"
        if [[ -n "$port" ]]; then
            netstat -tuln | grep ":$port "
        else
            netstat -tuln
        fi
    }
    
    # Function to show disk usage
    diskusage() {
        df -h | awk '
            NR==1 {print $0}
            NR>1 { 
                if ($5+0 > 80) print $0 " ⚠️"
                else print $0
            }
        '
    }
    
    # Function to show memory usage
    memusage() {
        free -h | awk '
            /^Mem:/ { 
                used=$3; total=$2; 
                percent=int(used/total*100);
                print "Memory Usage: " used "/" total " (" percent "%)"
            }
        '
    }
    
    # Function to show CPU usage
    cpuusage() {
        top -bn1 | grep "Cpu(s)" | awk '{print "CPU Usage: " $2}'
    }
    
    # Function to show system load
    loadavg() {
        uptime | awk '{print "Load Average: " $(NF-2) " " $(NF-1) " " $NF}'
    }
    
    log_info "Custom functions configured successfully"
}

# =============================================================================
# History Configuration
# =============================================================================

setup_history() {
    log_info "Setting up history configuration..."
    
    # History file
    export HISTFILE="$HOME/.ksh_history"
    
    # History size
    export HISTSIZE=10000
    
    # History options
    set -o history
    
    log_info "History configuration completed"
}

# =============================================================================
# Prompt Configuration
# =============================================================================

setup_prompt() {
    log_info "Setting up prompt configuration..."
    
    # Function to get git branch
    git_branch() {
        local branch=$(git branch 2>/dev/null | grep '^*' | sed 's/* //')
        if [[ -n "$branch" ]]; then
            print " ($branch)"
        fi
    }
    
    # Function to get git status
    git_status() {
        local status=$(git status --porcelain 2>/dev/null)
        if [[ -n "$status" ]]; then
            print " *"
        fi
    }
    
    # Set prompt
    export PS1='${GREEN}\u@\h${NC}:${BLUE}\w${NC}${YELLOW}$(git_branch)$(git_status)${NC}\$ '
    
    log_info "Prompt configured successfully"
}

# =============================================================================
# Key Bindings
# =============================================================================

setup_key_bindings() {
    log_info "Setting up key bindings..."
    
    # History search
    bind '^R=history-search-backward'
    bind '^S=history-search-forward'
    
    # Word navigation
    bind '^[[1;5C=forward-word'
    bind '^[[1;5D=backward-word'
    
    # Beginning and end of line
    bind '^A=beginning-of-line'
    bind '^E=end-of-line'
    
    # Delete word
    bind '^W=backward-kill-word'
    
    log_info "Key bindings configured successfully"
}

# =============================================================================
# Completion System
# =============================================================================

setup_completion() {
    log_info "Setting up completion system..."
    
    # Enable completion
    set -o complete
    
    # Custom completions for Chain Rice commands
    complete cr-start 'N:1:(start stop restart status logs build test clean backup restore deploy)'
    complete cr-stop 'N:1:(start stop restart status logs build test clean backup restore deploy)'
    complete cr-restart 'N:1:(start stop restart status logs build test clean backup restore deploy)'
    
    log_info "Completion system configured successfully"
}

# =============================================================================
# Welcome Message
# =============================================================================

show_welcome() {
    print "${CYAN}"
    print "╔══════════════════════════════════════════════════════════════╗"
    print "║                    Chain Rice Development                    ║"
    print "║                      Korn Shell Setup                      ║"
    print "╚══════════════════════════════════════════════════════════════╝"
    print "${NC}"
    print
    print "${GREEN}Welcome to Chain Rice development environment!${NC}"
    print
    print "${YELLOW}Quick Commands:${NC}"
    print "  cr          - Navigate to Chain Rice project"
    print "  cr-start    - Start services"
    print "  cr-stop     - Stop services"
    print "  cr-status   - Show service status"
    print "  cr-build    - Build project"
    print "  cr-test     - Run tests"
    print "  cr-logs     - Show service logs"
    print
    print "${YELLOW}Utility Functions:${NC}"
    print "  sysinfo     - Show system information"
    print "  weather     - Show weather information"
    print "  extract     - Extract archives"
    print "  ff          - Find files"
    print "  sg          - Search in files"
    print
    print "${BLUE}Project Root: $CHAIN_RICE_ROOT${NC}"
    print "${BLUE}Scripts: $CHAIN_RICE_SCRIPTS${NC}"
    print
}

# =============================================================================
# Main Initialization Function
# =============================================================================

init_ksh() {
    log_info "Initializing Korn Shell for Chain Rice..."
    
    # Setup components
    setup_environment
    setup_aliases
    setup_functions
    setup_history
    setup_prompt
    setup_key_bindings
    setup_completion
    
    # Show welcome message
    show_welcome
    
    log_info "Korn Shell initialization completed successfully!"
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Configuration options
DEBUG="${DEBUG:-false}"

# Run initialization
init_ksh

# Clean up
unset -f log_info log_warn log_error log_debug
unset -f setup_environment setup_aliases setup_functions
unset -f setup_history setup_prompt setup_key_bindings
unset -f setup_completion show_welcome init_ksh
