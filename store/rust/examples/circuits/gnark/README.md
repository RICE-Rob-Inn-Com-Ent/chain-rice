# Gnark Circuit Guide

## Overview

Gnark is a Go library for building zk-SNARK circuits. This guide covers creating circuits for bridge operations.

## Circuit Structure

```go
type BridgeLockCircuit struct {
    // Public inputs
    TokenAddress frontend.Variable `gnark:",public"`
    Amount       frontend.Variable `gnark:",public"`
    
    // Private inputs
    LockTxHash   frontend.Variable
    MerkleProof  []frontend.Variable
}
```

## Available Constraints

- `api.AssertIsEqual(a, b)` - Assert equality
- `api.AssertIsDifferent(a, b)` - Assert inequality
- `api.AssertIsLessOrEqual(a, b)` - Assert less than or equal

## Best Practices

1. Use descriptive variable names
2. Add comments for complex constraints
3. Validate all inputs
4. Keep circuits focused and modular

## Performance Optimization

- Minimize constraint count
- Use efficient hash functions
- Optimize for WASM size (< 3MB target)
- Keep compilation time < 200ms

## Common Patterns

See `bridge_lock.go` for a complete example.
