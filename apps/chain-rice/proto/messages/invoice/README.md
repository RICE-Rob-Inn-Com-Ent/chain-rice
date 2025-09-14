# Invoice Module - Documentation

## Overview

The Invoice module has been designed to handle invoices in the ChainRice system. It has been divided into logical components for better organization and code maintainability.

## Module Structure

### Component Files

1. **`invoice.proto`** - Main file with invoice definition
2. **`parties.proto`** - Transaction parties information (seller/buyer)
3. **`items.proto`** - Invoice items (products/services)
4. **`payment.proto`** - Payment information
5. **`tax.proto`** - Tax information
6. **`index.proto`** - Central import point

### Main Data Types

#### Invoice

Main invoice structure containing:

- Basic information (number, type, status)
- Transaction parties (seller/buyer)
- Invoice items
- Payment information
- Tax information
- Metadata (creation/modification dates)

#### Party

Represents a transaction party with:

- Basic information (name, NIP, REGON)
- Address
- Bank account
- Contact details

#### InvoiceItem

Invoice item containing:

- Product/service description
- Quantity and prices
- Tax information
- Additional metadata

#### Payment

Payment information:

- Payment method
- Amounts (total, paid, remaining)
- Payment status
- Bank transfer details

#### Tax

Tax information:

- Net/gross amounts
- Tax details
- VAT rates
- Tax exemptions

## Usage

### Module Import

```protobuf
import "messages/invoice/index.proto";
```

### Usage Example

```protobuf
message CreateInvoiceRequest {
  chainrice.chainrice.invoice.Invoice invoice = 1;
}
```

## Polish Law Compliance

The module has been designed with Polish fiscal requirements in mind:

- NIP and REGON support
- Standard VAT rates (0%, 5%, 8%, 23%)
- Required fields for VAT invoices
- Tax exemption support

## Migration

The old `invoice.proto` file has been marked as DEPRECATED.
Use the new module by importing `messages/invoice/index.proto`.

## Versioning

- **v1.0** - First modular version
- **v0.x** - Pre-split versions (DEPRECATED)
