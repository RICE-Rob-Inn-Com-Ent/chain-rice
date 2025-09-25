# Solidity/EVM blockchain interaction — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Essential blockchain interaction only (no AI/analytics/frontend).
# JavaScript/TypeScript packages like hardhat, ethers, web3, @openzeppelin/contracts,
# dotenv, typechain are resolved via npm/yarn in your project. This shell provides
# Node.js toolchain, Foundry, solc, and protobuf/gRPC utilities.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  nodejs = pkgs.nodejs_20 or pkgs.nodejs;
  npm = pkgs.npm;
  yarn = pkgs.yarn;

  # Solidity compiler
  solc = pkgs.solc;

  # Foundry (forge, cast, anvil)
  foundry = pkgs.foundry;

  # Protobuf/gRPC tooling for cross-chain communication
  protoc = pkgs.protobuf;
  buf = pkgs.buf;
  grpcurl = pkgs.grpcurl;

in pkgs.mkShell {
  name = "solidity-evm-dev";

  packages = [
    nodejs
    npm
    yarn
    solc
    foundry

    # Useful CLI utilities
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.openssl
    pkgs.pkg-config

    # Proto/gRPC CLIs
    protoc
    buf
    grpcurl
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Node.js environment
    export NPM_CONFIG_PREFIX="$PWD/.npm-global"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

    # Foundry environment
    export FOUNDRY_ROOT="$PWD/.foundry"

    echo "[solidity-evm-dev] Node.js $(node --version) with npm $(npm --version) and yarn $(yarn --version) ready."
    echo "Solidity compiler: $(solc --version | head -n1)"
    echo "Foundry: forge $(forge --version | awk '{print $2}'), cast $(cast --version | awk '{print $2}')"
    echo "Use npm/yarn to add: hardhat, ethers, web3, @openzeppelin/contracts, dotenv, typechain."
    echo "Protobuf tools: protoc=${protoc}/bin/protoc, buf=${buf}/bin/buf, grpcurl available."

    # Quick tips:
    # npm init -y
    # npm install hardhat ethers web3 @openzeppelin/contracts dotenv @typechain/hardhat typechain
    # npx hardhat init
    # forge init my-project
  '';
}
