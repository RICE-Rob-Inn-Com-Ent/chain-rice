# 🌍 Rice-Dev Ecosystem

**Comprehensive multi-language development platform with centralized package management and bridge architecture**

## 🎯 Overview

Rice-Dev is a complete development ecosystem that provides:

- **Backend Services**: Go-based microservices with blockchain, accounting, and tax APIs
- **Bridge Libraries**: Connect any backend language (.NET, BEAM, Python, JVM, PHP) to Go services
- **Frontend Applications**: Multi-platform apps (Flutter, Kotlin/Android, Swift/iOS, TypeScript/Web)
- **Development Tools**: Comprehensive tooling for automation, contracts, data science, and DevOps
- **Centralized Management**: Nix packages, Docker containerization, and unified Makefile commands

## 🏗️ Architecture

```
Rice-Dev Ecosystem
├── 🍚 ChainRice (Main Application)
│   ├── Backend Services (Go)
│   ├── Frontend Applications
│   └── AI/ML Services
├── 🐱 Meowtopia (Cat Cafe App)
│   ├── Backend Services
│   └── Frontend Applications
├── 🌉 Bridge Libraries
│   ├── .NET Bridge
│   ├── BEAM Bridge (Erlang/Elixir)
│   ├── Python Bridge
│   ├── JVM Bridge (Java/Kotlin/Scala)
│   └── PHP Bridge
└── 🛠️ Development Tools
    ├── AUTO (Build automation)
    ├── CONTRACTS (Smart contracts)
    ├── DATA (AI, SQL, data science)
    ├── DEV (DevOps, infrastructure)
    └── MISC (Experimental languages)
```

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** (for containerized deployment)
- **Nix** (for package management)
- **Make** (for build automation)

### Installation

```bash
# Clone the repository
git clone https://github.com/chainrice/rice-dev.git
cd rice-dev

# Install everything and start all services
make up

# Or use Docker for everything
make docker-all
```

### Development Mode

```bash
# Start development environment with hot reload
make dev

# Open all interfaces in browser
make open
```

## 📦 Package Management

### Nix Packages

The ecosystem uses Nix for centralized package management:

```bash
# Enter Nix development environment
make nix

# Build specific packages
nix build .#chainrice-go
nix build .#chainrice-dotnet-bridge
nix build .#chainrice-flutter-app
```

### Available Packages

- **Backend**: `backend.nix` - Go services and bridge libraries
- **Frontend**: `frontend.nix` - Mobile and web applications  
- **Tools**: `tools.nix` - Development and automation tools

## 🌉 Bridge Architecture

Connect any backend language to ChainRice Go services:

### .NET Bridge

```csharp
using ChainRice.Bridge;

var client = new ChainRiceClient();
var invoice = await client.Accounting.CreateInvoiceAsync(new CreateInvoiceRequest
{
    CustomerName = "John Doe",
    Amount = 1000.00m,
    Currency = "PLN"
});
```

### Python Bridge

```python
from chainrice_bridge import ChainRiceClient

client = ChainRiceClient()
invoice = await client.accounting.create_invoice({
    "customer_name": "John Doe",
    "amount": 1000.00,
    "currency": "PLN"
})
```

### Elixir/Erlang Bridge

```elixir
alias ChainRice.Bridge

client = ChainRice.Bridge.new()
{:ok, invoice} = ChainRice.Bridge.AccountingApi.create_invoice(client, %{
  customer_name: "John Doe",
  amount: 1000.00,
  currency: "PLN"
})
```

## 🐳 Docker Deployment

### All Services

```bash
# Start everything via Docker
make docker-all

# View logs
docker-compose -f stacks/tools/DEV/docker/docker-compose.yml logs -f
```

### Individual Services

```bash
# Start specific services
make chainrice
make meowtopia
make bridges
```

## 🛠️ Development Tools

### AUTO (Build Automation)

- Protocol Buffer generation
- Multi-language build scripts
- CI/CD automation

### CONTRACTS (Smart Contracts)

- CosmWasm contracts (Rust)
- Solidity contracts
- Multi-blockchain support

### DATA (Data Science)

- Python AI/ML tools
- Julia scientific computing
- Octave/Matlab analysis
- SQL databases (PostgreSQL, MySQL, SQLite)

### DEV (DevOps)

- Kubernetes deployment
- Terraform infrastructure
- Monitoring (Prometheus, Grafana)
- Security scanning

## 📱 Frontend Applications

### Mobile Apps

- **Flutter/Dart**: Cross-platform mobile app
- **Kotlin/Android**: Native Android app
- **Swift/iOS**: Native iOS app

### Web Apps

- **Next.js**: React-based web app
- **Nuxt.js**: Vue-based web app
- **Angular**: TypeScript-based web app

## 🔧 Available Commands

### Main Commands

```bash
make up          # Install everything and start all services
make down        # Stop all containers and services
make docker-all  # Start all services via Docker
make nix         # Enter Nix development environment
```

### Service Management

```bash
make start       # Start entire ecosystem
make stop        # Stop all services
make status      # Check status of all services
make clean       # Clean all builds
```

### Bridge Services

```bash
make bridges     # Start all bridge services
make dotnet-bridge    # Start .NET bridge
make beam-bridge      # Start BEAM bridge
make python-bridge    # Start Python bridge
make jvm-bridge       # Start JVM bridge
make php-bridge       # Start PHP bridge
```

### Development

```bash
make dev         # Development mode with hot reload
make proto       # Generate protobuf files
make build       # Build all services
make test        # Run all tests
```

### Interfaces

```bash
make open        # Open all interfaces in browser
make open-chainrice    # Open ChainRice interfaces
make open-meowtopia    # Open Meowtopia interfaces
make open-bridges      # Open bridge interfaces
```

## 🌐 Service Ports

| Service | Port | Description |
|---------|------|-------------|
| ChainRice Go API | 8080 | Main accounting API |
| ChainRice Tax API | 8081 | Tax calculation API |
| .NET Bridge | 8082 | .NET bridge service |
| BEAM Bridge | 8083 | Erlang/Elixir bridge |
| Python Bridge | 8084 | Python bridge service |
| JVM Bridge | 8085 | Java/Kotlin bridge |
| PHP Bridge | 8086 | PHP bridge service |
| AUTO Tools | 8087 | Build automation |
| CONTRACTS | 8088 | Smart contracts |
| DATA Tools | 8089 | Data science tools |
| DEV Tools | 8090 | DevOps tools |
| MISC Tools | 8091 | Experimental tools |
| Flutter App | 3000 | Mobile app |
| Next.js App | 3001 | Web app |
| Nuxt.js App | 3002 | Web app |
| Angular App | 3003 | Web app |
| Blockchain RPC | 26657 | Cosmos SDK RPC |
| Blockchain REST | 1317 | Cosmos SDK REST |

## 📚 Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Backend Services](stacks/backend/README.md)
- [Frontend Applications](stacks/frontend/README.md)
- [Development Tools](stacks/tools/README.md)
- [Bridge Libraries](stacks/backend/README.md#bridge-libraries)
- [Nix Packages](stacks/tools/DEV/packages/README.md)
- [Docker Setup](stacks/tools/DEV/docker/README.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/chainrice/rice-dev/issues)
- **Discussions**: [GitHub Discussions](https://github.com/chainrice/rice-dev/discussions)
- **Documentation**: [Wiki](https://github.com/chainrice/rice-dev/wiki)

---

**Rice-Dev Ecosystem** - Building the future of multi-language development platforms 🌍