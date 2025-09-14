#!/bin/bash
# =============================================================================
# Chain Rice Environment Loader
# =============================================================================
# This script loads environment variables from the .env file and makes them
# available to the current shell session.
#
# Usage: source load-env.sh
# Or: . load-env.sh
# =============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo "Please copy env.example to .env and configure it:"
    echo "  cp env.example .env"
    echo "  # Edit .env with your settings"
    return 1
fi

# Load environment variables
echo "Loading environment variables from $ENV_FILE..."

# Source the .env file
source "$ENV_FILE"

# Verify critical variables are set
if [[ -z "$CHAIN_RICE_ROOT" ]]; then
    echo "Warning: CHAIN_RICE_ROOT not set in .env file"
fi

if [[ -z "$CHAIN_RICE_SCRIPTS" ]]; then
    echo "Warning: CHAIN_RICE_SCRIPTS not set in .env file"
fi

echo "Environment loaded successfully!"
echo "Project Root: $CHAIN_RICE_ROOT"
echo "Scripts Directory: $CHAIN_RICE_SCRIPTS"
echo "Build Type: $BUILD_TYPE"
echo "Parallel Jobs: $PARALLEL_JOBS"

# Show available services
echo ""
echo "Available Services:"
echo "  Rust API:     Port $RUST_API_PORT"
echo "  Scala API:    Port $SCALA_API_PORT"
echo "  Go Service:   Port $GO_SERVICE_PORT"
echo "  Python API:  Port $PYTHON_SERVICE_PORT"
echo "  Node Service: Port $NODE_SERVICE_PORT"
echo "  Java Service: Port $JAVA_SERVICE_PORT"

# Show feature flags
echo ""
echo "Feature Flags:"
echo "  Docker:       $FEATURE_DOCKER"
echo "  Database:     $FEATURE_DATABASE"
echo "  Redis:        $FEATURE_REDIS"
echo "  Monitoring:   $FEATURE_MONITORING"
echo "  Logging:      $FEATURE_LOGGING"
echo "  Backup:       $FEATURE_BACKUP"

echo ""
echo "Environment ready! You can now run the Chain Rice scripts."
echo "Try: ./start.sh status"
