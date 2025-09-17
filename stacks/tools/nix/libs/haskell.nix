{ pkgs }:

{
  packages = with pkgs; [
    # Compilers and build tools
    ghc
    cabal-install
    stack

    # Language server and dev tooling
    haskell-language-server
    hlint
    fourmolu
    ormolu
    stylish-haskell
    hoogle
    cabal-fmt
    cabal2nix
    alex
    happy

    # System libraries commonly required by Haskell packages
    pkg-config
    zlib
    openssl
    libffi
    gmp
    sqlite
    postgresql

    # Utilities
    git
    ripgrep
    fd
  ];
  
  envVars = {
    # Haskell build configuration
    CABAL_DIR = "$HOME/.cabal";
    STACK_ROOT = "$HOME/.stack";
    LC_ALL = "en_US.UTF-8";

    # Prefer cabal new-build style
    CABAL_REINIT_CONFIG = "0";

    # Project root hint
    CHAINRICE_HASKELL_ROOT = "$PWD/stacks/langs/haskell";
  };
  
  shellHook = ''
    echo "🔷 Haskell GHC: $(ghc --version | sed -n '1p')"
    echo "   • cabal/stack toolchains"
    echo "   • HLS, hlint, fourmolu/ormolu, stylish-haskell, hoogle"

    # Ensure configuration directories
    mkdir -p "$CABAL_DIR" "$STACK_ROOT"

    # Update cabal package index (non-blocking)
    (cabal update >/dev/null 2>&1 || true) &

    # Warm up HLS (non-blocking)
    if command -v haskell-language-server >/dev/null 2>&1; then
      (haskell-language-server --version >/dev/null 2>&1 || true) &
    fi

    # Generate Hoogle database (non-blocking)
    if command -v hoogle >/dev/null 2>&1; then
      (hoogle generate >/dev/null 2>&1 || true) &
    fi

    # Helpful aliases (cabal)
    alias cb='cabal build'
    alias cr='cabal run'
    alias ct='cabal test'
    alias cclean='cabal clean'
    alias cfmt='cabal-fmt --inplace $(git ls-files "**/*.cabal")'

    # Helpful aliases (stack)
    alias sb='stack build'
    alias sr='stack run'
    alias st='stack test'

    # Formatting and linting
    alias hsfmt='fourmolu -i $(git ls-files "**/*.hs" "**/*.lhs") || ormolu -i $(git ls-files "**/*.hs" "**/*.lhs")'
    alias hl='hlint .'

    # Code generators
    alias alexg='alex'
    alias happ='happy'

    # Sample project hint
    if [ -f "${CHAINRICE_HASKELL_ROOT}/src/Main.hs" ]; then
      echo "📘 Sample available at ${CHAINRICE_HASKELL_ROOT}"
      echo "   ghc -o main ${CHAINRICE_HASKELL_ROOT}/src/Main.hs ${CHAINRICE_HASKELL_ROOT}/src/Utils.hs && ./main"
      echo "   or: (cd ${CHAINRICE_HASKELL_ROOT} && cabal build && cabal run)"
    fi
  '';
}
