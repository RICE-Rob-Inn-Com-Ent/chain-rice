# ChainRice Nix Development Environment

This Nix flake provides a comprehensive development environment for the ChainRice blockchain tax system, importing logic and configurations from all relevant stacks in the `../../../../stacks/` directory.

## 🚀 Quick Start

```bash
# Enter the complete development environment
nix develop

# Enter stack-specific environments
nix develop .#go       # Go development (Cosmos SDK + Tax API)
nix develop .#react    # React frontend development
nix develop .#nextjs   # Next.js full-stack development
nix develop .#rust     # Rust smart contracts (CosmWasm)
nix develop .#proto    # Protocol Buffers with Buf
nix develop .#julia    # Julia functions development
nix develop .#python   # Python backend services
nix develop .#infra    # Infrastructure tools (Docker, Terraform, Ansible)
```

## 📦 Included Stacks

### 🐹 Go Stack
- **Go 1.24** with Cosmos SDK support
- SQLite with CGO enabled
- Protocol Buffers and gRPC tools
- Blockchain development tools
- **Packages**: `go`, `gopls`, `protobuf`, `sqlite`, `grpcurl`, etc.

### ⚛️ React Stack  
- **Node.js 22** with npm, yarn, pnpm
- TypeScript and development tools
- Vite for fast development
- ESLint, Prettier for code quality
- **Packages**: `nodejs`, `typescript`, `vite`, `eslint`, etc.

### ⚡ Next.js Stack
- **Node.js 22** with Next.js framework
- Full-stack React development
- API routes and SSR/SSG support
- Image optimization and performance tools
- **Packages**: `nodejs`, `typescript`, `tailwindcss`, `imagemagick`, etc.

### 🦀 Rust Stack
- **Rust** with CosmWasm smart contract support
- WASM compilation tools
- Cargo development utilities
- Security auditing tools
- **Packages**: `rustc`, `cargo`, `wasm-pack`, `cargo-audit`, etc.

### 📋 Protocol Buffers Stack
- **Protoc** compiler with **Buf** schema management
- Cosmos SDK proto dependencies (cosmos-proto, cosmos-sdk, gogo-proto)
- Multi-language code generation (Go, TypeScript, Rust)
- gRPC tools and gateway generation
- **Packages**: `protobuf`, `buf`, `grpcurl`, `protoc-gen-go`, etc.

### 🔬 Julia Stack
- **Julia** with scientific computing libraries
- OpenBLAS, FFTW, HDF5 support
- Python and R integration
- Jupyter notebook support
- **Packages**: `julia-bin`, `openblas`, `python3`, `R`, etc.

### 🐍 Python Stack
- **Python 3** with comprehensive development tools
- FastAPI, Flask, Django for web development
- Data science libraries (NumPy, Pandas, Matplotlib)
- Testing frameworks (Pytest)
- **Packages**: `python3`, `fastapi`, `numpy`, `pytest`, etc.

### 🐳 Docker Stack
- **Docker** and Docker Compose
- Container analysis tools (Dive, Hadolint)
- Kubernetes tools (kubectl, helm, k9s)
- **Packages**: `docker`, `docker-compose`, `kubectl`, `dive`, etc.

### 🏗️ Terraform Stack
- **Terraform** with cloud provider CLIs
- Infrastructure validation tools
- Security scanning (TFSec, Checkov)
- **Packages**: `terraform`, `awscli2`, `tfsec`, `terragrunt`, etc.

### 🤖 Ansible Stack
- **Ansible** with automation tools
- Cloud provider SDKs
- SSH and networking utilities
- **Packages**: `ansible`, `boto3`, `kubectl`, `openssh`, etc.

## 🌍 Environment Variables

The flake automatically sets up environment variables for all stacks:

### ChainRice Specific
```bash
CHAIN_RICE_ROOT="$PWD"
DB_PATH="$PWD/backend/go/accounting.db"
TAX_API_PORT="8003"
BLOCKCHAIN_API_PORT="1317"
FRONTEND_PORT="5173"
```

### Development Settings
```bash
NODE_ENV="development"
GO_ENV="development"
PYTHON_ENV="development"
RUST_BACKTRACE="1"
CHAINRICE_PROTO_ROOT="$PWD/contracts/proto"
BUF_CACHE_DIR="$HOME/.cache/buf"
VITE_API_URL="http://localhost:8003"
VITE_BLOCKCHAIN_URL="http://localhost:1317"
NEXT_PUBLIC_API_URL="http://localhost:8003"
NEXT_PUBLIC_BLOCKCHAIN_URL="http://localhost:1317"
```

## 📁 Project Structure

```
apps/chain-rice/
├── backend/
│   ├── go/                    # Go services (accounting, blockchain)
│   └── python/                # Python backend services
├── frontend/
│   ├── react/                 # React frontend
│   └── next/                  # Next.js frontend (if used)
├── functions/
│   └── julia/                 # Julia computational functions
├── contracts/
│   ├── proto/                 # Protocol buffer definitions
│   └── rust/                  # Smart contracts (if used)
└── infrastructure/
    ├── docker/                # Docker configurations
    ├── terraform/             # Infrastructure as code
    ├── ansible/               # Configuration management
    └── nix/                   # This Nix environment
        ├── flake.nix          # Main flake configuration
        ├── stacks/            # Stack-specific configurations
        │   ├── go.nix
        │   ├── react.nix
        │   ├── julia.nix
        │   ├── python.nix
        │   ├── docker.nix
        │   ├── terraform.nix
        │   └── ansible.nix
        └── README.md          # This file
```

## 🔧 Development Workflows

### Full Stack Development
```bash
# Enter complete environment
nix develop

# Build Go services
cd backend/go && make build

# Start React frontend
cd frontend/react && npm run dev

# Run Julia functions
cd functions/julia && julia --project=.
```

### Stack-Specific Development
```bash
# Go development only
nix develop .#go
cd backend/go
go mod tidy
go run main.go

# React development only  
nix develop .#react
cd frontend/react
npm install
npm run dev

# Next.js development only
nix develop .#nextjs
cd frontend/next
npm install
npm run dev

# Rust smart contracts only
nix develop .#rust
cd contracts/rust
cargo build --target wasm32-unknown-unknown
cargo test

# Protocol Buffers only
nix develop .#proto
cd contracts/proto
buf generate
buf lint

# Infrastructure work
nix develop .#infra
cd infrastructure
terraform init
ansible-playbook playbooks/setup.yml
```

## 🚀 Services and Ports

| Service | Port | URL |
|---------|------|-----|
| React Frontend | 5173 | http://localhost:5173 |
| Next.js Frontend | 3000 | http://localhost:3000 |
| Tax API | 8003 | http://localhost:8003 |
| Blockchain API | 1317 | http://localhost:1317 |

## 🔍 Useful Commands

### General
```bash
make tax-status-simple    # Check service status
make tax-build           # Build all services
make tax-test            # Run all tests
```

### Go Development
```bash
go mod tidy              # Clean up dependencies
go test ./...            # Run tests
go build                 # Build binary
```

### React Development
```bash
npm install              # Install dependencies
npm run dev              # Start development server
npm run build            # Build for production
npm run lint             # Lint code
```

### Next.js Development
```bash
npm run dev              # Start development server
npm run build            # Build for production
npm run start            # Start production server
npm run lint             # Lint code
```

### Rust Development
```bash
cargo build --target wasm32-unknown-unknown  # Build WASM contracts
cargo test               # Run tests
cargo clippy             # Lint code
cargo audit              # Security audit
cosmwasm-check target/wasm32-unknown-unknown/release/*.wasm  # Validate contracts
```

### Protocol Buffers Development
```bash
buf generate             # Generate code from proto files
buf lint                 # Lint proto files
buf format -w            # Format proto files
buf build                # Build proto files
buf breaking --against .git#branch=main  # Check breaking changes
buf mod update           # Update dependencies
buf push                 # Push to Buf registry
```

### Julia Development
```bash
julia --project=.        # Start Julia with project
] instantiate            # Install packages
] test                   # Run tests
```

### Infrastructure
```bash
docker-compose up        # Start services
terraform plan           # Plan infrastructure
ansible-playbook deploy.yml  # Deploy configuration
```

## 🛠️ Customization

### Adding New Packages
Edit the relevant stack file in `stacks/` directory:
- `stacks/go.nix` - Go packages and tools
- `stacks/react.nix` - Node.js and React tools  
- `stacks/julia.nix` - Julia packages
- etc.

### Environment Variables
Add environment variables to the `envVars` attribute in each stack file or in the main `flake.nix`.

### Shell Hooks
Customize the shell initialization by modifying the `shellHook` in each stack file.

## 🐛 Troubleshooting

### Common Issues

1. **Docker daemon not running**
   ```bash
   sudo systemctl start docker
   ```

2. **Go modules not found**
   ```bash
   cd backend/go && go mod download
   ```

3. **Node modules missing**
   ```bash
   cd frontend/react && npm install
   ```

4. **Julia packages not installed**
   ```bash
   cd functions/julia && julia --project=. -e "using Pkg; Pkg.instantiate()"
   ```

### Getting Help
- Check the logs in each service directory
- Use `nix develop --verbose` for detailed output
- Refer to individual stack documentation in `../../../../stacks/`

## 📚 Related Documentation

- [ChainRice Architecture](../../ARCHITECTURE.md)
- [Go Stack Documentation](../../../../stacks/go/README.md)
- [React Stack Documentation](../../../../stacks/react/README.md)
- [Julia Stack Documentation](../../../../stacks/julia/README.md)
- [Python Stack Documentation](../../../../stacks/python/README.md)

---

**Happy coding with ChainRice! 🌾✨**
