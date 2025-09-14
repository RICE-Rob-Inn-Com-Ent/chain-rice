#!/bin/tcsh -f
# =============================================================================
# Chain Rice TC Shell Build Automation Script
# =============================================================================
# This script provides comprehensive build automation for the Chain Rice
# project using TC shell (tcsh) syntax with enhanced features over csh.
#
# Usage: ./build.tcsh [options] [targets]
# Options:
#   --help, -h          Show this help message
#   --verbose, -v       Enable verbose output
#   --clean             Clean before building
#   --test              Run tests after building
#   --install           Install after building
#   --parallel, -j N    Use N parallel jobs
#   --config CONFIG     Use specific configuration
#   --profile           Enable profiling
#   --debug             Enable debug symbols
# =============================================================================

# =============================================================================
# Configuration Variables
# =============================================================================

# Colors (ANSI escape codes)
set RED = '\033[0;31m'
set GREEN = '\033[0;32m'
set YELLOW = '\033[1;33m'
set BLUE = '\033[0;34m'
set PURPLE = '\033[0;35m'
set CYAN = '\033[0;36m'
set NC = '\033[0m'

# Project configuration
set PROJECT_ROOT = "/media/mrdinkelman/Dev/chain-rice"
set BUILD_DIR = "$PROJECT_ROOT/build"
set LOG_DIR = "$PROJECT_ROOT/logs"
set TARGET_DIR = "$PROJECT_ROOT/target"
set CACHE_DIR = "$PROJECT_ROOT/.cache"
set PROFILE_DIR = "$PROJECT_ROOT/profiles"

# Build configuration
set BUILD_TYPE = "release"
set PARALLEL_JOBS = 4
set VERBOSE = 0
set CLEAN_BUILD = 0
set RUN_TESTS = 0
set INSTALL_BUILD = 0
set ENABLE_PROFILE = 0
set ENABLE_DEBUG = 0
set CONFIG_NAME = "default"

# Component paths
set RUST_DIR = "$PROJECT_ROOT/examples/rust"
set SCALA_DIR = "$PROJECT_ROOT/examples/scala"
set GO_DIR = "$PROJECT_ROOT/examples/go"
set PYTHON_DIR = "$PROJECT_ROOT/examples/python"
set NODE_DIR = "$PROJECT_ROOT/examples/node"
set JAVA_DIR = "$PROJECT_ROOT/examples/java"

# Build statistics
set BUILD_START_TIME = `date +%s`
set TOTAL_BUILD_TIME = 0
set COMPONENTS_BUILT = 0
set COMPONENTS_FAILED = 0

# =============================================================================
# Utility Functions
# =============================================================================

log_info() {
    echo "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo "${RED}[ERROR]${NC} $*"
}

log_debug() {
    if ($VERBOSE) then
        echo "${BLUE}[DEBUG]${NC} $*"
    endif
}

log_step() {
    echo "${CYAN}[STEP]${NC} $*"
}

log_success() {
    echo "${GREEN}[✓]${NC} $*"
}

log_failure() {
    echo "${RED}[✗]${NC} $*"
}

# Enhanced timing function
get_timestamp() {
    date +%s
}

get_elapsed_time() {
    set current_time = `get_timestamp`
    @ elapsed = $current_time - $BUILD_START_TIME
    echo $elapsed
}

format_time() {
    set seconds = $1
    @ hours = $seconds / 3600
    @ minutes = ($seconds % 3600) / 60
    @ secs = $seconds % 60
    
    if ($hours > 0) then
        printf "%02d:%02d:%02d" $hours $minutes $secs
    else if ($minutes > 0) then
        printf "%02d:%02d" $minutes $secs
    else
        printf "%02ds" $secs
    endif
}

# =============================================================================
# Directory and Environment Setup
# =============================================================================

setup_directories() {
    log_info "Setting up build directories..."
    
    set dirs = ("$BUILD_DIR" "$LOG_DIR" "$TARGET_DIR" "$CACHE_DIR" "$PROFILE_DIR")
    foreach dir ($dirs)
        if (! -d "$dir") then
            mkdir -p "$dir"
            log_debug "Created directory: $dir"
        endif
    end
    
    log_success "Build directories ready"
}

setup_environment() {
    log_info "Setting up build environment..."
    
    # Set environment variables
    setenv BUILD_TYPE "$BUILD_TYPE"
    setenv PARALLEL_JOBS "$PARALLEL_JOBS"
    setenv PROJECT_ROOT "$PROJECT_ROOT"
    setenv BUILD_DIR "$BUILD_DIR"
    setenv TARGET_DIR "$TARGET_DIR"
    setenv ENABLE_PROFILE "$ENABLE_PROFILE"
    setenv ENABLE_DEBUG "$ENABLE_DEBUG"
    
    # Rust environment
    if (-d "$HOME/.cargo") then
        setenv PATH "$HOME/.cargo/bin:$PATH"
        setenv CARGO_TARGET_DIR "$TARGET_DIR"
        setenv RUST_BACKTRACE "1"
        
        if ($ENABLE_PROFILE) then
            setenv CARGO_PROFILE "true"
        endif
        
        if ($ENABLE_DEBUG) then
            setenv RUST_DEBUG "1"
        endif
    endif
    
    # Go environment
    if (-d "$HOME/go") then
        setenv GOPATH "$HOME/go"
        setenv GOBIN "$HOME/go/bin"
        setenv PATH "$HOME/go/bin:$PATH"
        
        if ($ENABLE_PROFILE) then
            setenv GO_PROFILE "true"
        endif
        
        if ($ENABLE_DEBUG) then
            setenv GO_DEBUG "1"
        endif
    endif
    
    # Java environment
    if (-d "/usr/lib/jvm/java-17-openjdk") then
        setenv JAVA_HOME "/usr/lib/jvm/java-17-openjdk"
        setenv PATH "$JAVA_HOME/bin:$PATH"
        
        if ($ENABLE_DEBUG) then
            setenv JAVA_DEBUG "true"
        endif
    endif
    
    # Scala environment
    if (-d "/usr/local/scala") then
        setenv SCALA_HOME "/usr/local/scala"
        setenv PATH "$SCALA_HOME/bin:$PATH"
    endif
    
    # Node.js environment
    if (-d "$HOME/.nvm") then
        setenv NODE_ENV "development"
        
        if ($ENABLE_DEBUG) then
            setenv NODE_DEBUG "1"
        endif
    endif
    
    # Python environment
    setenv PYTHONPATH "$PROJECT_ROOT:$PYTHONPATH"
    
    if ($ENABLE_DEBUG) then
        setenv PYTHONDEBUG "1"
    endif
    
    log_success "Build environment configured"
}

# =============================================================================
# Enhanced Build Functions
# =============================================================================

build_rust() {
    log_step "Building Rust components..."
    set start_time = `get_timestamp`
    
    if (! -d "$RUST_DIR") then
        log_warn "Rust directory not found: $RUST_DIR"
        return 1
    endif
    
    cd "$RUST_DIR"
    
    # Check if Cargo.toml exists
    if (! -f "Cargo.toml") then
        log_warn "Cargo.toml not found in $RUST_DIR"
        return 1
    endif
    
    # Build command with enhanced options
    set build_cmd = "cargo build"
    if ("$BUILD_TYPE" == "release") then
        set build_cmd = "$build_cmd --release"
    endif
    
    if ($ENABLE_PROFILE) then
        set build_cmd = "$build_cmd --profile=dev"
    endif
    
    if ($VERBOSE) then
        set build_cmd = "$build_cmd --verbose"
    endif
    
    # Execute build with timing
    log_debug "Executing: $build_cmd"
    if ($VERBOSE) then
        eval $build_cmd
    else
        eval $build_cmd > "$LOG_DIR/rust-build.log" 2>&1
    endif
    
    set end_time = `get_timestamp`
    @ build_time = $end_time - $start_time
    
    if ($status == 0) then
        log_success "Rust components built successfully (${build_time}s)"
        @ COMPONENTS_BUILT++
        return 0
    else
        log_failure "Rust build failed (${build_time}s)"
        @ COMPONENTS_FAILED++
        return 1
    endif
}

build_scala() {
    log_step "Building Scala components..."
    set start_time = `get_timestamp`
    
    if (! -d "$SCALA_DIR") then
        log_warn "Scala directory not found: $SCALA_DIR"
        return 1
    endif
    
    cd "$SCALA_DIR"
    
    # Check if build.sbt exists
    if (! -f "build.sbt") then
        log_warn "build.sbt not found in $SCALA_DIR"
        return 1
    endif
    
    # Build command with enhanced options
    set build_cmd = "sbt compile"
    if ($VERBOSE) then
        set build_cmd = "$build_cmd -v"
    endif
    
    if ($ENABLE_PROFILE) then
        set build_cmd = "$build_cmd -J-XX:+UnlockDiagnosticVMOptions -J-XX:+DebugNonSafepoints"
    endif
    
    # Execute build with timing
    log_debug "Executing: $build_cmd"
    if ($VERBOSE) then
        eval $build_cmd
    else
        eval $build_cmd > "$LOG_DIR/scala-build.log" 2>&1
    endif
    
    set end_time = `get_timestamp`
    @ build_time = $end_time - $start_time
    
    if ($status == 0) then
        log_success "Scala components built successfully (${build_time}s)"
        @ COMPONENTS_BUILT++
        return 0
    else
        log_failure "Scala build failed (${build_time}s)"
        @ COMPONENTS_FAILED++
        return 1
    endif
}

build_go() {
    log_step "Building Go components..."
    set start_time = `get_timestamp`
    
    if (! -d "$GO_DIR") then
        log_warn "Go directory not found: $GO_DIR"
        return 1
    endif
    
    cd "$GO_DIR"
    
    # Check if go.mod exists
    if (! -f "go.mod") then
        log_warn "go.mod not found in $GO_DIR"
        return 1
    endif
    
    # Create bin directory
    if (! -d "bin") then
        mkdir -p bin
    endif
    
    # Build command with enhanced options
    set build_cmd = "go build"
    if ("$BUILD_TYPE" == "release") then
        set build_cmd = "$build_cmd -ldflags='-s -w'"
    endif
    
    if ($ENABLE_PROFILE) then
        set build_cmd = "$build_cmd -race"
    endif
    
    if ($ENABLE_DEBUG) then
        set build_cmd = "$build_cmd -gcflags='-N -l'"
    endif
    
    set build_cmd = "$build_cmd -o bin/service ."
    
    # Execute build with timing
    log_debug "Executing: $build_cmd"
    if ($VERBOSE) then
        eval $build_cmd
    else
        eval $build_cmd > "$LOG_DIR/go-build.log" 2>&1
    endif
    
    set end_time = `get_timestamp`
    @ build_time = $end_time - $start_time
    
    if ($status == 0) then
        log_success "Go components built successfully (${build_time}s)"
        @ COMPONENTS_BUILT++
        return 0
    else
        log_failure "Go build failed (${build_time}s)"
        @ COMPONENTS_FAILED++
        return 1
    endif
}

build_python() {
    log_step "Building Python components..."
    set start_time = `get_timestamp`
    
    if (! -d "$PYTHON_DIR") then
        log_warn "Python directory not found: $PYTHON_DIR"
        return 1
    endif
    
    cd "$PYTHON_DIR"
    
    # Check if requirements.txt exists
    if (-f "requirements.txt") then
        log_info "Installing Python dependencies..."
        if ($VERBOSE) then
            pip install -r requirements.txt
        else
            pip install -r requirements.txt > "$LOG_DIR/python-deps.log" 2>&1
        endif
        
        if ($status != 0) then
            log_failure "Python dependency installation failed"
            @ COMPONENTS_FAILED++
            return 1
        endif
    endif
    
    # Check if setup.py exists
    if (-f "setup.py") then
        log_info "Building Python package..."
        set build_cmd = "python setup.py build"
        
        if ($ENABLE_DEBUG) then
            set build_cmd = "$build_cmd --debug"
        endif
        
        if ($VERBOSE) then
            eval $build_cmd
        else
            eval $build_cmd > "$LOG_DIR/python-build.log" 2>&1
        endif
        
        set end_time = `get_timestamp`
        @ build_time = $end_time - $start_time
        
        if ($status == 0) then
            log_success "Python components built successfully (${build_time}s)"
            @ COMPONENTS_BUILT++
            return 0
        else
            log_failure "Python build failed (${build_time}s)"
            @ COMPONENTS_FAILED++
            return 1
        endif
    else
        log_info "No setup.py found, skipping Python build"
        return 0
    endif
}

build_node() {
    log_step "Building Node.js components..."
    set start_time = `get_timestamp`
    
    if (! -d "$NODE_DIR") then
        log_warn "Node.js directory not found: $NODE_DIR"
        return 1
    endif
    
    cd "$NODE_DIR"
    
    # Check if package.json exists
    if (! -f "package.json") then
        log_warn "package.json not found in $NODE_DIR"
        return 1
    endif
    
    # Install dependencies
    log_info "Installing Node.js dependencies..."
    set install_cmd = "npm install"
    
    if ($VERBOSE) then
        eval $install_cmd
    else
        eval $install_cmd > "$LOG_DIR/node-deps.log" 2>&1
    endif
    
    if ($status != 0) then
        log_failure "Node.js dependency installation failed"
        @ COMPONENTS_FAILED++
        return 1
    endif
    
    # Build if build script exists
    if (grep -q '"build"' package.json) then
        log_info "Building Node.js components..."
        set build_cmd = "npm run build"
        
        if ($ENABLE_DEBUG) then
            set build_cmd = "$build_cmd --debug"
        endif
        
        if ($VERBOSE) then
            eval $build_cmd
        else
            eval $build_cmd > "$LOG_DIR/node-build.log" 2>&1
        endif
        
        set end_time = `get_timestamp`
        @ build_time = $end_time - $start_time
        
        if ($status == 0) then
            log_success "Node.js components built successfully (${build_time}s)"
            @ COMPONENTS_BUILT++
            return 0
        else
            log_failure "Node.js build failed (${build_time}s)"
            @ COMPONENTS_FAILED++
            return 1
        endif
    else
        log_info "No build script found, skipping Node.js build"
        return 0
    endif
}

build_java() {
    log_step "Building Java components..."
    set start_time = `get_timestamp`
    
    if (! -d "$JAVA_DIR") then
        log_warn "Java directory not found: $JAVA_DIR"
        return 1
    endif
    
    cd "$JAVA_DIR"
    
    # Check if pom.xml exists (Maven)
    if (-f "pom.xml") then
        log_info "Building with Maven..."
        set build_cmd = "mvn compile"
        
        if ($ENABLE_PROFILE) then
            set build_cmd = "$build_cmd -Pprofile"
        endif
        
        if ($ENABLE_DEBUG) then
            set build_cmd = "$build_cmd -Dmaven.compiler.debug=true"
        endif
        
        if ($VERBOSE) then
            eval $build_cmd
        else
            eval $build_cmd > "$LOG_DIR/java-build.log" 2>&1
        endif
        
        set end_time = `get_timestamp`
        @ build_time = $end_time - $start_time
        
        if ($status == 0) then
            log_success "Java components built successfully (${build_time}s)"
            @ COMPONENTS_BUILT++
            return 0
        else
            log_failure "Java build failed (${build_time}s)"
            @ COMPONENTS_FAILED++
            return 1
        endif
    endif
    
    # Check if build.gradle exists (Gradle)
    if (-f "build.gradle") then
        log_info "Building with Gradle..."
        set build_cmd = "./gradlew build"
        
        if ($ENABLE_PROFILE) then
            set build_cmd = "$build_cmd --profile"
        endif
        
        if ($ENABLE_DEBUG) then
            set build_cmd = "$build_cmd --debug"
        endif
        
        if ($VERBOSE) then
            eval $build_cmd
        else
            eval $build_cmd > "$LOG_DIR/java-build.log" 2>&1
        endif
        
        set end_time = `get_timestamp`
        @ build_time = $end_time - $start_time
        
        if ($status == 0) then
            log_success "Java components built successfully (${build_time}s)"
            @ COMPONENTS_BUILT++
            return 0
        else
            log_failure "Java build failed (${build_time}s)"
            @ COMPONENTS_FAILED++
            return 1
        endif
    endif
    
    log_warn "No build file found for Java components"
    return 1
}

# =============================================================================
# Enhanced Test Functions
# =============================================================================

test_rust() {
    log_step "Testing Rust components..."
    set start_time = `get_timestamp`
    
    if (! -d "$RUST_DIR") then
        log_warn "Rust directory not found: $RUST_DIR"
        return 1
    endif
    
    cd "$RUST_DIR"
    
    set test_cmd = "cargo test"
    if ($VERBOSE) then
        set test_cmd = "$test_cmd --verbose"
    endif
    
    if ($ENABLE_PROFILE) then
        set test_cmd = "$test_cmd --profile=dev"
    endif
    
    log_debug "Executing: $test_cmd"
    if ($VERBOSE) then
        eval $test_cmd
    else
        eval $test_cmd > "$LOG_DIR/rust-test.log" 2>&1
    endif
    
    set end_time = `get_timestamp`
    @ test_time = $end_time - $start_time
    
    if ($status == 0) then
        log_success "Rust tests passed (${test_time}s)"
        return 0
    else
        log_failure "Rust tests failed (${test_time}s)"
        return 1
    endif
}

test_scala() {
    log_step "Testing Scala components..."
    set start_time = `get_timestamp`
    
    if (! -d "$SCALA_DIR") then
        log_warn "Scala directory not found: $SCALA_DIR"
        return 1
    endif
    
    cd "$SCALA_DIR"
    
    set test_cmd = "sbt test"
    if ($VERBOSE) then
        set test_cmd = "$test_cmd -v"
    endif
    
    log_debug "Executing: $test_cmd"
    if ($VERBOSE) then
        eval $test_cmd
    else
        eval $test_cmd > "$LOG_DIR/scala-test.log" 2>&1
    endif
    
    set end_time = `get_timestamp`
    @ test_time = $end_time - $start_time
    
    if ($status == 0) then
        log_success "Scala tests passed (${test_time}s)"
        return 0
    else
        log_failure "Scala tests failed (${test_time}s)"
        return 1
    endif
}

test_go() {
    log_step "Testing Go components..."
    set start_time = `get_timestamp`
    
    if (! -d "$GO_DIR") then
        log_warn "Go directory not found: $GO_DIR"
        return 1
    endif
    
    cd "$GO_DIR"
    
    set test_cmd = "go test ./..."
    if ($VERBOSE) then
        set test_cmd = "$test_cmd -v"
    endif
    
    if ($ENABLE_PROFILE) then
        set test_cmd = "$test_cmd -race"
    endif
    
    log_debug "Executing: $test_cmd"
    if ($VERBOSE) then
        eval $test_cmd
    else
        eval $test_cmd > "$LOG_DIR/go-test.log" 2>&1
    endif
    
    set end_time = `get_timestamp`
    @ test_time = $end_time - $start_time
    
    if ($status == 0) then
        log_success "Go tests passed (${test_time}s)"
        return 0
    else
        log_failure "Go tests failed (${test_time}s)"
        return 1
    endif
}

test_python() {
    log_step "Testing Python components..."
    set start_time = `get_timestamp`
    
    if (! -d "$PYTHON_DIR") then
        log_warn "Python directory not found: $PYTHON_DIR"
        return 1
    endif
    
    cd "$PYTHON_DIR"
    
    # Check if pytest is available
    if (which pytest > /dev/null) then
        set test_cmd = "pytest"
        if ($VERBOSE) then
            set test_cmd = "$test_cmd -v"
        endif
        
        if ($ENABLE_PROFILE) then
            set test_cmd = "$test_cmd --profile"
        endif
    else
        set test_cmd = "python -m unittest discover"
    endif
    
    log_debug "Executing: $test_cmd"
    if ($VERBOSE) then
        eval $test_cmd
    else
        eval $test_cmd > "$LOG_DIR/python-test.log" 2>&1
    endif
    
    set end_time = `get_timestamp`
    @ test_time = $end_time - $start_time
    
    if ($status == 0) then
        log_success "Python tests passed (${test_time}s)"
        return 0
    else
        log_failure "Python tests failed (${test_time}s)"
        return 1
    endif
}

test_node() {
    log_step "Testing Node.js components..."
    set start_time = `get_timestamp`
    
    if (! -d "$NODE_DIR") then
        log_warn "Node.js directory not found: $NODE_DIR"
        return 1
    endif
    
    cd "$NODE_DIR"
    
    # Check if test script exists
    if (grep -q '"test"' package.json) then
        set test_cmd = "npm test"
        if ($VERBOSE) then
            set test_cmd = "$test_cmd --verbose"
        endif
        
        log_debug "Executing: $test_cmd"
        if ($VERBOSE) then
            eval $test_cmd
        else
            eval $test_cmd > "$LOG_DIR/node-test.log" 2>&1
        endif
        
        set end_time = `get_timestamp`
        @ test_time = $end_time - $start_time
        
        if ($status == 0) then
            log_success "Node.js tests passed (${test_time}s)"
            return 0
        else
            log_failure "Node.js tests failed (${test_time}s)"
            return 1
        endif
    else
        log_warn "No test script found for Node.js components"
        return 1
    endif
}

# =============================================================================
# Enhanced Clean Functions
# =============================================================================

clean_rust() {
    log_step "Cleaning Rust components..."
    
    if (! -d "$RUST_DIR") then
        log_warn "Rust directory not found: $RUST_DIR"
        return 1
    endif
    
    cd "$RUST_DIR"
    cargo clean
    
    if ($status == 0) then
        log_success "Rust components cleaned"
        return 0
    else
        log_failure "Rust clean failed"
        return 1
    endif
}

clean_scala() {
    log_step "Cleaning Scala components..."
    
    if (! -d "$SCALA_DIR") then
        log_warn "Scala directory not found: $SCALA_DIR"
        return 1
    endif
    
    cd "$SCALA_DIR"
    sbt clean
    
    if ($status == 0) then
        log_success "Scala components cleaned"
        return 0
    else
        log_failure "Scala clean failed"
        return 1
    endif
}

clean_go() {
    log_step "Cleaning Go components..."
    
    if (! -d "$GO_DIR") then
        log_warn "Go directory not found: $GO_DIR"
        return 1
    endif
    
    cd "$GO_DIR"
    go clean
    rm -f bin/*
    
    if ($status == 0) then
        log_success "Go components cleaned"
        return 0
    else
        log_failure "Go clean failed"
        return 1
    endif
}

clean_python() {
    log_step "Cleaning Python components..."
    
    if (! -d "$PYTHON_DIR") then
        log_warn "Python directory not found: $PYTHON_DIR"
        return 1
    endif
    
    cd "$PYTHON_DIR"
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    find . -type f -name "*.pyc" -delete 2>/dev/null
    rm -rf build dist *.egg-info 2>/dev/null
    
    log_success "Python components cleaned"
    return 0
}

clean_node() {
    log_step "Cleaning Node.js components..."
    
    if (! -d "$NODE_DIR") then
        log_warn "Node.js directory not found: $NODE_DIR"
        return 1
    endif
    
    cd "$NODE_DIR"
    rm -rf node_modules dist build 2>/dev/null
    
    log_success "Node.js components cleaned"
    return 0
}

clean_all() {
    log_step "Cleaning all components..."
    
    clean_rust
    clean_scala
    clean_go
    clean_python
    clean_node
    
    # Clean build directories
    rm -rf "$BUILD_DIR"/* 2>/dev/null
    rm -rf "$TARGET_DIR"/* 2>/dev/null
    rm -rf "$CACHE_DIR"/* 2>/dev/null
    rm -rf "$PROFILE_DIR"/* 2>/dev/null
    
    log_success "All components cleaned"
}

# =============================================================================
# Main Build Functions
# =============================================================================

build_all() {
    log_info "Building all components..."
    
    set build_success = 1
    
    # Build components
    build_rust
    if ($status != 0) set build_success = 0
    
    build_scala
    if ($status != 0) set build_success = 0
    
    build_go
    if ($status != 0) set build_success = 0
    
    build_python
    if ($status != 0) set build_success = 0
    
    build_node
    if ($status != 0) set build_success = 0
    
    build_java
    if ($status != 0) set build_success = 0
    
    if ($build_success) then
        log_success "All components built successfully"
        return 0
    else
        log_failure "Some components failed to build"
        return 1
    endif
}

test_all() {
    log_info "Running all tests..."
    
    set test_success = 1
    
    # Test components
    test_rust
    if ($status != 0) set test_success = 0
    
    test_scala
    if ($status != 0) set test_success = 0
    
    test_go
    if ($status != 0) set test_success = 0
    
    test_python
    if ($status != 0) set test_success = 0
    
    test_node
    if ($status != 0) set test_success = 0
    
    if ($test_success) then
        log_success "All tests passed"
        return 0
    else
        log_failure "Some tests failed"
        return 1
    endif
}

# =============================================================================
# Build Statistics and Reporting
# =============================================================================

show_build_summary() {
    set end_time = `get_timestamp`
    @ TOTAL_BUILD_TIME = $end_time - $BUILD_START_TIME
    
    echo
    log_info "Build Summary"
    echo "═══════════════════════════════════════════════════════════════"
    echo "Total Build Time: `format_time $TOTAL_BUILD_TIME`"
    echo "Components Built: $COMPONENTS_BUILT"
    echo "Components Failed: $COMPONENTS_FAILED"
    echo "Build Type: $BUILD_TYPE"
    echo "Parallel Jobs: $PARALLEL_JOBS"
    if ($ENABLE_PROFILE) echo "Profiling: Enabled"
    if ($ENABLE_DEBUG) echo "Debug: Enabled"
    echo "═══════════════════════════════════════════════════════════════"
    
    if ($COMPONENTS_FAILED > 0) then
        log_warn "Build completed with $COMPONENTS_FAILED failures"
        return 1
    else
        log_success "Build completed successfully"
        return 0
    endif
}

# =============================================================================
# Command Line Interface
# =============================================================================

show_help() {
    cat << EOF
Chain Rice TC Shell Build Script

USAGE:
    $0 [OPTIONS] [TARGETS]

OPTIONS:
    --help, -h          Show this help message
    --verbose, -v       Enable verbose output
    --clean             Clean before building
    --test              Run tests after building
    --install           Install after building
    --parallel, -j N    Use N parallel jobs
    --config CONFIG     Use specific configuration
    --type TYPE         Build type (debug|release)
    --profile           Enable profiling
    --debug             Enable debug symbols

TARGETS:
    rust                Build Rust components only
    scala               Build Scala components only
    go                  Build Go components only
    python              Build Python components only
    node                Build Node.js components only
    java                Build Java components only
    all                 Build all components (default)

EXAMPLES:
    $0                          # Build all components
    $0 --clean --test           # Clean, build, and test all
    $0 --verbose rust           # Build Rust with verbose output
    $0 --type release scala     # Build Scala in release mode
    $0 --parallel 8 all         # Build all with 8 parallel jobs
    $0 --profile --debug all    # Build with profiling and debug

DESCRIPTION:
    This script provides comprehensive build automation for the Chain Rice
    project using TC shell with enhanced features including timing,
    profiling, and detailed reporting.

EOF
}

parse_arguments() {
    while ($#argv > 0)
        switch ($argv[1])
            case --help:
            case -h:
                show_help
                exit 0
            case --verbose:
            case -v:
                set VERBOSE = 1
                shift argv
                breaksw
            case --clean:
                set CLEAN_BUILD = 1
                shift argv
                breaksw
            case --test:
                set RUN_TESTS = 1
                shift argv
                breaksw
            case --install:
                set INSTALL_BUILD = 1
                shift argv
                breaksw
            case --parallel:
            case -j:
                if ($#argv > 1) then
                    set PARALLEL_JOBS = $argv[2]
                    shift argv
                    shift argv
                else
                    log_error "Parallel jobs count required"
                    exit 1
                endif
                breaksw
            case --config:
                if ($#argv > 1) then
                    set CONFIG_NAME = $argv[2]
                    shift argv
                    shift argv
                else
                    log_error "Configuration name required"
                    exit 1
                endif
                breaksw
            case --type:
                if ($#argv > 1) then
                    set BUILD_TYPE = $argv[2]
                    shift argv
                    shift argv
                else
                    log_error "Build type required"
                    exit 1
                endif
                breaksw
            case --profile:
                set ENABLE_PROFILE = 1
                shift argv
                breaksw
            case --debug:
                set ENABLE_DEBUG = 1
                shift argv
                breaksw
            case rust:
            case scala:
            case go:
            case python:
            case node:
            case java:
            case all:
                set TARGETS = ($TARGETS $argv[1])
                shift argv
                breaksw
            default:
                log_error "Unknown option: $argv[1]"
                show_help
                exit 1
                breaksw
        endsw
    end
    
    # Default target if none specified
    if ($#TARGETS == 0) then
        set TARGETS = (all)
    endif
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    log_info "Chain Rice TC Shell Build Script"
    log_info "Project: $PROJECT_ROOT"
    log_info "Build Type: $BUILD_TYPE"
    log_info "Parallel Jobs: $PARALLEL_JOBS"
    if ($ENABLE_PROFILE) log_info "Profiling: Enabled"
    if ($ENABLE_DEBUG) log_info "Debug: Enabled"
    
    # Parse command line arguments
    parse_arguments
    
    # Setup environment
    setup_directories
    setup_environment
    
    # Clean if requested
    if ($CLEAN_BUILD) then
        clean_all
    endif
    
    # Build targets
    foreach target ($TARGETS)
        switch ($target)
            case rust:
                build_rust
                breaksw
            case scala:
                build_scala
                breaksw
            case go:
                build_go
                breaksw
            case python:
                build_python
                breaksw
            case node:
                build_node
                breaksw
            case java:
                build_java
                breaksw
            case all:
                build_all
                breaksw
        endsw
    end
    
    # Run tests if requested
    if ($RUN_TESTS) then
        test_all
    endif
    
    # Install if requested
    if ($INSTALL_BUILD) then
        log_info "Installation not implemented yet"
    endif
    
    # Show build summary
    show_build_summary
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Only run main if script is executed directly
if ($0 =~ */build.tcsh) then
    main
endif
