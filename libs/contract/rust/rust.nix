# Rust blockchain/Cosmos SDK interaction — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Essential blockchain interaction only (no frontend/AI/analytics).
# Rust crates like cosmwasm, cosmrs, tendermint-rs, serde, reqwest, tokio,
# anyhow/thiserror, prost, tonic/grpcio, hex/base64 are resolved via Cargo
# in your project. This shell provides Rust toolchain and protobuf/gRPC utilities.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  rust = pkgs.rust-bin.stable.latest or pkgs.rustc;

  rustWithComponents = rust.override {
    extensions = [ "rust-src" "rustfmt" "clippy" ];
  };

  cargo = pkgs.cargo;

  # Protobuf/gRPC tooling for schema work and testing
  protoc = pkgs.protobuf;
  buf = pkgs.buf;
  grpcurl = pkgs.grpcurl;

in pkgs.mkShell {
  name = "rust-blockchain-dev";

  packages = [
    rustWithComponents
    cargo

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

    # Rust environment
    export CARGO_HOME="$PWD/.cargo"
    export RUSTUP_HOME="$PWD/.rustup"

    # Ensure cargo and rustc are in PATH
    export PATH="$CARGO_HOME/bin:$PATH"

    echo "[rust-blockchain-dev] Rust $(${rustWithComponents}/bin/rustc --version) with Cargo $(cargo --version | awk '{print $2}') ready."
    echo "Use Cargo to add: cosmwasm, cosmrs, tendermint-rs, serde, reqwest, tokio, anyhow/thiserror, prost, tonic/grpcio, hex/base64."
    echo "Protobuf tools: protoc=${protoc}/bin/protoc, buf=${buf}/bin/buf, grpcurl available."

    # Quick tips:
    # cargo init --name blockchain-client
    # cargo add cosmwasm cosmrs tendermint-rs serde serde_json reqwest tokio anyhow thiserror prost tonic hex base64
  '';
}
