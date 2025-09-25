# Shared TypeScript frontend tooling — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Shared tooling only (no backend/AI/analytics). Intended to be used across
# Angular, Next.js/React, and Nuxt/Vue projects. Most packages are best installed
# per-project via package.json for exact versioning. This shell provides Node.js,
# package managers, and optionally global tools from nixpkgs when available.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  nodejs = pkgs.nodejs_20 or pkgs.nodejs;
  npm = pkgs.npm;
  yarn = pkgs.yarn;
  pnpm = pkgs.pnpm;

  # Node packages from nixpkgs (optional convenience; prefer local npm installs)
  nodePkgs = pkgs.nodePackages_latest;
  typescript = nodePkgs.typescript or null;
  eslint = nodePkgs.eslint or null;
  prettier = nodePkgs.prettier or null;
  jest = nodePkgs.jest or null;
  vitest = nodePkgs.vitest or null;
  playwright = nodePkgs.playwright or null;
  vite = nodePkgs.vite or null;
  webpack = nodePkgs.webpack or null;

in pkgs.mkShell {
  name = "ts-shared-tooling-dev";

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
  ] ++ pkgs.lib.optional (typescript != null) typescript
    ++ pkgs.lib.optional (eslint != null) eslint
    ++ pkgs.lib.optional (prettier != null) prettier
    ++ pkgs.lib.optional (jest != null) jest
    ++ pkgs.lib.optional (vitest != null) vitest
    ++ pkgs.lib.optional (playwright != null) playwright
    ++ pkgs.lib.optional (vite != null) vite
    ++ pkgs.lib.optional (webpack != null) webpack;

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Enable Corepack to manage yarn/pnpm versions from packageManager field
    corepack enable >/dev/null 2>&1 || true

    # Local npm prefix (optional, keeps globals project-local)
    export NPM_CONFIG_PREFIX="$PWD/.npm-global"
    mkdir -p "$NPM_CONFIG_PREFIX/bin"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

    echo "[ts-shared-tooling-dev] Node $(node --version), npm $(npm --version), yarn $(yarn --version), pnpm $(pnpm --version)."
    echo "Install per-project: typescript eslint prettier jest vitest @playwright/test vite webpack."
    echo "Playwright note: run 'npx playwright install' to fetch browsers as needed."
  '';
}
