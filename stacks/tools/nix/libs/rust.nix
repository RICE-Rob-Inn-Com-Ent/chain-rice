{ pkgs }:

{
  packages = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
    rustup
    
    # Rust development tools
    cargo-watch
    cargo-edit
    cargo-audit
    cargo-outdated
    cargo-tree
    cargo-expand
    cargo-llvm-cov  # Code coverage
    cargo-udeps
    cargo-sort
    cargo-tarpaulin
    
    # CosmWasm specific tools
    cargo-generate
    cargo-make
    
    # WASM tools
    wasm-pack
    wasmtime
    wasm-bindgen-cli
    binaryen  # wasm-opt
    wabt      # wasm2wat, etc.
    trunk
    
    # Build dependencies
    gcc
    pkg-config
    openssl
    clang_18
    llvmPackages_18.lld
    mold
    sccache
    
    # Additional tools for smart contract development
    protobuf
    
    # Testing and benchmarking
    cargo-nextest
    cargo-criterion
    
    # Documentation
    mdbook
    
    # Cross-compilation support
    cargo-cross
    
    # Linting and security
    cargo-deny
    cargo-geiger  # Security audit
    
    # Development utilities
    just  # Command runner (alternative to make)
    
    # Binary inspection
    binutils
    
    # Network tools for blockchain interaction
    curl
    jq
  ];
  
  envVars = {
    # Rust configuration
    RUST_BACKTRACE = "1";
    CARGO_INCREMENTAL = "1";
    RUST_LOG = "debug";
    CARGO_TERM_COLOR = "always";
    
    # CosmWasm specific
    COSMWASM_VERSION = "1.4";
    
    # Build optimization
    CARGO_TARGET_DIR = "$PWD/target";
    RUSTFLAGS = "-C target-cpu=native";
    RUSTC_WRAPPER = "sccache";
    
    # ChainRice specific Rust settings
    CHAINRICE_CONTRACTS_ROOT = "$PWD/contracts/rust";
    
    # WASM optimization
    RUSTFLAGS_WASM = "-C link-arg=-s -C opt-level=z";
    
    # Development settings
    CARGO_WATCH_IGNORE = "target/";
    
    # Security settings
    CARGO_AUDIT_DATABASE = "$HOME/.cargo/advisory-db";
    
    # Cross-compilation
    CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
    
    # Testing
    CARGO_TEST_THREADS = "1";  # For blockchain tests
  };
  
  shellHook = ''
    echo "🦀 Rust ${pkgs.rustc.version} with CosmWasm development tools"
    echo "   • Cargo for package management"
    echo "   • Clippy for linting"
    echo "   • Rust Analyzer for IDE support"
    echo "   • CosmWasm tools for smart contracts"
    echo "   • WASM tools (wasm-bindgen, wasm-pack, wasm-opt, wabt, trunk)"
    echo "   • sccache, mold/LLD for faster builds"
    
    # Configure linker preference: mold -> lld
    if ! ${CARGO_TARGET_DIR:+true}; then :; fi
    if ${CXX:-clang++} -fuse-ld=mold -Wl,--version >/dev/null 2>&1; then
      export RUSTFLAGS="${RUSTFLAGS} -C linker=clang -C link-arg=-fuse-ld=mold"
    elif ${CXX:-clang++} -fuse-ld=lld -Wl,--version >/dev/null 2>&1; then
      export RUSTFLAGS="${RUSTFLAGS} -C linker=clang -C link-arg=-fuse-ld=lld"
    fi

    # Enable sccache
    if command -v sccache >/dev/null 2>&1; then
      export RUSTC_WRAPPER="sccache"
      mkdir -p "$HOME/.cache/sccache"
      sccache --version >/dev/null 2>&1 || true
    fi

    # Ensure rustup exists and install WASM target if missing
    if command -v rustup >/dev/null 2>&1; then
      if ! rustup target list --installed | grep -q wasm32-unknown-unknown; then
        echo "📦 Installing WASM target..."
        rustup target add wasm32-unknown-unknown
      fi
    fi
    
    # Install cargo-generate for CosmWasm templates
    if ! command -v cargo-generate &> /dev/null; then
      echo "🛠️  Installing cargo-generate..."
      cargo install cargo-generate
    fi
    
    # Install cosmwasm-check for contract validation
    if ! command -v cosmwasm-check &> /dev/null; then
      echo "🔍 Installing cosmwasm-check..."
      cargo install cosmwasm-check
    fi
    
    # Install cargo-make for task automation
    if ! command -v cargo-make &> /dev/null; then
      echo "⚙️  Installing cargo-make..."
      cargo install cargo-make
    fi
    
    # Set up CosmWasm development environment
    if [ -d "contracts/rust" ]; then
      echo "📁 CosmWasm contracts found in contracts/rust"
      export CARGO_MANIFEST_DIR="$PWD/contracts/rust"
      
      # Build contracts if Cargo.toml exists
      if [ -f "contracts/rust/Cargo.toml" ]; then
        echo "🏗️  Building CosmWasm contracts..."
        cd contracts/rust
        cargo check --target wasm32-unknown-unknown
        cd - > /dev/null
      fi
    fi
    
    # Update advisory database
    if command -v cargo-audit &> /dev/null; then
      echo "🔒 Updating security advisory database..."
      cargo audit --update-db
    fi
    
    # Aliases for common Rust operations
    alias cb='cargo build'
    alias ct='cargo test'
    alias cc='cargo check'
    alias cf='cargo fmt'
    alias ccl='cargo clippy'
    alias cr='cargo run'
    alias cw='cargo watch'
    alias cu='cargo update'
    alias ca='cargo audit'
    alias cne='cargo nextest run'
    alias culcov='cargo llvm-cov'
    alias ctarpa='cargo tarpaulin'
    alias cudeps='cargo udeps'
    alias csort='cargo sort -w'
    
    # CosmWasm specific aliases
    alias cwbuild='cargo build --target wasm32-unknown-unknown --release'
    alias cwtest='cargo test --target wasm32-unknown-unknown'
    alias cwcheck='cosmwasm-check'
    alias cwoptimize='docker run --rm -v "$(pwd)":/code cosmwasm/rust-optimizer:0.12.13'
    alias wb='wasm-bindgen'
    alias wopt='wasm-opt -Oz'
    alias w2wat='wasm2wat'
    alias trunkd='trunk serve'
    
    # ChainRice contract aliases
    alias chainrice-contracts='cd contracts/rust'
    alias build-contracts='cargo make build-contracts'
    alias test-contracts='cargo make test-contracts'
    alias optimize-contracts='cargo make optimize-contracts'
  '';
}
