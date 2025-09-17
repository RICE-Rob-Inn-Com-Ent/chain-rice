# 🌍 Rice-Dev Ecosystem

## A comprehensive development ecosystem with reusable stacks and complete applications

Rice-Dev is a modern development platform that combines **technology stacks** for rapid prototyping and **complete applications** for real-world solutions, all unified under a single workspace.

## 🗂️ What's Inside

### 🧱 Stacks (`stacks/`)

Reusable technology templates and tools:

- **🏗️ Frameworks** - Frontend frameworks (Angular, React/Next.js, Nuxt, Vue, Flutter)
- **🗣️ Languages** - Programming language stacks (Go, Python, Rust, Java, C#, etc.)
- **🛠️ Tools** - Development tools (Docker, Terraform, Ansible, Bash, Nix)
- **🎮 Unity** - Game development templates

### 🚀 Apps (`apps/`)

Complete production-ready applications:

- **🍚 ChainRice** - Blockchain accounting system with AI receipt recognition
- **🐱 Meowtopia** - Cat cafe management system with gaming integration

### 🔧 Root (`/`)

Ecosystem orchestration and configuration:

- **Makefile** - Unified build and deployment commands
- **VS Code Workspace** - Multi-root development environment
- **Documentation** - Architecture guides and usage instructions

## 🚀 Quick Start

### Prerequisites

- **Git** - Version control
- **Make** - Build automation
- **Docker** (optional) - Containerization
- **Cursor** (recommended) - Development environment

### Getting Started

```bash
# Clone the repository
git clone <repository-url>
cd rice-dev

# Open in Cursor (recommended)
cursor rice-dev.code-workspace

# Install everything and start all services
make up

# Or step by step:
make install    # Install all dependencies
make build      # Build all services
make start      # Start all applications
make open       # Open all interfaces

# Check status
make status
```

## 🎯 How It Works

### For Learning & Prototyping

Use **stacks** to quickly set up development environments:

```bash
# Explore Go development
cd stacks/langs/go
make setup
make build
make test

# Try React/Next.js framework
cd stacks/frontend/typescript/next
yarn install
yarn dev

# Experiment with Docker containers
cd stacks/tools/docker
docker-compose up
```

### For Production Applications

Use **apps** for complete solutions:

```bash
# Run ChainRice accounting system
cd apps/chain-rice
make start

# Run Meowtopia cafe management
cd apps/meowtopia
make start

# Or run everything from root
make chainrice    # Start ChainRice only
make meowtopia    # Start Meowtopia only
make start        # Start everything
```

## 📚 Stacks Overview

### 🏗️ Frameworks (`stacks/frameworks/`)

| Framework | Description | Technologies |
|-----------|-------------|-------------|
| **Angular** | Angular framework setup | TypeScript, Angular CLI, RxJS |
| **Next.js** | React with Next.js | React 19, TypeScript, Tailwind CSS, Vite |
| **Vue** | Vue.js framework | Vue 3, Composition API, TypeScript |
| **Flutter** | Mobile development | Dart, Flutter SDK, Material Design |

### 🗣️ Languages (`stacks/langs/`)

| Language | Description | Use Cases |
|----------|-------------|-----------|
| **Go** | Systems programming | APIs, microservices, blockchain |
| **Python** | General purpose | AI/ML, data science, web backends |
| **Rust** | Systems programming | Performance-critical applications |
| **Java** | Enterprise development | Large-scale applications |
| **C#** | Microsoft ecosystem | .NET applications, games |
| **JavaScript/TypeScript** | Web development | Frontend, Node.js backends |
| **Clojure** | Functional programming | Data processing, concurrent systems |
| **Solidity** | Smart contracts | Blockchain development |
| **Proto** | Protocol Buffers | API definitions, gRPC services |

### 🛠️ Tools (`stacks/tools/`)

| Tool | Description | Purpose |
|------|-------------|---------|
| **Docker** | Containerization | Application packaging, deployment |
| **Terraform** | Infrastructure as Code | Cloud resource management |
| **Ansible** | Configuration Management | Server automation |
| **Bash** | Shell scripting | Automation, build scripts |
| **Makefile** | Build automation | Consistent build processes |
| **Nix** | Package management | Reproducible environments |

## 🚀 Apps Overview

### 🍚 ChainRice

#### Blockchain Accounting System

- **AI Receipt Recognition** - Automatic receipt processing with OCR
- **Invoice Management** - Create, edit, and track invoices
- **Tax Compliance** - Automated tax calculations and reporting
- **Blockchain Integration** - Immutable transaction records
- **Multi-language Support** - Ukrainian, Polish, English

**Tech Stack**: Cosmos SDK, Go, React, Python, PostgreSQL

### 🐱 Meowtopia

#### Cat Cafe Management System

- **Cat Management** - Track cats, adoptions, health records
- **Menu System** - Manage cafe menu, orders, payments
- **Reservation System** - Table bookings and scheduling
- **Gaming Integration** - Rewards system with blockchain
- **Real-time Updates** - WebSocket-based live updates

**Tech Stack**: React, Node.js, Rust, GraphQL, PostgreSQL

## 🔧 Root Commands

### Ecosystem Management

```bash
make help           # Show all available commands
make up             # Install everything and start all services
make down           # Stop all containers and services
make install        # Install all dependencies
make build          # Build all projects
make start          # Start all applications
make stop           # Stop all services
make status         # Check service status
make clean          # Clean all builds
make test           # Run all tests
```

### Application Control

```bash
make chainrice      # Start ChainRice only
make meowtopia      # Start Meowtopia only
make docker         # Start with Docker Compose
```

### Development

```bash
make dev            # Development mode with hot reload and auto-open
make dev-setup      # Set up development environment
make quick          # Install + build + start + open
make logs           # Show application logs
make backup         # Backup databases
```

## 🌐 Available Services

After running `make start`, access:

### 🍚 ChainRice Services

- **Frontend**: <http://localhost:5173>
- **API**: <http://localhost:8004>
- **AI Service**: <http://localhost:8005>

### 🐱 Meowtopia Services

- **Frontend**: <http://localhost:5174>
- **API**: <http://localhost:8006>

### ⛓️ Blockchain

- **REST API**: <http://localhost:1317>
- **RPC**: <http://localhost:26657>

## 🏗️ Architecture

```text
Rice-Dev Ecosystem
├── 🧱 Stacks (Reusable Templates)
│   ├── 🏗️ Frameworks → Frontend templates
│   ├── 🗣️ Languages → Backend templates  
│   ├── 🛠️ Tools → DevOps templates
│   └── 🎮 Unity → Game templates
│
├── 🚀 Apps (Complete Solutions)
│   ├── 🍚 ChainRice → Accounting + AI + Blockchain
│   └── 🐱 Meowtopia → Cafe + Gaming + Blockchain
│
└── 🔧 Root (Orchestration)
    ├── Makefile → Unified commands
    ├── Workspace → VS Code configuration
    └── Documentation → Guides and references
```

## 💡 Usage Patterns

### 1. **Learning Mode**

Explore individual stacks to learn technologies:

```bash
cd stacks/langs/rust
make setup && make build
```

### 2. **Prototyping Mode**

Combine stacks for rapid prototyping:

```bash
cp -r stacks/frameworks/next my-project
cp -r stacks/langs/go/modules my-project/backend
```

### 3. **Production Mode**

Use complete apps as reference or foundation:

```bash
cd apps/meowtopia
make deploy
```

### 4. **Development Mode**

Work on the entire ecosystem:

```bash
cursor rice-dev.code-workspace
make dev-setup
make dev
```

## 🔐 Configuration

### Environment Variables

Each stack and app includes environment templates:

- `stacks/*/env.example` - Stack-specific variables
- `apps/*/env.example` - Application-specific variables
- Root `.env.example` - Ecosystem-wide variables

### Cursor Workspace

The `rice-dev.code-workspace` provides:

- Multi-root workspace with all stacks and apps
- Language-specific settings and extensions
- Unified tasks for building and running
- Integrated terminal configurations

### Docker Support

Most stacks and apps include Docker configurations:

- `docker-compose.yml` - Multi-service orchestration
- `Dockerfile` - Individual service containers
- `.dockerignore` - Optimized build contexts

## 🎯 Benefits

### For Developers

- **🚀 Rapid Setup** - Pre-configured development environments
- **📚 Learning Resources** - Comprehensive examples across technologies
- **🔧 Best Practices** - Battle-tested patterns and configurations
- **🎨 Consistency** - Uniform development experience

### For Teams

- **📋 Standardization** - Consistent project structures
- **⚡ Efficiency** - Reduced setup and configuration time
- **🤝 Knowledge Sharing** - Centralized expertise and patterns
- **🔄 Maintainability** - Clear separation of concerns

### For Projects

- **🧩 Flexibility** - Mix and match technologies as needed
- **📈 Scalability** - Proven patterns for growth
- **✅ Quality** - Built-in testing and deployment practices
- **📖 Documentation** - Comprehensive guides and examples

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch
3. **Add** your stack, tool, or app
4. **Follow** existing patterns and documentation
5. **Test** your changes
6. **Submit** a pull request

### Adding a New Stack

```bash
mkdir stacks/langs/your-language
cd stacks/langs/your-language
# Add README.md, Makefile, and example code
```

### Adding a New App

```bash
mkdir apps/your-app
cd apps/your-app
# Add ARCHITECTURE.md, README.md, and source code
```

## 📄 License

MIT License - see the [LICENSE](LICENSE) file for details.

---

**Rice-Dev Ecosystem** - Empowering developers with reusable stacks and production-ready applications. 🚀

*Ready to build something amazing? Start with `make quick` and explore the possibilities!*
