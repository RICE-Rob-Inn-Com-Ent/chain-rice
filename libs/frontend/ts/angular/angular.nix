# Angular + TypeScript frontend development — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Angular frontend only (no backend/AI/analytics). Project dependencies like
# Angular Material, NGXS/NGRX, and testing libraries (Angular Testing Library,
# Jasmine, Karma) are managed in package.json. This shell provides Node.js,
# Angular CLI, TypeScript, RxJS, and common CLI tools.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  nodejs = pkgs.nodejs_20 or pkgs.nodejs;
  npm = pkgs.npm;
  yarn = pkgs.yarn;
  pnpm = pkgs.pnpm;

  # Node packages available in nixpkgs' nodePackages sets
  nodePkgs = pkgs.nodePackages_latest;
  angularCli = nodePkgs."@angular/cli" or null;
  typescript = nodePkgs.typescript or null;
  rxjs = nodePkgs.rxjs or null;

in pkgs.mkShell {
  name = "angular-ts-frontend-dev";

  packages = [
    nodejs
    npm
    yarn
    pnpm

    # Prefer pure npm install for exact versions in your project; but include
    # these global tools for convenience if available in nixpkgs
  ] ++ pkgs.lib.optional (angularCli != null) angularCli
    ++ pkgs.lib.optional (typescript != null) typescript
    ++ pkgs.lib.optional (rxjs != null) rxjs
    ++ [
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

    # Node package managers
    corepack enable >/dev/null 2>&1 || true

    # Local npm prefix (optional)
    export NPM_CONFIG_PREFIX="$PWD/.npm-global"
    mkdir -p "$NPM_CONFIG_PREFIX/bin"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

    echo "[angular-ts-frontend-dev] Node $(node --version), npm $(npm --version), yarn $(yarn --version), pnpm $(pnpm --version)."
    if command -v ng >/dev/null 2>&1; then
      echo "Angular CLI $(ng version | head -n1)."
    else
      echo "Tip: install Angular CLI locally: npm install -D @angular/cli && npx ng version"
    fi

    echo "Commands: ng new app; ng serve; ng build; ng test"
    echo "Add deps: npm i -D typescript rxjs @angular/material @ngrx/store @ngxs/store @testing-library/angular jasmine karma"
  '';
}
