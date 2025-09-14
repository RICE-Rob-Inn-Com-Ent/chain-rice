# ChainRice Protocol Buffer Structure

## Overview

The ChainRice protocol buffer definitions have been reorganized into a clean, modular structure with three main categories: `@enums/`, `@messages/`, and `@services/`.

## Directory Structure

```
proto/
├── enums/                    # All enum definitions
│   ├── payment.proto         # Payment-related enums
│   ├── tax.proto            # Tax-related enums
│   ├── cafe.proto           # Cafe-related enums
│   └── index.proto          # Central enum import point
├── messages/                 # All message definitions
│   ├── accounting/          # Accounting messages
│   │   ├── invoice.proto    # Invoice messages
│   │   └── index.proto      # Accounting import point
│   ├── cafe/                # Cafe messages
│   │   ├── menu.proto       # Menu, orders, reservations
│   │   └── index.proto      # Cafe import point
│   ├── invoice/             # Modular invoice system
│   │   ├── invoice.proto    # Main invoice structure
│   │   ├── parties.proto    # Transaction parties
│   │   ├── items.proto      # Invoice items
│   │   ├── payment.proto    # Payment information
│   │   ├── tax.proto        # Tax information
│   │   ├── index.proto      # Invoice import point
│   │   └── README.md        # Invoice module documentation
│   ├── cat.proto            # Cat-related messages
│   ├── blockchain.proto     # Blockchain core (genesis & params)
│   └── index.proto          # Central message import point
├── services/                 # All service definitions
│   ├── query.proto          # Query services
│   ├── tx.proto             # Transaction services
│   ├── accounting.proto     # Accounting services
│   ├── cafe.proto           # Cafe services
│   └── index.proto          # Central service import point
├── index.proto              # Main entry point
├── query.proto              # DEPRECATED - use services/query.proto
├── tx.proto                 # DEPRECATED - use services/tx.proto
├── gov.proto                # DEPRECATED - use messages/accounting/
├── cafe.proto               # DEPRECATED - use messages/cafe/
└── README.md                # This file
```

## Usage

### Import Everything

```protobuf
import "index.proto";
```

### Import Specific Modules

```protobuf
// Import all enums
import "enums/index.proto";

// Import all messages
import "messages/index.proto";

// Import all services
import "services/index.proto";

// Import specific modules
import "messages/accounting/index.proto";
import "messages/cafe/index.proto";
import "messages/invoice/index.proto";
```

### Import Specific Files

```protobuf
// Import specific enums
import "enums/payment.proto";
import "enums/tax.proto";

// Import specific messages
import "messages/accounting/invoice.proto";
import "messages/cafe/menu.proto";

// Import specific services
import "services/accounting.proto";
import "services/cafe.proto";
```

## Module Organization

### @enums/

Contains all enum definitions organized by domain:

- **payment.proto**: Payment methods, statuses, invoice types
- **tax.proto**: Tax types, VAT rates
- **cafe.proto**: Order statuses, reservation statuses, menu categories

### @messages/

Contains all message definitions organized by domain:

- **accounting/**: Invoice, dashboard stats, financial data
- **cafe/**: Menu items, orders, reservations, tables, customers
- **invoice/**: Modular invoice system with separate components
- **cat.proto**: Cat-related messages
- **blockchain.proto**: Blockchain core (genesis state and module parameters)

### @services/

Contains all gRPC service definitions:

- **query.proto**: Query services
- **tx.proto**: Transaction services
- **accounting.proto**: Accounting operations
- **cafe.proto**: Cafe operations

## Migration Guide

### Old Structure → New Structure

- `query.proto` → `services/query.proto`
- `tx.proto` → `services/tx.proto`
- `gov.proto` → `messages/accounting/`
- `cafe.proto` → `messages/cafe/`
- Enum definitions → `enums/`

### Deprecated Files

The following files are marked as DEPRECATED and will be removed in future versions:

- `query.proto` (use `services/query.proto`)
- `tx.proto` (use `services/tx.proto`)
- `gov.proto` (use `messages/accounting/`)
- `cafe.proto` (use `messages/cafe/`)

## Benefits

1. **Clear Separation**: Enums, messages, and services are clearly separated
2. **Modular Design**: Each domain has its own module
3. **Easy Navigation**: Logical directory structure
4. **Maintainability**: Easier to find and modify specific components
5. **Scalability**: Easy to add new modules without cluttering
6. **Import Flexibility**: Import everything or just what you need

## Development Guidelines

1. **New Enums**: Add to appropriate file in `enums/`
2. **New Messages**: Add to appropriate module in `messages/`
3. **New Services**: Add to appropriate file in `services/`
4. **Cross-References**: Use imports to reference other modules
5. **Documentation**: Update README files when adding new modules
