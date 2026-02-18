# Circuit Examples

This directory contains reusable code skeletons for creating zk-SNARK circuits using gnark and circom.

## Quick Start

1. **Check Requirements**
   ```bash
   npm run example:test -- --grep "Requirements Check"
   ```

2. **Compile a Circuit**
   ```bash
   # Compile circom circuit
   npm run example:compile:circom
   
   # Compile gnark circuit
   npm run example:compile:gnark
   ```

3. **Run Trusted Setup**
   ```bash
   npm run example:setup
   ```

4. **Run Tests**
   ```bash
   npm run example:test
   ```

## Directory Structure

- `circuits/` - Example circuits (gnark and circom)
- `helpers/` - Reusable helper functions
- `tests/` - Integration and unit tests
- `artifacts/` - Generated files (created during compilation)

## Circuit Types

### Gnark Circuits
Located in `circuits/gnark/`. See [Gnark README](circuits/gnark/README.md) for details.

### Circom Circuits
Located in `circuits/circom/`. See [Circom README](circuits/circom/README.md) for details.

## Helper Functions

All helper functions are in the `helpers/` directory:
- `compile-circuit.ts` - Circuit compilation utilities
- `setup-circuit.ts` - Trusted setup utilities
- `test-circuit.ts` - Testing and benchmarking utilities

## Integration with Bridge Contracts

These circuits are designed for cross-chain bridge operations. See the main [README](../README.md) for integration details.

## Troubleshooting

- **CLI not found**: Install required CLIs (see Dockerfile)
- **Compilation errors**: Check circuit syntax and dependencies
- **Setup fails**: Ensure R1CS and WASM files exist
