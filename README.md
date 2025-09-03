# ChainRice Ecosystem 🌟

**ChainRice** is a comprehensive blockchain ecosystem built with Cosmos SDK, featuring a web platform for cafe management and a mobile platform for games, all connected to a unified blockchain backend.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Platform  │    │  Mobile Platform│    │   Blockchain    │
│   (Cafe UI)     │    │   (Games)       │    │   (Cosmos SDK)  │
│                 │    │                 │    │                 │
│ • Vite + React  │    │ • Android/Kotlin│    │ • Tendermint    │
│ • Tailwind CSS  │    │ • iOS/Swift     │    │ • Cosmos SDK    │
│ • CosmosJS      │    │ • Jetpack Compose│   │ • Smart Contracts│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Backend APIs  │
                    │                 │
                    │ • Node.js/Express│
                    │ • PostgreSQL    │
                    │ • Redis Cache   │
                    │ • JWT Auth      │
                    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Docker Desktop** (latest version)
  - [Download for Windows](https://www.docker.com/products/docker-desktop/)
  - [Download for macOS](https://www.docker.com/products/docker-desktop/)
  - [Install for Linux](https://docs.docker.com/engine/install/)
- **Git** - For version control
- **Make** - For running commands
  - **Windows**: Install via [Chocolatey](https://chocolatey.org/) or [WSL](https://docs.microsoft.com/en-us/windows/wsl/)
  - **macOS**: Install via [Homebrew](https://brew.sh/) or Xcode Command Line Tools
  - **Linux**: Usually pre-installed

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd chain-rice
   ```

2. **Start the complete development environment**
   ```bash
   make dev
   ```

3. **Access the application**
   - **Web Frontend**: http://localhost:3000
   - **Backend API**: http://localhost:8000
   - **API Documentation**: http://localhost:8000/docs
   - **Blockchain API**: http://localhost:1317

## ⚡ Quick Commands Reference

```bash
# Start everything
make dev

# Service management
make up           # Start services
make down         # Stop services
make restart      # Restart services
make status       # Check status
make logs         # View logs
make open         # Open all interfaces

# Platform builds
make linux        # Build for Linux
make windows      # Build for Windows
make mac          # Build for macOS

# Help
make help         # Show all commands
```

## 🛠️ Service Management Commands

### 🚀 Development Environment
```bash
make dev          # Start complete development environment
make up           # Start all services
make down         # Stop all services
make restart      # Restart all services
make status       # Show service status
make logs         # View colored logs from all services
make open         # Open all development interfaces in browser
```

### 🏗️ Platform-Specific Builds
```bash
make linux        # Build for Linux platforms
make windows      # Build for Windows platforms
make mac          # Build for macOS platforms
make build-all    # Build for all platforms
```

### 🧪 Testing & Quality
```bash
make test         # Run Go tests
make test-unit    # Run unit tests only
make test-race    # Run tests with race detection
make lint         # Run code linter
```

### 📚 Help & Documentation
```bash
make help         # Show all available commands
```

## 📱 Platform-Specific Startup

### 🌐 Web Platform (Cafe Interface)
```bash
make dev          # Recommended: Start complete environment
# OR
./scripts/dev/start-web.sh
```
- **URL**: http://localhost:3000
- **API**: http://localhost:8000
- **Features**: Cafe management, order processing, blockchain integration

### 🎮 Mobile Platform (Games)
```bash
./scripts/dev/start-mobile.sh
```
- **API**: http://localhost:8000
- **Android**: Open `meowtopia/frontend/mobile/android/` in Android Studio
- **iOS**: Open `meowtopia/frontend/mobile/ios/` in Xcode

### ⛓️ Blockchain Only
```bash
make up           # Start all services including blockchain
# OR
docker-compose --profile blockchain up -d
```
- **RPC**: http://localhost:26657
- **REST API**: http://localhost:1317
- **WebSocket**: ws://localhost:26657/websocket

## 🧪 Testing

### Run All Tests
```bash
make test         # Run Go blockchain tests
./scripts/tests/run-tests.sh  # Run comprehensive test suite
```

### Individual Test Suites
```bash
# Blockchain tests
make test
make test-unit    # Unit tests only
make test-race    # Tests with race detection

# Backend tests
cd meowtopia/backend && python -m pytest

# Web frontend tests
cd meowtopia/frontend/web && npm test

# Code quality
make lint         # Run linter
```

## 🏗️ Development

### Quick Development Start
```bash
make dev          # Start complete development environment
make open         # Open all interfaces in browser
make logs         # Monitor logs
```

### Web Frontend Development
```bash
cd meowtopia/frontend/web
npm install
npm run dev
```

**Key Technologies:**
- **Vite** - Fast build tool
- **React 19** - UI framework
- **Tailwind CSS** - Styling
- **TypeScript** - Type safety
- **Framer Motion** - Animations

### Mobile Development

#### Android (Kotlin)
```bash
cd meowtopia/frontend/mobile/android
# Open in Android Studio
# Sync Gradle files
# Run on device/emulator
```

**Key Technologies:**
- **Kotlin** - Programming language
- **Jetpack Compose** - UI framework
- **Hilt** - Dependency injection
- **Retrofit** - Networking
- **Room** - Local database
- **Coroutines** - Asynchronous programming

#### iOS (Swift)
```bash
cd meowtopia/frontend/mobile/ios
# Open project in Xcode
# Select target device/simulator
# Build and run
```

**Key Technologies:**
- **Swift** - Programming language
- **SwiftUI** - UI framework
- **Combine** - Reactive programming
- **URLSession** - Networking
- **Core Data** - Local database

### Backend Development
```bash
cd meowtopia/backend
pip install poetry
poetry install
poetry run python -m uvicorn app.main:app --reload
```

**Key Technologies:**
- **Python 3.12** - Programming language
- **FastAPI** - Web framework
- **PostgreSQL** - Database
- **Poetry** - Dependency management
- **JWT** - Authentication
- **Uvicorn** - ASGI server

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root or copy from `env.example`:

```bash
cp env.example .env
```

#### Environment Variables (.env)
```env
# Build Configuration
BUILD_ENV=development
BUILD_NUMBER=1
BUILD_DATE=$(date +%Y-%m-%d)
BUILD_VERSION=0.1.0
BUILD_COMMIT=$(git rev-parse --short HEAD)

# Database Configuration
POSTGRES_DB=meowtopia
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=meowtopia-db

# Blockchain Data Directory
BLOCKCHAIN_DATA_DIR=./blockchain-data
```

#### Web Frontend (meowtopia/frontend/web/.env)
```env
VITE_API_URL=http://localhost:8000
VITE_BLOCKCHAIN_RPC_URL=http://localhost:26657
VITE_CHAIN_ID=chainrice-local
VITE_APP_NAME=ChainRice Cafe
VITE_APP_VERSION=1.0.0
```

#### Backend (meowtopia/backend/.env)
```env
POSTGRES_HOST=meowtopia-db
POSTGRES_DB=meowtopia
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
JWT_SECRET=your-super-secret-jwt-key
NODE_ENV=development
```

## 🌐 API Endpoints

### Backend API (Port 8000)
- `GET /health` - Health check
- `GET /docs` - API documentation (Swagger UI)
- `POST /api/auth/login` - User authentication
- `GET /api/cafe/menu` - Cafe menu
- `POST /api/orders` - Create order
- `GET /api/blockchain/status` - Blockchain status

### Blockchain API (Port 1317)
- `GET /cosmos/base/tendermint/v1beta1/node_info` - Node information
- `GET /cosmos/base/tendermint/v1beta1/syncing` - Sync status
- `GET /cosmos/bank/v1beta1/balances/{address}` - Account balances

### Blockchain RPC (Port 26657)
- `GET /status` - Node status
- `GET /block` - Get block
- `POST /broadcast_tx_async` - Broadcast transaction
- `GET /abci_query` - Query state
- `GET /validators` - Validator information

## 🗄️ Database Schema

### PostgreSQL Tables

#### Cafe Management
```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'customer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Menu items
CREATE TABLE menu_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    available BOOLEAN DEFAULT true
);

-- Orders
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    items JSONB NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Game Management
```sql
-- Game sessions
CREATE TABLE game_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    game_type VARCHAR(100) NOT NULL,
    score INTEGER DEFAULT 0,
    duration INTEGER,
    blockchain_tx_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Leaderboard
CREATE TABLE leaderboard (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    game_type VARCHAR(100) NOT NULL,
    score INTEGER NOT NULL,
    rank INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔐 Security

### Authentication
- **JWT Tokens** - Stateless authentication
- **Password Hashing** - bcrypt with salt
- **Rate Limiting** - Express rate limiter
- **CORS** - Cross-origin resource sharing
- **Helmet** - Security headers

### Blockchain Security
- **Private Key Management** - Secure key storage
- **Transaction Signing** - Cryptographic signatures
- **Consensus** - Tendermint BFT
- **State Validation** - ABCI interface

## 📊 Monitoring & Logging

### Health Checks
- **Backend**: `GET /health`
- **Mobile Backend**: `GET /health`
- **Blockchain**: `GET /status`
- **Database**: Connection pool monitoring
- **Redis**: Memory and connection monitoring

### Logging
- **Structured Logging** - JSON format
- **Log Levels** - DEBUG, INFO, WARN, ERROR
- **Request Logging** - Morgan middleware
- **Error Tracking** - Stack traces

## 🚀 Deployment

### Production Build
```bash
# Build all services
docker-compose -f docker-compose.prod.yml build

# Deploy to production
docker-compose -f docker-compose.prod.yml up -d
```

### Environment-Specific Configs
- **Development**: `docker-compose.yml`
- **Testing**: `docker-compose.test.yml`
- **Production**: `docker-compose.prod.yml`

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Guidelines
- **Code Style**: ESLint + Prettier
- **Testing**: Jest + Vitest
- **Documentation**: JSDoc + README
- **Commits**: Conventional Commits

## 📚 Documentation

- **Development Guide**: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) - Complete setup and usage guide
- **Cross-Platform Build**: [docs/CROSS_PLATFORM_BUILD.md](docs/CROSS_PLATFORM_BUILD.md) - Multi-platform build instructions
- **Scripts Documentation**: [scripts/README.md](scripts/README.md) - Scripts directory guide
- **API Documentation**: http://localhost:8000/docs (when running)
- **Blockchain Docs**: [Cosmos SDK Documentation](https://docs.cosmos.network/)
- **Mobile Guides**: Platform-specific documentation in `meowtopia/frontend/mobile/` directories

## 🆘 Troubleshooting

### Common Issues

#### Service Management
```bash
# Check service status
make status

# View logs
make logs

# Restart services
make restart

# Stop all services
make down
```

#### Port Already in Use
```bash
# Find process using port
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

#### Docker Issues
```bash
# Clean Docker cache
docker system prune -a

# Reset Docker containers
make down
docker-compose down -v

# Rebuild without cache
docker-compose build --no-cache
```

#### Build Issues
```bash
# Platform-specific builds
make linux        # For Linux
make windows      # For Windows
make mac          # For macOS
make build-all    # For all platforms
```

#### Database Issues
```bash
# Reset database
make down
docker volume rm chain-rice_meowtopia-db-data
make up
```

### Platform-Specific Issues

#### Windows
- Ensure WSL2 is enabled in Docker Desktop
- Run commands in WSL2 terminal or PowerShell
- Check Windows Defender firewall settings

#### macOS
- For Apple Silicon Macs, ensure Docker Desktop supports ARM64
- Check Docker Desktop resource allocation
- Ensure sufficient disk space

#### Linux
- Ensure Docker daemon is running
- Check user permissions for Docker
- Verify Docker Compose version compatibility

### Getting Help
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Documentation**: See `docs/DEVELOPMENT.md` for detailed setup

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Cosmos SDK** - Blockchain framework
- **Ignite CLI** - Development tools
- **Tendermint** - Consensus engine
- **React** - UI framework
- **Vite** - Build tool

---

**ChainRice** - Building the future of decentralized applications 🌟 