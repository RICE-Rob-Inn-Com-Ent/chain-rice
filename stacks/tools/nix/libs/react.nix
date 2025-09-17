{ pkgs }:

{
  packages = with pkgs; [
    # Node.js ecosystem
    nodejs_22
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    
    # TypeScript and development tools
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.prettier
    
    # Vite and React development
    nodePackages.vite
    nodePackages.create-vite
    
    # Build tools
    nodePackages.concurrently
    nodePackages.cross-env
    
    # Testing tools
    nodePackages.jest
    nodePackages.vitest
    
    # Additional React development tools
    nodePackages.react-devtools
    
    # CSS and styling tools
    nodePackages.postcss
    nodePackages.postcss-cli
    nodePackages.autoprefixer
    
    # Linting and formatting
    nodePackages.stylelint
    
    # Package management
    nodePackages.npm-check-updates
    
    # Development server tools
    nodePackages.serve
    nodePackages.http-server
  ];
  
  envVars = {
    # Node.js configuration
    NODE_ENV = "development";
    NODE_OPTIONS = "--max_old_space_size=4096";
    
    # npm configuration
    NPM_CONFIG_FUND = "false";
    NPM_CONFIG_AUDIT = "false";
    
    # React development
    BROWSER = "none";  # Don't auto-open browser
    FAST_REFRESH = "true";
    
    # Vite configuration
    VITE_HOST = "0.0.0.0";
    VITE_PORT = "5173";
    
    # ChainRice specific frontend env vars
    VITE_API_URL = "http://localhost:8003";
    VITE_BLOCKCHAIN_URL = "http://localhost:1317";
    VITE_APP_NAME = "ChainRice Tax System";
    VITE_APP_VERSION = "1.0.0";
    
    # Development features
    VITE_ENABLE_DEVTOOLS = "true";
    VITE_ENABLE_HOT_RELOAD = "true";
  };
  
  shellHook = ''
    echo "⚛️  Node.js ${pkgs.nodejs.version} with React development tools"
    echo "   • TypeScript ${pkgs.nodePackages.typescript.version}"
    echo "   • Vite for fast development"
    echo "   • ESLint & Prettier for code quality"
    
    # Ensure npm global bin is in PATH
    export PATH="$HOME/.npm-global/bin:$PATH"
    
    # Set npm global directory
    mkdir -p $HOME/.npm-global
    npm config set prefix $HOME/.npm-global
    
    # Install or update global tools if needed
    if [ ! -d "node_modules" ] && [ -f "package.json" ]; then
      echo "📦 Installing Node.js dependencies..."
      npm install
    fi
    
    # Check for updates
    if command -v ncu &> /dev/null; then
      echo "🔍 Checking for package updates..."
      ncu --format group
    fi
  '';
}
