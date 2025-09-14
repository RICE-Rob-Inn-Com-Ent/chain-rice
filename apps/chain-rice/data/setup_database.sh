#!/bin/bash

# Chain Rice Database Setup Script
# Quick setup for the modular PostgreSQL database

set -e

echo "🍚 Chain Rice Database Setup"
echo "============================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if PostgreSQL is running
if ! pg_isready -q; then
    print_error "PostgreSQL is not running. Please start PostgreSQL first."
    exit 1
fi

print_status "Setting up Chain Rice database..."

# Option 1: Run complete setup (recommended)
if [ "$1" = "complete" ] || [ -z "$1" ]; then
    print_status "Running complete database setup..."
    sudo -u postgres psql -f 00_setup.sql
    print_success "Complete database setup finished!"
    
# Option 2: Run individual components
elif [ "$1" = "components" ]; then
    print_status "Running database components individually..."
    
    # Create database if it doesn't exist
    sudo -u postgres psql -c "CREATE DATABASE chain_rice;" 2>/dev/null || print_status "Database chain_rice already exists"
    
    # Run each component
    for file in 01_extensions.sql 02_validators.sql 03_bitcoin.sql 04_ai_analytics.sql 05_indexes.sql 06_views.sql 07_functions.sql 08_triggers.sql 09_sample_data.sql 10_comments.sql; do
        if [ -f "$file" ]; then
            print_status "Running $file..."
            sudo -u postgres psql -d chain_rice -f "$file"
        else
            print_error "File $file not found!"
            exit 1
        fi
    done
    
    print_success "All components setup finished!"
    
# Option 3: Reset database
elif [ "$1" = "reset" ]; then
    print_status "Resetting database..."
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS chain_rice;"
    sudo -u postgres psql -f 00_setup.sql
    print_success "Database reset completed!"
    
# Option 4: Show help
else
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  complete   - Run complete database setup (default)"
    echo "  components - Run components individually"
    echo "  reset      - Reset and recreate database"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Run complete setup"
    echo "  $0 complete     # Run complete setup"
    echo "  $0 components   # Run components individually"
    echo "  $0 reset        # Reset database"
    exit 1
fi

echo ""
print_success "🍚 Chain Rice database is ready!"
echo ""
echo "Database: chain_rice"
echo "Tables: validators, bitcoin_addresses, bitcoin_transactions, ai_analysis_results, ai_predictions, network_statistics"
echo "Views: validator_overview, network_summary, bitcoin_balance_summary"
echo "Sample validators: alice, validator1, validator2"
echo ""
echo "Connect with: psql -U postgres -d chain_rice"
