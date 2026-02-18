# Circom Circuit Guide

## Overview

Circom is a domain-specific language for writing zk-SNARK circuits. This guide covers creating circuits for bridge operations.

## Circuit Structure

```circom
template BridgeLock() {
    signal input tokenAddress;
    signal input amount;
    signal output isValid;
    
    // Constraints
    isValid <== 1;
}

component main = BridgeLock();
```

## Components

Use components from `circomlib`:
- `IsZero()` - Check if value is zero
- `Poseidon()` - Poseidon hash function
- `LessThan()` - Comparison operations

## Best Practices

1. Use meaningful signal names
2. Include necessary components
3. Validate all inputs
4. Keep templates focused

## Performance Optimization

- Minimize signal count
- Use efficient components
- Optimize constraint count
- Test with various inputs

## Common Patterns

See `bridge_lock.circom` for a complete example.
