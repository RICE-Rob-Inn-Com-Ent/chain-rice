{ pkgs }:

{
  packages = with pkgs; [
    # Node.js ecosystem (same base as React but with Next.js focus)
    nodejs_22
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    
    # TypeScript and development tools
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.prettier
    
    # Next.js specific tools
    nodePackages.create-next-app
    
    # Build and development tools
    nodePackages.concurrently
    nodePackages.cross-env
    nodePackages.rimraf
    
    # Testing tools
    nodePackages.jest
    nodePackages.vitest
    
    # CSS and styling tools
    nodePackages.postcss
    nodePackages.postcss-cli
    nodePackages.autoprefixer
    nodePackages.tailwindcss
    
    # Linting and formatting
    nodePackages.stylelint
    nodePackages.eslint-config-next
    
    # Package management and updates
    nodePackages.npm-check-updates
    
    # Development server tools
    nodePackages.serve
    nodePackages.http-server
    
    # Image optimization tools
    imagemagick
    
    # Performance and analysis
    nodePackages.webpack-bundle-analyzer
    
    # API development
    nodePackages.swagger-ui-dist
    
    # Database tools (for Next.js API routes)
    sqlite
    
    # Additional development utilities
    nodePackages.nodemon
    nodePackages.dotenv-cli
  ];
  
  envVars = {
    # Node.js configuration
    NODE_ENV = "development";
    NODE_OPTIONS = "--max_old_space_size=4096";
    
    # npm configuration
    NPM_CONFIG_FUND = "false";
    NPM_CONFIG_AUDIT = "false";
    
    # Next.js specific configuration
    NEXT_TELEMETRY_DISABLED = "1";  # Disable telemetry
    NEXTJS_PORT = "3000";
    NEXTJS_HOST = "0.0.0.0";
    
    # Development features
    FAST_REFRESH = "true";
    ANALYZE_BUNDLE = "false";
    
    # ChainRice specific Next.js env vars
    NEXT_PUBLIC_API_URL = "http://localhost:8003";
    NEXT_PUBLIC_BLOCKCHAIN_URL = "http://localhost:1317";
    NEXT_PUBLIC_APP_NAME = "ChainRice Tax System";
    NEXT_PUBLIC_APP_VERSION = "1.0.0";
    
    # Database (for Next.js API routes)
    DATABASE_URL = "sqlite:///$PWD/backend/go/accounting.db";
    
    # Authentication (if using NextAuth.js)
    NEXTAUTH_URL = "http://localhost:3000";
    NEXTAUTH_SECRET = "development-secret-key";
    
    # Image optimization
    NEXT_PUBLIC_IMAGE_DOMAINS = "localhost";
    
    # Performance monitoring
    NEXT_PUBLIC_ENABLE_ANALYTICS = "false";
    
    # Build optimization
    NEXT_BUILD_WORKERS = "4";
    
    # Development debugging
    DEBUG = "next:*";
    VERBOSE = "true";
  };
  
  shellHook = ''
    echo "⚡ Next.js development environment with Node.js ${pkgs.nodejs.version}"
    echo "   • TypeScript ${pkgs.nodePackages.typescript.version}"
    echo "   • Tailwind CSS for styling"
    echo "   • ESLint & Prettier for code quality"
    echo "   • Image optimization tools"
    echo "   • API route development ready"
    
    # Ensure npm global bin is in PATH
    export PATH="$HOME/.npm-global/bin:$PATH"
    
    # Set npm global directory
    mkdir -p $HOME/.npm-global
    npm config set prefix $HOME/.npm-global
    
    # Set up Next.js project if it exists
    if [ -d "frontend/next" ]; then
      echo "📁 Next.js project found in frontend/next"
      cd frontend/next
      
      # Install dependencies if package.json exists but node_modules doesn't
      if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        echo "📦 Installing Next.js dependencies..."
        npm install
      fi
      
      # Check for updates
      if command -v ncu &> /dev/null; then
        echo "🔍 Checking for package updates..."
        ncu --format group
      fi
      
      cd - > /dev/null
    fi
    
    # Install Next.js globally if not present
    if ! command -v next &> /dev/null; then
      echo "⚡ Installing Next.js globally..."
      npm install -g next
    fi
    
    # Aliases for common Next.js operations
    alias ndev='npm run dev'
    alias nbuild='npm run build'
    alias nstart='npm run start'
    alias nlint='npm run lint'
    alias ntest='npm run test'
    alias nanalyze='ANALYZE=true npm run build'
    
    # Next.js specific aliases
    alias next-dev='next dev -p $NEXTJS_PORT'
    alias next-build='next build'
    alias next-start='next start -p $NEXTJS_PORT'
    alias next-lint='next lint'
    alias next-telemetry='next telemetry'
    
    # ChainRice Next.js aliases
    alias chainrice-next='cd frontend/next'
    alias next-api-test='curl http://localhost:3000/api/health'
    
    # Development utilities
    alias serve-build='npx serve out'  # For static export
    alias bundle-analyzer='npx webpack-bundle-analyzer .next/static/chunks/*.js'
    
    # Database utilities (for API routes)
    alias db-studio='npx prisma studio'  # If using Prisma
    alias db-migrate='npx prisma migrate dev'  # If using Prisma
    
    echo ""
    echo "🚀 Next.js ready on port $NEXTJS_PORT"
    echo "   • Frontend: http://localhost:$NEXTJS_PORT"
    echo "   • API routes: http://localhost:$NEXTJS_PORT/api/*"
  '';
}
