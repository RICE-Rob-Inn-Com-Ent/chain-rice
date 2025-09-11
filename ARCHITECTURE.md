## ChainRice Architecture

- Web UI: `meowtopia/frontend/web` (Vite + React + Tailwind)
- Backend API: `meowtopia/backend` (FastAPI + PostgreSQL)
- Blockchain: Cosmos SDK app in `app/`, CLI in `cmd/`, modules in `x/`

### Services and Ports
- Frontend (Vite dev): 3000
- Backend (Uvicorn): 8000
- PostgreSQL: 5432
- Blockchain REST: 1317, RPC: 26657, P2P: 26656

### Local Development
- Orchestrated with `docker-compose.yml` profiles: `app` (web+api+db), `blockchain` (node)
- Makefile targets wrap scripts in `scripts/`

### Data Flow
React UI -> FastAPI -> Postgres; UI and API optionally talk to blockchain REST/RPC for on-chain features.

### Configuration
- `.env` for compose, service-specific `.env` files under each service
- Future `settings.json` can toggle profiles and dev flags across scripts

### Docs
- See per-folder README for commands and quick tips.
