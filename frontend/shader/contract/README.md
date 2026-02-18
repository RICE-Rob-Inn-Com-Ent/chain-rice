# Contract – TypeScript/Node (STACK/node)

TypeScript and Node tooling for Rice contracts: connectors, Hardhat, zk-SNARK helpers, and tests.

- **Source:** `.devcontainer/node/contract/` (this folder). **Config:** `package.json` and `tsconfig.json` are consolidated in **`.devcontainer/node/`** (STACK/node root).
- **Circuit sources** (circom, gnark) and **artifacts** stay in `.devcontainer/contract/examples/`; scripts reference them via `../../contract/examples/`.

Full docs, connector usage, and bridge API: **[.devcontainer/contract/README.md](../../contract/README.md)**.

## Quick start

```bash
# From .devcontainer/node
pnpm install   # or npm install
bun run contract:compile
bun run contract:test
# Or: npx hardhat compile / npx hardhat test (Hardhat config is in node root)
```

Imports from other packages:

```ts
import { createEVMConnector, createCosmWasmConnector } from ".devcontainer/node/contract/app/app";
```
