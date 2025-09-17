{ pkgs }:

{
  packages = with pkgs; [
    # Compilers and EVM toolchains
    solc
    foundry-bin         # forge, cast, anvil
    vyper

    # Node.js toolchain for Hardhat/Truffle
    nodejs_22
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    nodePackages.hardhat
    nodePackages.truffle
    nodePackages.ganache
    nodePackages.solhint
    nodePackages.prettier
    nodePackages.typescript

    # Python toolchain for security/testing frameworks
    python3
    python3Packages.slither-analyzer
    python3Packages.mythril
    python3Packages.manticore
    echidna
    python3Packages.eth-brownie
    python3Packages.web3
    # Ape (ETH Ape) if available in nixpkgs; otherwise user installs via pip
    # python3Packages.eth-ape

    # Nodes and SDKs
    geth

    # Go-ethereum abigen (provided by geth in nixpkgs; include for clarity if packaged separately)
    # abigen

    # Utilities
    git
    curl
    jq
    ripgrep
    fd
    gnumake
    openssl
  ];
  
  envVars = {
    # EVM defaults
    ETH_RPC_URL = "http://localhost:8545";
    HARDHAT_NETWORK = "localhost";
    ANVIL_PORT = "8545";
    ANVIL_HOST = "127.0.0.1";

    # Explorer/API keys (placeholders)
    ALCHEMY_API_KEY = "";
    INFURA_API_KEY = "";
    ETHERSCAN_API_KEY = "";

    # Foundry settings
    FOUNDRY_DIR = "$HOME/.foundry";

    # Project root hint
    CHAINRICE_SOLIDITY_ROOT = "$PWD/stacks/langs/solidity";
  };
  
  shellHook = ''
    echo "🟩 Solidity toolchain: solc $(solc --version | sed -n '1p')"
    echo "   • Foundry (forge/cast/anvil)"
    echo "   • Hardhat/Truffle/Ganache"
    echo "   • Slither/Mythril/Echidna/Manticore"
    echo "   • Vyper, Brownie (Python)"

    # Ensure local node_modules bin is in PATH
    if [ -d "node_modules/.bin" ]; then
      export PATH="node_modules/.bin:$PATH"
    fi

    # Print versions (non-fatal)
    forge --version 2>/dev/null || true
    cast --version 2>/dev/null || true
    anvil --version 2>/dev/null || true
    hardhat --version 2>/dev/null || true
    truffle version 2>/dev/null || true
    ganache --version 2>/dev/null || true
    slither --version 2>/dev/null || true
    myth --version 2>/dev/null || true
    vyper --version 2>/dev/null || true

    # Install Node deps if package.json exists
    if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
      echo "📦 Installing Node dependencies (detected package.json)"
      if command -v pnpm >/dev/null 2>&1; then pnpm install || true
      elif command -v yarn >/dev/null 2>&1; then yarn install || true
      else npm ci || npm install || true
      fi
    fi

    # Helpful aliases
    alias f='forge'
    alias c='cast'
    alias an='anvil -p ${ANVIL_PORT:-8545} -h ${ANVIL_HOST:-127.0.0.1}'
    alias hh='hardhat'
    alias tr='truffle'
    alias gn='ganache -p ${ANVIL_PORT:-8545} -h ${ANVIL_HOST:-127.0.0.1}'

    alias solfmt='prettier --plugin=prettier-plugin-solidity "**/*.sol" --write || true'
    alias sollint='solhint "**/*.sol" || true'
    alias sl='slither . || true'
    alias mythanalyze='myth analyze || true'
    alias ech='echidna-test . || true'

    alias geth-local='geth --dev --http --http.api eth,net,web3,personal --http.addr 0.0.0.0 --http.port 8545'

    # Brownie
    alias brownie='brownie'

    # Quick project scaffolding hints
    echo "💡 Forge init: forge init my-contracts"
    echo "💡 Hardhat init: npm create --yes hardhat"

    # Sample project hint
    if [ -f "${CHAINRICE_SOLIDITY_ROOT}/index.sol" ]; then
      echo "📘 Sample exists at ${CHAINRICE_SOLIDITY_ROOT}"
    fi
  '';
}
