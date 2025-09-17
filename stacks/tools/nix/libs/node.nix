{ pkgs }:

{
  packages = with pkgs; [
    # Node runtimes and managers
    nodejs_22
    corepack  # enables pnpm/yarn via corepack enable
    pnpm
    yarn
    nodePackages.npm

    # TypeScript and language tools
    nodePackages.typescript
    nodePackages.typescript-language-server

    # Framework CLIs
    nodePackages.create-react-app
    nodePackages.next
    nodePackages.vite
    nodePackages.gatsby-cli
    nodePackages.nuxi
    # Angular CLI packaged separately
    angular-cli
    # Vue CLI (deprecated), recommend vite; include @vue/cli-service-global alternative not in nix; keep nuxi for Nuxt

    # Linters/formatters
    nodePackages.eslint
    nodePackages.prettier
    nodePackages.eslint_d
    nodePackages.stylelint
    nodePackages.markdownlint-cli

    # Testing and tooling
    nodePackages.jest
    nodePackages.vitest
    nodePackages.playwright
    nodePackages.cypress
    nodePackages.storybook

    # Build tools
    nodePackages.rollup
    nodePackages.webpack
    nodePackages.parcel-bundler
    nodePackages.esbuild
    nodePackages.swc

    # Dev servers and utilities
    nodePackages.http-server
    nodePackages.nodemon
    nodePackages.cross-env

    # API/GraphQL
    nodePackages.graphql
    nodePackages.prisma
    nodePackages.apollo

    # Misc utilities
    git
    jq
    curl
    wget
  ];

  envVars = {
    # Prefer pnpm; enable corepack to manage yarn/pnpm versions pinned by project
    COREPACK_ENABLE_AUTO_PIN = "1";
    PLAYWRIGHT_BROWSERS_PATH = "0"; # install browsers to node_modules for reproducibility
  };

  shellHook = ''
    echo "🟩 Node Frontend stack: React/TS/Next/Angular/Vue + ESLint/Prettier/Jest/Vitest/Playwright"

    # Enable corepack shims
    if command -v corepack >/dev/null 2>&1; then
      corepack enable >/dev/null 2>&1 || true
    fi

    # Auto-install dependencies if package.json present and node_modules missing
    if [ -f package.json ] && [ ! -d node_modules ]; then
      echo "📦 Installing Node dependencies"
      if command -v pnpm >/dev/null 2>&1; then pnpm install || true
      elif command -v yarn >/dev/null 2>&1; then yarn install || true
      else npm ci || npm install || true
      fi
    fi

    # Common aliases
    alias nr='npm run'
    alias pr='pnpm run'
    alias yr='yarn run'
    alias ts='tsc --noEmit'
    alias lint='eslint .'
    alias fmt='prettier --write .'
    alias test='jest || vitest'
    alias dev='vite dev || next dev || ng serve || vue-tsc --noEmit && vite'

    echo "💡 Create apps: npx create-next-app@latest, pnpm create vite, ng new"
  '';
}
