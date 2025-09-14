# Chain Rice Go Backend

A modular Go backend application for the Chain Rice blockchain ecosystem, designed to be packaged and reused through the stack system.

## Architecture

This backend is structured as a main application that exports and orchestrates two core modules:

- **Blockchain Module** (`./blockchain/`) - Cosmos SDK based blockchain functionality
- **Accounting Module** (`./accounting/`) - Comprehensive accounting and financial management

## Project Structure

```
chain-rice/
├── main.go              # Main application entry point
├── go.mod               # Main module dependencies
├── go.sum               # Dependency checksums
├── Makefile             # Build and run commands
├── README.md            # This file
├── blockchain/          # Blockchain module
│   ├── module.go        # Blockchain application logic
│   ├── go.mod           # Blockchain module dependencies
│   └── go.sum           # Blockchain dependency checksums
└── accounting/          # Accounting module
    ├── module.go        # Accounting application logic
    ├── go.mod           # Accounting module dependencies
    └── go.sum           # Accounting dependency checksums
```

## Features

### Main Application
- Orchestrates both blockchain and accounting services
- Provides unified CLI interface
- Exports functions for external use
- Context-aware service management

### Blockchain Module
- Cosmos SDK integration
- Configurable blockchain parameters
- RPC, gRPC, and API endpoints
- CLI interface for blockchain operations

### Accounting Module
- SQLite database integration
- Invoice management system
- Transaction tracking
- Validator management
- RESTful API endpoints

## Quick Start

### Prerequisites
- Go 1.21 or later
- Make (for build automation)

### Installation

1. Clone the repository and navigate to the backend directory:
```bash
cd apps/chain-rice/backend/go
```

2. Install dependencies:
```bash
make deps
```

3. Build the application:
```bash
make build
```

### Running the Application

#### Run All Services
```bash
make run
```

#### Run Individual Services
```bash
# Blockchain service only
make blockchain

# Accounting service only
make accounting
```

#### CLI Commands
```bash
# Show help
./build/chain-rice help

# Run blockchain CLI
./build/chain-rice blockchain

# Run accounting CLI
./build/chain-rice accounting
```

## Development

### Available Make Commands

- `make build` - Build all modules and main application
- `make run` - Run the main application
- `make blockchain` - Run blockchain service only
- `make accounting` - Run accounting service only
- `make test` - Run tests for all modules
- `make clean` - Clean build artifacts
- `make mod-tidy` - Tidy go modules
- `make deps` - Install dependencies
- `make fmt` - Format code
- `make lint` - Lint code

### Module Development

Each module is designed to be independently usable and can be imported by other applications:

```go
import (
    "chain-rice/blockchain"
    "chain-rice/accounting"
)

// Create blockchain app
blockchainApp, err := blockchain.NewApp(ctx)

// Create accounting app
accountingApp, err := accounting.NewApp(ctx)
```

## Stack Integration

This backend is designed to be packaged and reused through the stack system. The modular structure allows for:

- Individual module deployment
- Shared functionality across applications
- Easy integration with other stack components
- Independent scaling of services

## Configuration

### Blockchain Configuration
- Chain ID: `chain-rice`
- RPC Address: `tcp://localhost:26657`
- gRPC Address: `localhost:9090`
- API Address: `localhost:1317`

### Accounting Configuration
- Database: SQLite (`./accounting.db`)
- Port: `8080`
- Host: `localhost`

## Dependencies

### Main Dependencies
- Cosmos SDK v0.50.1
- gRPC and Protocol Buffers
- Cobra CLI framework
- Viper configuration management

### Module Dependencies
- **Blockchain**: Cosmos SDK, gRPC
- **Accounting**: SQLite3, Cobra CLI

## License

This project is part of the Chain Rice ecosystem and follows the project's licensing terms.
