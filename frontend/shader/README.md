# STACK/node

Konfiguracja środowiska **Node.js / npm / yarn / pnpm / bun**, **TypeScript**, **JavaScript** i powiązanych narzędzi w repozytorium.

## Zawartość

- **Monorepo** – `package.json`, `pnpm-workspace.yaml`
- **Contract (TS/Node)** – `contract/` (kod); `package.json` i `tsconfig.json` w tym katalogu (skrypty `contract:*`, Hardhat, zależności); źródła Solidity/Rust w `.devcontainer/contract/`
- **Commitlint** – `.commitlintrc.js`
- **Prettier** – `.prettierrc.js`, `.prettierignore`
- **Semantic Release** – `.releaserc.js`
- **TypeScript** – `tsconfig.json`
- **Next.js** – `next.config.js`
- **Tailwind CSS** – `tailwind.config.ts`, `postcss.config.ts`
- **Vitest** – `vitest.config.js`
- **Lighthouse** – `lighthouserc.json`
- **OpenTelemetry** – `instrumentation.ts`
- **npm** – `.npmrc`

W tym katalogu znajdują się też `package.json` i `pnpm-workspace.yaml` (definicja monorepo). CI używa konfiguracji z tego katalogu (np. commitlint: `-c .devcontainer/node/.commitlintrc.js`).
