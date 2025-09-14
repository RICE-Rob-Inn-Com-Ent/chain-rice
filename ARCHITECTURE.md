# Architektura ChainRice

## 🌟 Przegląd Systemu

**ChainRice** to zaawansowany ekosystem blockchain zbudowany na Cosmos SDK, integrujący platformę webową do zarządzania kawiarnią z platformą mobilną do gier, wszystko połączone z ujednoliconym backendem blockchain.

## 🏗️ Architektura Wysokiego Poziomu

```
┌─────────────────────────────────────────────────────────────────┐
│                        ChainRice Ecosystem                     │
├─────────────────────────────────────────────────────────────────┤
│  Frontend Layer (Warstwa Frontend)                            │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │   Web Platform  │    │  Mobile Platform│                   │
│  │   (Cafe UI)     │    │   (Gry)         │                   │
│  │                 │    │                 │                   │
│  │ • Vite + React  │    │ • Android/Kotlin│                   │
│  │ • Tailwind CSS  │    │ • iOS/Swift     │                   │
│  │ • TypeScript    │    │ • Jetpack Compose│                  │
│  │ • CosmosJS      │    │ • Flutter       │                   │
│  └─────────────────┘    └─────────────────┘                   │
├─────────────────────────────────────────────────────────────────┤
│  Backend Services Layer (Warstwa Usług Backend)               │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │   Web Backend   │    │  Mobile Backend │    │   Game      │ │
│  │   (FastAPI)     │    │   (Node.js)     │    │   Engine    │ │
│  │                 │    │                 │    │   (Rust)    │ │
│  │ • REST API      │    │ • GraphQL API   │    │             │ │
│  │ • WebSocket     │    │ • WebSocket     │    │ • Game Logic│ │
│  │ • JWT Auth      │    │ • JWT Auth      │    │ • Physics   │ │
│  └─────────────────┘    └─────────────────┘    └─────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Blockchain Layer (Warstwa Blockchain)                        │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Cosmos SDK App                          ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ ││
│  │  │   Tendermint│  │  Cosmos SDK │  │   Custom Modules    │ ││
│  │  │   Core      │  │   Modules   │  │                     │ ││
│  │  │             │  │             │  │ • Cafe Management   │ ││
│  │  │ • Consensus │  │ • Bank      │  │ • Game Rewards      │ ││
│  │  │ • P2P       │  │ • Staking   │  │ • NFT Marketplace  │ ││
│  │  │ • RPC       │  │ • Gov       │  │ • DeFi Protocols   │ ││
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────┤
│  Data Layer (Warstwa Danych)                                  │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │   PostgreSQL    │    │     Redis       │    │   IPFS      │ │
│  │   (Primary DB)  │    │   (Cache/Queue) │    │ (File Store)│ │
│  │                 │    │                 │    │             │ │
│  │ • User Data     │    │ • Session Store │    │ • Game Assets│ │
│  │ • Orders        │    │ • Rate Limiting │    │ • NFT Images│ │
│  │ • Game Scores   │    │ • Real-time Data│    │ • Documents │ │
│  └─────────────────┘    └─────────────────┘    └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Komponenty Systemu

### 🌐 Frontend Layer

#### Web Platform (Platforma Web)
- **Lokalizacja**: `meowtopia/frontend/web`
- **Technologie**: Vite + React 19 + Tailwind CSS + TypeScript
- **Port**: 3000
- **Funkcje**:
  - Zarządzanie kawiarnią (menu, zamówienia, płatności)
  - Dashboard administratora
  - Integracja z blockchain (portfele, transakcje)
  - Real-time updates (WebSocket)

#### Mobile Platform (Platforma Mobilna)
- **Lokalizacja**: `meowtopia/frontend/mobile`
- **Android**: Kotlin + Jetpack Compose
- **iOS**: Swift + SwiftUI
- **Funkcje**:
  - Gry mobilne z integracją blockchain
  - System nagród i osiągnięć
  - Multiplayer gaming
  - Push notifications

### 🚀 Backend Services Layer

#### Web Backend (FastAPI)
- **Lokalizacja**: `meowtopia/backend`
- **Port**: 8000
- **Technologie**: Python 3.12 + FastAPI + PostgreSQL
- **Funkcje**:
  - REST API dla platformy web
  - Uwierzytelnianie JWT
  - Zarządzanie użytkownikami i rolami
  - Przetwarzanie zamówień kawiarni
  - Integracja z blockchain

#### Mobile Backend (Node.js)
- **Port**: 8001
- **Technologie**: Node.js + Express + GraphQL
- **Funkcje**:
  - GraphQL API dla aplikacji mobilnych
  - Real-time gaming features
  - Push notifications
  - Game state management
  - Leaderboards i achievements

#### Game Engine (Rust)
- **Port**: 8002
- **Technologie**: Rust + Tokio + WebSocket
- **Funkcje**:
  - Game logic i physics
  - Real-time multiplayer
  - AI opponents
  - Game state synchronization
  - Performance optimization

### ⛓️ Blockchain Layer

#### Cosmos SDK Application
- **Lokalizacja**: `apps/chain-rice/`
- **Porty**: RPC (26657), REST (1317), P2P (26656)
- **Technologie**: Go + Cosmos SDK + Tendermint
- **Funkcje**:
  - Custom blockchain modules
  - Smart contracts
  - DeFi protocols
  - NFT marketplace
  - Governance

#### Custom Modules
- **Cafe Management Module**: Zarządzanie kawiarnią na blockchain
- **Game Rewards Module**: System nagród za gry
- **NFT Marketplace Module**: Handel NFT
- **DeFi Protocols Module**: Protokoły DeFi
- **Tax Control Module**: 🇵🇱 Kompleksowy system kontroli podatkowej dla Polski
  - Moduł podatników (NIP, REGON, dane firmy)
  - Moduł dokumentów podatkowych (VAT, faktury, paragony)
  - Moduł JPK (generowanie JPK_VAT, JPK_V7M, JPK_FA)
  - Moduł zgodności podatkowej (monitoring, audyty)
  - Integracja z KSeF, e-Urządem, NBP API

### 🗄️ Data Layer

#### PostgreSQL (Primary Database)
- **Port**: 5432
- **Funkcje**:
  - User management
  - Order processing
  - Game scores i leaderboards
  - Transaction history
  - Analytics data
  - Tax records and compliance data
  - JPK generation and storage
  - Taxpayer information

#### Redis (Cache & Queue)
- **Port**: 6379
- **Funkcje**:
  - Session storage
  - Rate limiting
  - Real-time data caching
  - Message queue
  - Pub/Sub messaging
  - Tax calculation cache
  - JPK generation queue
  - Compliance monitoring cache

#### IPFS (File Storage)
- **Funkcje**:
  - Game assets storage
  - NFT images i metadata
  - Document storage
  - Media files
  - Decentralized file system
  - Tax documents storage
  - JPK files storage
  - Audit trail documents

## 🔄 Przepływ Danych

### 1. Web Platform Flow
```
React UI → FastAPI → PostgreSQL
    ↓
WebSocket → Real-time Updates
    ↓
CosmosJS → Blockchain API → Custom Modules
```

### 2. Mobile Platform Flow
```
Mobile App → GraphQL API → Node.js Backend
    ↓
WebSocket → Real-time Gaming
    ↓
Rust Game Engine → Game State
    ↓
Blockchain Integration → Rewards & NFTs
```

### 3. Blockchain Integration Flow
```
Frontend → API Gateway → Backend Services
    ↓
Blockchain Client → Cosmos SDK
    ↓
Custom Modules → State Changes
    ↓
Event Emission → Real-time Updates
```

### 4. Tax System Flow
```
Tax Portal → Tax API → Blockchain Tax Module
    ↓
JPK Generation → KSeF Integration
    ↓
Compliance Monitoring → Audit System
    ↓
Real-time Updates → Tax Dashboard
```

## 🌐 Porty i Serwisy

### Development Environment
- **Frontend Web**: 3000 (Vite dev server)
- **Backend API**: 8000 (FastAPI)
- **Mobile Backend**: 8001 (Node.js)
- **Game Engine**: 8002 (Rust)
- **Tax API**: 8003 (FastAPI Tax Service)
- **JPK Service**: 8004 (Node.js JPK Generator)
- **Audit Service**: 8005 (Python Audit Service)
- **PostgreSQL**: 5432
- **Redis**: 6379
- **Blockchain RPC**: 26657
- **Blockchain REST**: 1317
- **Blockchain P2P**: 26656

### Production Environment
- **Load Balancer**: 80, 443
- **API Gateway**: 8080
- **Backend Services**: 8000-8002
- **Tax Services**: 8003-8005
- **Database**: 5432
- **Cache**: 6379
- **Blockchain**: 26657, 1317, 26656

## 🐳 Docker Orchestration

### Development Profiles
```yaml
# docker-compose.yml
services:
  # Web platform
  web-frontend:
    build: ./meowtopia/frontend/web
    ports: ["3000:3000"]
    profiles: ["web"]
  
  # Backend services
  web-backend:
    build: ./meowtopia/backend
    ports: ["8000:8000"]
    profiles: ["api"]
  
  mobile-backend:
    build: ./meowtopia/backend-mobile
    ports: ["8001:8001"]
    profiles: ["mobile"]
  
  # Blockchain
  blockchain:
    build: ./apps/chain-rice
    ports: ["26657:26657", "1317:1317"]
    profiles: ["blockchain"]
  
  # Data layer
  postgres:
    image: postgres:15
    ports: ["5432:5432"]
    profiles: ["data"]
  
  redis:
    image: redis:7
    ports: ["6379:6379"]
    profiles: ["data"]
```

## 🔧 Konfiguracja Środowiska

### Environment Variables
```bash
# Build Configuration
BUILD_ENV=development
BUILD_NUMBER=1
BUILD_VERSION=0.1.0

# Database Configuration
POSTGRES_DB=meowtopia
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=postgres

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# Blockchain Configuration
CHAIN_ID=chainrice-local
RPC_URL=http://localhost:26657
REST_URL=http://localhost:1317

# API Configuration
API_PORT=8000
MOBILE_API_PORT=8001
GAME_ENGINE_PORT=8002
```

### Service Configuration
```bash
# Web Frontend
VITE_API_URL=http://localhost:8000
VITE_BLOCKCHAIN_RPC_URL=http://localhost:26657
VITE_CHAIN_ID=chainrice-local

# Mobile Backend
GRAPHQL_ENDPOINT=http://localhost:8001/graphql
WEBSOCKET_URL=ws://localhost:8001/ws

# Game Engine
GAME_ENGINE_URL=http://localhost:8002
WEBSOCKET_GAME_URL=ws://localhost:8002/ws
```

## 🚀 Deployment Strategy

### Development
```bash
# Start all services
make dev

# Start specific profiles
make up --profile web
make up --profile api
make up --profile blockchain
```

### Production
```bash
# Build production images
make build-prod

# Deploy to production
make deploy-prod

# Scale services
make scale-backend=3
make scale-frontend=2
```

## 📊 Monitoring i Observability

### Health Checks
- **Backend Services**: `/health` endpoint
- **Database**: Connection pool monitoring
- **Redis**: Memory and connection monitoring
- **Blockchain**: Node status and sync status

### Logging
- **Structured Logging**: JSON format across all services
- **Log Levels**: DEBUG, INFO, WARN, ERROR
- **Centralized Logging**: ELK Stack or similar
- **Request Tracing**: Distributed tracing with Jaeger

### Metrics
- **Application Metrics**: Prometheus + Grafana
- **Infrastructure Metrics**: Node Exporter
- **Custom Metrics**: Business logic metrics
- **Alerting**: AlertManager for critical issues

## 🔐 Security Architecture

### Authentication & Authorization
- **JWT Tokens**: Stateless authentication
- **Role-Based Access Control**: Granular permissions
- **OAuth2 Integration**: Social login support
- **Multi-Factor Authentication**: Enhanced security

### Network Security
- **TLS/SSL**: End-to-end encryption
- **CORS Configuration**: Cross-origin resource sharing
- **Rate Limiting**: DDoS protection
- **Firewall Rules**: Network segmentation

### Data Security
- **Encryption at Rest**: Database encryption
- **Encryption in Transit**: TLS for all communications
- **Key Management**: Secure key storage
- **Data Anonymization**: Privacy protection

## 🎯 Performance Optimization

### Caching Strategy
- **Redis Caching**: Application-level caching
- **CDN**: Static asset delivery
- **Database Query Caching**: Query result caching
- **API Response Caching**: Response caching

### Database Optimization
- **Connection Pooling**: Efficient database connections
- **Query Optimization**: Indexed queries
- **Read Replicas**: Read scaling
- **Partitioning**: Data partitioning

### Blockchain Optimization
- **Transaction Batching**: Batch multiple transactions
- **Gas Optimization**: Efficient smart contracts
- **State Pruning**: Reduce blockchain size
- **Light Client Support**: Efficient client connections

## 🔄 CI/CD Pipeline

### Build Pipeline
1. **Code Commit** → GitHub
2. **Automated Testing** → Unit, Integration, E2E tests
3. **Security Scanning** → SAST, DAST, dependency scanning
4. **Build Images** → Docker images for all services
5. **Deploy to Staging** → Automated staging deployment
6. **Production Deployment** → Manual approval required

### Quality Gates
- **Code Coverage**: Minimum 80% coverage
- **Security Scan**: No critical vulnerabilities
- **Performance Tests**: Response time requirements
- **Integration Tests**: All services working together

## 📚 Dokumentacja Techniczna

### API Documentation
- **Swagger UI**: http://localhost:8000/docs
- **GraphQL Playground**: http://localhost:8001/graphql
- **OpenAPI Specs**: Auto-generated from code
- **Postman Collections**: Pre-configured API tests

### Architecture Decision Records (ADRs)
- **ADR-001**: Technology Stack Selection
- **ADR-002**: Database Design Decisions
- **ADR-003**: Blockchain Integration Strategy
- **ADR-004**: Security Implementation

### Development Guidelines
- **Code Style**: ESLint + Prettier configuration
- **Testing Strategy**: Unit, Integration, E2E testing
- **Documentation**: JSDoc + README standards
- **Git Workflow**: Feature branches + PR reviews

## 🎯 Wnioski

Architektura ChainRice została zaprojektowana jako **nowoczesny, skalowalny ekosystem** łączący tradycyjne aplikacje webowe z technologią blockchain:

- **Modular Design**: Każdy komponent może być rozwijany niezależnie
- **Microservices Architecture**: Łatwe skalowanie i maintenance
- **Blockchain Integration**: Seamless integration z Cosmos SDK
- **Multi-Platform Support**: Web, mobile, i blockchain
- **Production Ready**: Monitoring, logging, security, i deployment

Ta architektura zapewnia solidne fundamenty dla rozwoju zaawansowanych aplikacji blockchain z doskonałym doświadczeniem użytkownika.

---

*Dokumentacja architektury została stworzona w języku polskim zgodnie z preferencjami projektu.*
