# ChainRice Frontend

A modern React + Vite frontend for the ChainRice blockchain development environment.

## Features

- 🌾 **Token Management**: View balances, transfer CRICE and MWT tokens
- ⛓️ **Blockchain Integration**: Connect to ChainRice Cosmos SDK blockchain
- 🎨 **Modern UI**: Built with React, Material-UI, and Tailwind CSS
- 🔄 **Real-time Updates**: Live blockchain data and transaction status
- 📱 **Responsive Design**: Works on desktop and mobile devices

## Quick Start

1. **Start the development environment**:
   ```bash
   # From rice-dev root directory
   nix develop
   rice-dev-start
   ```

2. **Open the ChainRice UI**:
   - Main UI: http://localhost:3000
   - Development Dashboard: http://localhost:8080/dev-dashboard.html

## Available Pages

- **Dashboard**: Overview of blockchain status and token balances
- **Token Balances**: View CRICE and MWT token balances
- **Transfer Tokens**: Send tokens between addresses
- **Deploy Contract**: Deploy smart contracts to the blockchain
- **Block Explorer**: Explore blockchain transactions and blocks
- **Settings**: Configure wallet and network settings

## Development

### Prerequisites

- Node.js 20+
- npm, yarn, or pnpm
- Nix (for the complete development environment)

### Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── Layout.tsx      # Main layout with navigation
│   └── ErrorBoundary.tsx
├── pages/              # Page components
│   ├── Dashboard.tsx   # Main dashboard
│   ├── TokenBalances.tsx
│   ├── TokenTransfer.tsx
│   ├── ContractDeploy.tsx
│   ├── BlockExplorer.tsx
│   └── Settings.tsx
├── App.tsx             # Main app component
├── main.tsx           # Entry point
└── index.css          # Global styles
```

## Integration

The frontend integrates with:

- **Blockchain RPC**: http://localhost:26657
- **REST API**: http://localhost:1317
- **Bot Core API**: http://localhost:8000
- **FastAPI Connection**: http://localhost:8001

## Token Support

- **CRICE**: Main blockchain token (urice)
- **MWT**: Subtoken ready for deployment

## Technologies

- **React 18**: UI framework
- **Vite**: Build tool and dev server
- **TypeScript**: Type safety
- **Material-UI**: Component library
- **Tailwind CSS**: Utility-first CSS
- **React Query**: Data fetching and caching
- **React Hook Form**: Form handling
- **CosmJS**: Cosmos SDK integration
- **Ethers.js**: Ethereum compatibility

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
