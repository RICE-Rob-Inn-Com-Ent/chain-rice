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

- **Docker & Docker Compose** - For containerized services
- **Node.js 18+** - For development
- **Android Studio** - For Android development (optional)
- **Xcode** - For iOS development (optional, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd chainrice
   ```

2. **Make scripts executable**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Start the entire ecosystem**
   ```bash
   ./scripts/start-all.sh
   ```

## 📱 Platform-Specific Startup

### 🌐 Web Platform (Cafe Interface)
```bash
./scripts/start-web.sh
```
- **URL**: http://localhost:3000
- **API**: http://localhost:8080
- **Features**: Cafe management, order processing, blockchain integration

### 🎮 Mobile Platform (Games)
```bash
./scripts/start-mobile.sh
```
- **API**: http://localhost:8081
- **Android**: Open `mobile/android/` in Android Studio
- **iOS**: Open `mobile/ios/ChainRiceMobile.xcodeproj` in Xcode

### ⛓️ Blockchain Only
```bash
docker-compose up -d blockchain postgres redis
```
- **RPC**: http://localhost:26657
- **REST API**: http://localhost:1317
- **WebSocket**: ws://localhost:26657/websocket

## 🧪 Testing

### Run All Tests
```bash
./scripts/run-tests.sh
```

### Individual Test Suites
```bash
# Backend tests
cd backend && npm test

# Mobile backend tests
cd mobile-backend && npm test

# Web frontend tests
cd web-frontend && npm test

# Blockchain tests
make test
```

## 🏗️ Development

### Web Frontend Development
```bash
cd web-frontend
npm install
npm run dev
```

**Key Technologies:**
- **Vite** - Fast build tool
- **React 18** - UI framework
- **Tailwind CSS** - Styling
- **CosmosJS** - Blockchain integration
- **React Query** - Data fetching
- **Zustand** - State management

### Mobile Development

#### Android (Kotlin)
```bash
cd mobile/android
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
cd mobile/ios
# Open ChainRiceMobile.xcodeproj in Xcode
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
cd backend
npm install
npm run dev
```

**Key Technologies:**
- **Node.js** - Runtime
- **Express** - Web framework
- **PostgreSQL** - Database
- **Redis** - Caching
- **JWT** - Authentication
- **Socket.io** - Real-time communication

## 🔧 Configuration

### Environment Variables

#### Web Frontend (.env)
```env
VITE_API_URL=http://localhost:8080
VITE_BLOCKCHAIN_RPC_URL=http://localhost:26657
VITE_CHAIN_ID=chainrice-local
VITE_APP_NAME=ChainRice Cafe
VITE_APP_VERSION=1.0.0
```

#### Backend (.env)
```env
PORT=8080
DATABASE_URL=postgresql://postgres:password@localhost:5432/chainrice
REDIS_URL=redis://localhost:6379
BLOCKCHAIN_RPC_URL=http://localhost:26657
JWT_SECRET=your-super-secret-jwt-key
NODE_ENV=development
```

#### Mobile Backend (.env)
```env
PORT=8081
DATABASE_URL=postgresql://postgres:password@localhost:5432/chainrice_mobile
REDIS_URL=redis://localhost:6379
BLOCKCHAIN_RPC_URL=http://localhost:26657
JWT_SECRET=your-super-secret-jwt-key-mobile
NODE_ENV=development
```

## 🌐 API Endpoints

### Web Backend (Port 8080)
- `GET /health` - Health check
- `GET /api-docs` - API documentation
- `POST /api/auth/login` - User authentication
- `GET /api/cafe/menu` - Cafe menu
- `POST /api/orders` - Create order
- `GET /api/blockchain/status` - Blockchain status

### Mobile Backend (Port 8081)
- `GET /health` - Health check
- `POST /api/auth/login` - User authentication
- `GET /api/games` - Available games
- `POST /api/games/start` - Start game session
- `GET /api/leaderboard` - Game leaderboard
- `POST /api/blockchain/transaction` - Submit transaction

### Blockchain (Port 26657)
- `GET /status` - Node status
- `GET /block` - Get block
- `POST /broadcast_tx_async` - Broadcast transaction
- `GET /abci_query` - Query state

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

- **API Documentation**: http://localhost:8080/api-docs
- **Blockchain Docs**: [Cosmos SDK Documentation](https://docs.cosmos.network/)
- **Mobile Guides**: Platform-specific documentation in `mobile/` directories

## 🆘 Support

### Common Issues

#### Port Already in Use
```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>
```

#### Docker Issues
```bash
# Reset Docker containers
docker-compose down -v
docker system prune -a
```

#### Database Issues
```bash
# Reset database
docker-compose down -v
docker volume rm chainrice_postgres-data
```

### Getting Help
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Documentation**: Project Wiki

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