# Nuxt 3 + Vue 3 + TypeScript frontend development — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Frontend only (no backend/AI/analytics). Project dependencies like
# nuxt, vue, typescript, pinia, vue-router, tailwindcss, vitest, and
# @testing-library/vue are managed in package.json. This shell provides Node.js
# and package managers.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  nodejs = pkgs.nodejs_20 or pkgs.nodejs;
  npm = pkgs.npm;
  yarn = pkgs.yarn;
  pnpm = pkgs.pnpm;

in pkgs.mkShell {
  name = "nuxt-vue-ts-frontend-dev";

  packages = [
    nodejs
    npm
    yarn
    pnpm

    # Helpful CLIs
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.which
    pkgs.unzip
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Enable Corepack to manage yarn/pnpm versions from packageManager field
    corepack enable >/dev/null 2>&1 || true

    # Local npm prefix (optional, keeps globals project-local)
    export NPM_CONFIG_PREFIX="$PWD/.npm-global"
    mkdir -p "$NPM_CONFIG_PREFIX/bin"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

    echo "[nuxt-vue-ts-frontend-dev] Node $(node --version), npm $(npm --version), yarn $(yarn --version), pnpm $(pnpm --version)."
    echo "Add deps: npm i -D typescript vitest @testing-library/vue && npm i nuxt vue vue-router pinia tailwindcss postcss autoprefixer"
    echo "Run: npx nuxt dev | nuxt build | nuxt test"
  '';
}
