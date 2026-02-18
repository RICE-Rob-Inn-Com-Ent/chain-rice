# Rice Monorepo Contracts

Unified contract repository supporting multiple blockchain networks and cross-chain bridges.

**TypeScript/Node** (connectors, Hardhat, zk-SNARK helpers) lives in **`.devcontainer/node/contract/`** (STACK/node). Rust, Solidity, GraphQL and Docker stay here in `.devcontainer/contract/`.

## Structure

```
.devcontainer/contract/          # Rust, Solidity, GraphQL, Docker, circuit sources (STACK/contract)
├── app/ app.rs, app.sol
├── rust/, graphql/
├── examples/circuits/         # circom, gnark
├── Cargo.toml                 # workspace root (members: ., ../../.project/*/contract)
├── .clippy.toml, .rustfmt.toml
└── Dockerfile

.devcontainer/node/contract/    # TypeScript/Node (STACK/node)
├── app/app.ts                 # Main TS logic (bridge + zk-proof)
├── ts/                        # Chain connectors
├── examples/helpers|scripts|tests/
├── package.json, hardhat.config.js, tsconfig.json
└── types.d.ts
```

All connectors and bridges are consolidated in `app/app.ts` and `app/config.ts`. Network configuration uses environment variables from `env.dev.txt`, `env.stag.txt`, or `env.prod.txt`.

Project contracts are located in:
- `.project/ceramix/contract/` - CRMX token
- `.project/meowtopia/contract/` - MWTP token
- `.project/code-rice/contract/` - CRICE token

## Supported Chains

### EVM Chains
- Ethereum Mainnet
- Polygon
- BNB Smart Chain (BSC)
- Avalanche
- Arbitrum One
- Optimism
- Base
- zkSync Era
- Linea
- Scroll
- Mantle

### CosmWasm
- ChainRice (main chain)

### Non-EVM Blockchains
- Bitcoin (BTC)
- Solana (SOL)
- Cardano (ADA)
- Polkadot (DOT)
- Near Protocol (NEAR)
- Algorand (ALGO)
- Tezos (XTZ)
- Tron (TRX)
- Litecoin (LTC)
- Dogecoin (DOGE)
- Stellar (XLM)
- Ripple (XRP)
- TON (The Open Network)
- Sui
- Aptos
- Internet Computer (ICP)

## Token System Architecture

Each project has its own token contract deployed on ChainRice blockchain:
- **Ceramix**: CRMX token (`.project/ceramix/contract/`)
- **Meowtopia**: MWTP token (`.project/meowtopia/contract/`)
- **Code Rice**: CRICE token (`.project/code-rice/contract/`)

### Token Creation

Tokens are created via the blockchain CosmosSDK module using `MsgCreateToken`. The blockchain automatically handles token signing and verification.

### Contract Features
- Token minting and burning
- Transfer functionality
- Balance queries
- Token info queries

### Using Connectors

Project contracts use connectors to communicate with the blockchain:

```typescript
import { createCosmWasmConnector } from ".devcontainer/node/contract/app/app";

// Connector automatically uses env variables from .env file
const cosmwasm = createCosmWasmConnector();
await cosmwasm.connectWithSigner(process.env.COSMOS_MNEMONIC!);

// Query token balance
const balance = await cosmwasm.queryContract(contractAddress, {
  balance: { address: "crice1..." }
});

// Execute token transfer
await cosmwasm.executeContract(contractAddress, {
  transfer: { recipient: "crice1...", amount: "1000" }
});
```

## Multi-Chain Connectors

Connectors provide reusable integrations for connecting to blockchains (similar to `bot/in/` for AI models). All connectors are in `bridge.ts`.

### EVM Connector

Supports all major EVM chains: Ethereum, Polygon, BSC, Avalanche, Arbitrum, Optimism. Network configuration uses environment variables.

```typescript
import { createEVMConnector } from ".devcontainer/node/contract/app/app";

// Uses env variables: ETH_RPC_URL, ETH_CHAIN_ID, ETH_EXPLORER_URL, etc.
const ethereum = createEVMConnector("ethereum", process.env.PRIVATE_KEY);
const balance = await ethereum.getBalance(address);
const txHash = await ethereum.deployContract(abi, bytecode, ...args);
```

### CosmWasm Connector

Connects to ChainRice blockchain and other CosmWasm chains. Uses environment variables for configuration.

```typescript
import { createCosmWasmConnector } from ".devcontainer/node/contract/app/app";

// Uses env variables: COSMOS_RPC_URL, COSMOS_PREFIX, COSMOS_GAS_PRICE
const cosmwasm = createCosmWasmConnector();
await cosmwasm.connectWithSigner(process.env.COSMOS_MNEMONIC!);
const result = await cosmwasm.queryContract(contractAddress, queryMsg);
```

### Network Configuration

Network configuration is a reusable template in `app/config.ts` that reads from environment variables defined in `env.txt`.  
Choose the active environment with:
- `just dev` - for sandboxing and testing
- `just stag` - for staging environment
- `just prod` - for production with real data

`env.txt` should contain:
- `ETH_RPC_URL`, `POLYGON_RPC_URL`, `BSC_RPC_URL`, etc.
- `ETH_CHAIN_ID`, `POLYGON_CHAIN_ID`, etc.
- `ETH_EXPLORER_URL`, `POLYGON_EXPLORER_URL`, etc.
- `COSMOS_RPC_URL`, `COSMOS_PREFIX`, `COSMOS_GAS_PRICE`

## Cross-Chain Bridges

All bridge functionality is consolidated in `app/app.ts`:

### EVM to CosmWasm

Lock tokens on EVM, mint on CosmWasm:

```typescript
import { EVMToCosmWasmBridge } from ".devcontainer/node/contract/app/app";

const bridge = new EVMToCosmWasmBridge({
  evmChain: evmConnector,
  cosmwasmChain: cosmWasmConnector,
  lockContractAddress: "...",
  mintContractAddress: "..."
});

const lockTx = await bridge.lockTokens(tokenAddress, amount, recipient);
const mintTx = await bridge.mintOnCosmWasm(proof, amount, recipient);
```

### CosmWasm to EVM

Burn tokens on CosmWasm, unlock on EVM:

```typescript
import { CosmWasmToEVMBridge } from ".devcontainer/node/contract/app/app";

const bridge = new CosmWasmToEVMBridge({
  cosmwasmChain: cosmWasmConnector,
  evmChain: evmConnector,
  burnContractAddress: "...",
  unlockContractAddress: "..."
});

const burnTx = await bridge.burnTokens(amount, recipient);
const unlockTx = await bridge.unlockOnEVM(proof, amount, recipient, tokenAddress);
```

### Bridge Relay

Automated relay service for monitoring and processing bridge transactions:

```typescript
import { BridgeRelay } from ".devcontainer/node/contract/app/app";

const relay = new BridgeRelay(
  evmConnector,
  cosmWasmConnector,
  lockContractAddress,
  mintContractAddress,
  burnContractAddress,
  unlockContractAddress
);

await relay.monitorEVMEvents(lockContractAddress, async (event) => {
    // Process bridge event
});

// Relay complete bridge operations
const { lockTx, mintTx } = await relay.relayEVMToCosmWasm(tokenAddress, amount, recipient);
const { burnTx, unlockTx } = await relay.relayCosmWasmToEVM(amount, recipient, tokenAddress);
```

## Development

### Solidity Contracts

```bash
cd .devcontainer/node/contract
npx hardhat compile
npx hardhat test
```

### Rust Contracts (CosmWasm)

Each project has its own contract:

```bash
# Ceramix (CRMX)
cd .project/ceramix/contract
cargo build --release --target wasm32-unknown-unknown

# Meowtopia (MWTP)
cd .project/meowtopia/contract
cargo build --release --target wasm32-unknown-unknown

# Code Rice (CRICE)
cd .project/code-rice/contract
cargo build --release --target wasm32-unknown-unknown
```

### TypeScript Bridge & Connectors

All connectors and bridges are in `app/app.ts` and `app/config.ts`. Install dependencies from contract directory:

```bash
# From project root
npm install

# Bridge uses environment variables for configuration
# Set up .env file from env.dev.txt, env.stag.txt, or env.prod.txt
```

## Environment Variables

```bash
# EVM RPC URLs
ETH_RPC_URL=https://...
POLYGON_RPC_URL=https://...
BSC_RPC_URL=https://...
AVAX_RPC_URL=https://...
ARB_RPC_URL=https://...
OPT_RPC_URL=https://...

# CosmWasm
COSMWASM_RPC_URL=http://localhost:26657

# Private Keys (for signing)
PRIVATE_KEY=0x...
```

## Project Tokens

Each project has its own independent token contract:

1. **Token Creation**: Tokens are created via blockchain CosmosSDK `MsgCreateToken` message
2. **Blockchain Verification**: The blockchain automatically handles token signing and verification
3. **Contract Deployment**: Deploy CosmWasm contract for each project
4. **Connector Integration**: Use connectors to interact with blockchain and contracts

### Token Symbols
- **Ceramix**: CRMX (`.project/ceramix/contract/`)
- **Meowtopia**: MWTP (`.project/meowtopia/contract/`)
- **Code Rice**: CRICE (`.project/code-rice/contract/`)

All tokens operate on ChainRice blockchain with address prefix `crice1`.

## Zero-Knowledge Proofs (zk-SNARKs)

The project uses zk-SNARKs for privacy-preserving cross-chain bridge operations. Complete infrastructure is provided as a reusable API service.

### Production Features

- **Full Groth16 verification** using arkworks (BN254 curve)
- **Circom circuit compilation** (Circom → R1CS/WASM)
- **Gnark circuit compilation** to WASM (<3MB, <200ms)
- **Trusted setup** for generating proving and verification keys
- **Proof generation and verification** via API
- **Idiomatic Rust** with no unwrap(), deny panics, pedantic clippy
- **WASM optimizations** for size and performance

### TypeScript (`zk-proof.ts`) - For EVM/Bridge Side

Used for generating proofs on the EVM side and bridge operations:

```typescript
import { generateBridgeProof, verifyBridgeProof } from ".devcontainer/node/contract/app/app";

// Generate proof for bridge operation
const proofString = await generateBridgeProof({
  a: 3,
  b: 4,
  // ... other circuit inputs
});

// Verify proof (for testing)
const isValid = await verifyBridgeProof(proofString);
```

**Features:**
- Generate zk-SNARK proofs using `snarkjs` (Groth16)
- Serialize/deserialize proofs for bridge transmission
- Verify proofs before sending to CosmWasm
- Integrates with `bridge.ts` for cross-chain operations

**Usage in Bridge:**
```typescript
import { generateBridgeProof, EVMToCosmWasmBridge } from ".devcontainer/node/contract/app/app";

// Generate proof for token lock
const proof = await generateBridgeProof({
  tokenAddress,
  amount,
  recipient,
  // ... other inputs
});

// Send proof to CosmWasm for minting
await bridge.mintOnCosmWasm(proof, amount, recipient);
```

### Rust (`zk-proof.rs`) - For CosmWasm Contracts

Used for verifying proofs on-chain in CosmWasm smart contracts:

```rust
use contract::zk_proof::{verify_bridge_proof, VerificationKey};

// In your CosmWasm contract
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::MintFromBridge { proof, amount, recipient } => {
            // Load verification key from contract state
            let vk: VerificationKey = load_verification_key(deps.storage)?;
            
            // Verify the proof
            let is_valid = verify_bridge_proof(&proof, &vk)?;
            
            if !is_valid {
                return Err(ContractError::InvalidProof {});
            }
            
            // Mint tokens if proof is valid
            // ...
        }
    }
}
```

**Features:**
- Verify Groth16 proofs generated by `snarkjs`
- Compatible with proof format from TypeScript side
- Validate proof structure before expensive verification
- Designed for CosmWasm contract integration

**Features:**
- ✅ **Full Groth16 verification** implemented with arkworks (enabled by default)
- ✅ **Production-ready** cryptographic verification on BN254 curve
- ✅ **Compatible with snarkjs** proof format
- ✅ **No unwrap() calls** - all error handling is explicit
- ✅ **Pedantic clippy** - strict linting for code quality

The `arkworks` feature is enabled by default. Full cryptographic verification is implemented in `verify_proof_arkworks()`.

### Workflow

1. **EVM Side (TypeScript):**
   - User locks tokens on EVM chain
   - Generate zk-proof using `generateBridgeProof()`
   - Send proof to bridge

2. **Bridge:**
   - Receives proof from EVM
   - Optionally verifies proof (off-chain)
   - Sends proof to CosmWasm contract

3. **CosmWasm Side (Rust):**
   - Contract receives proof
   - Verifies proof using `verify_bridge_proof()`
   - Mints tokens if proof is valid

### Setup

1. **Install dependencies:**
```bash
npm install snarkjs
```

2. **Compile circuits via API:**
```bash
# Compile Circom circuit
curl -X POST http://localhost:8080/api/zk/circuit/compile-circom \
  -H "Content-Type: application/json" \
  -d '{
    "circuitPath": "./circuits/lock.circom",
    "outputDir": "./artifacts",
    "circuitName": "lock"
  }'

# Or compile Gnark circuit
curl -X POST http://localhost:8080/api/zk/circuit/compile-gnark \
  -H "Content-Type: application/json" \
  -d '{
    "circuitPath": "./circuits/bridge.go",
    "outputPath": "./artifacts/bridge.wasm"
  }'
```

3. **Run trusted setup via API:**
```bash
curl -X POST http://localhost:8080/api/zk/circuit/setup \
  -H "Content-Type: application/json" \
  -d '{
    "r1csPath": "./artifacts/r1cs/lock.r1cs",
    "wasmPath": "./artifacts/wasm/lock_js/lock.wasm",
    "outputDir": "./artifacts",
    "circuitName": "lock"
  }'
```

4. **Build optimized WASM:**
```bash
# Build with arkworks verification enabled (default)
npm run build:wasm

# Optimize WASM size
npm run optimize:wasm
```

5. **Use in CosmWasm contract:**
```rust
// In your contract's Cargo.toml
[dependencies]
contract = { path = "../../contract" }
# arkworks is enabled by default - no need to specify features
```

