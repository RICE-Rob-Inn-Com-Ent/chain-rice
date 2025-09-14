# Meowtopia - Virtual Cat Universe

Meowtopia is a blockchain-based virtual cat universe where players can collect, trade, and interact with digital cats using NFTs and cryptocurrency tokens. Built on the Chain-Rice blockchain infrastructure.

## Project Structure

```
meowtopia/
├── contracts/          # Smart contracts for blockchain functionality
├── backend/            # Python backend with FastAPI and database
├── frontend/
│   ├── mobile/         # Mobile game for Android and iOS
│   │   ├── android/    # Android native app
│   │   └── ios/        # iOS native app
│   └── web/           # Web application for cat management
```

## Features

### Blockchain Integration (Smart Contracts)
- **MWT Token**: Native currency for the Meowtopia ecosystem
- **Cat NFTs**: Unique digital cats with rarity and attributes
- **DAO Governance**: Community-driven decision making
- **Group Management**: Cat breeding groups and clubs
- **IBC Support**: Inter-blockchain communication for cross-chain trading

### Mobile Game
- **Cat Collection**: Discover and collect unique cats
- **Breeding System**: Create new cats with combined traits
- **Virtual World**: Interactive environment for cats
- **Mini-games**: Earn rewards through gameplay
- **Social Features**: Trade and interact with other players

### Web Application
- **Cat Portfolio**: Manage your cat collection
- **Trading Platform**: Buy, sell, and trade cats
- **Breeding Calculator**: Plan optimal breeding strategies
- **Community Hub**: Connect with other cat enthusiasts
- **Analytics Dashboard**: Track your collection's value

### Backend Services
- **User Authentication**: Secure login and registration
- **Database Management**: Store user data and game state
- **API Gateway**: RESTful APIs for all services
- **Real-time Updates**: WebSocket connections for live data

## Tech Stack

- **Blockchain**: Cosmos SDK, Chain-Rice
- **Smart Contracts**: CosmWasm (Rust)
- **Backend**: Python FastAPI, PostgreSQL
- **Mobile**: React Native (cross-platform)
- **Web**: React, TypeScript, Tailwind CSS
- **Authentication**: JWT tokens, OAuth2

## Getting Started

### Prerequisites
- Node.js 18+ and npm
- Python 3.9+
- Rust and cargo (for smart contracts)
- Chain-Rice blockchain running locally

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd meowtopia
```

2. **Start Chain-Rice blockchain**
```bash
cd ../
ignite chain serve
```

3. **Deploy smart contracts**
```bash
cd meowtopia/contracts
make deploy
```

4. **Start backend services**
```bash
cd ../backend
pip install -r requirements.txt
python -m app.main
```

5. **Launch web application**
```bash
cd ../frontend/web
npm install
npm run dev
```

6. **Build mobile apps**
```bash
cd ../mobile
npm install
npm run android  # For Android
npm run ios      # For iOS
```

## Development Roadmap

### Phase 1: Foundation (Current)
- [x] Project structure setup
- [ ] Basic smart contracts
- [ ] Backend authentication system
- [ ] Simple mobile game prototype
- [ ] Web application MVP

### Phase 2: Core Features
- [ ] Advanced cat breeding mechanics
- [ ] Trading marketplace
- [ ] DAO governance implementation
- [ ] Enhanced mobile gameplay
- [ ] Social features

### Phase 3: Advanced Features
- [ ] Cross-chain trading
- [ ] Advanced analytics
- [ ] VR/AR integration
- [ ] Tournament system
- [ ] Community events

## Contributing

We welcome contributions! Please read our contributing guidelines and join our community Discord.

## License

This project is licensed under the MIT License - see the LICENSE file for details.