{
  description = "rice-mono: unified dev shell with Docker Compose";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
        };
        isDarwin = pkgs.stdenv.isDarwin;
      in {
        devShells = {
          monorepo = pkgs.mkShell {
            name = "rice-mono-dev";
            packages = with pkgs; [
              # =============================================================================
              # CONTAINERS & BUILD SYSTEM
              # =============================================================================
              docker
              docker-compose
              bazelisk
              buildifier

              # =============================================================================
              # NODE / TYPESCRIPT (libs/frontend/ts, projects/chain-rice, solidity)
              # - package.json, tsconfig.json, lockfiles
              # =============================================================================
              nodejs_20
              nodePackages.npm
              yarn
              pnpm

              # =============================================================================
              # PYTHON (bots/, libs/connection/FastAPI)
              # - pyproject.toml, poetry.lock
              # =============================================================================
              python311
              python311Packages.pip
              python311Packages.poetry

              # =============================================================================
              # JULIA (bots/models with Project/Manifest.toml)
              # =============================================================================
              julia

              # =============================================================================
              # GO (libs/backend with go.mod)
              # =============================================================================
              go_1_22

              # =============================================================================
              # RUST (libs/contract/rust with Cargo.toml)
              # =============================================================================
              rustc
              cargo

              # =============================================================================
              # JVM / JAVA (libs/connection/JVM with pom.xml)
              # =============================================================================
              jdk21
              maven
              gradle

              # =============================================================================
              # .NET (libs/connection/.NET with ConnectionDotNet.csproj)
              # =============================================================================
              dotnet-sdk

              # =============================================================================
              # ELIXIR / ERLANG (libs/connection/BEAM with mix.exs)
              # =============================================================================
              beam.packages.erlang_26
              beam.elixir_1_15
              beam.rebar3

              # =============================================================================
              # PHP (libs/connection/PHP with composer.json / composer.lock)
              # =============================================================================
              php
              phpPackages.composer

              # =============================================================================
              # DART / FLUTTER (libs/frontend/dart with pubspec.yaml)
              # =============================================================================
              dart
              flutter

              # =============================================================================
              # KOTLIN (libs/frontend/kotlin)
              # =============================================================================
              kotlin

              # =============================================================================
              # SWIFT (libs/frontend/swift; only on macOS)
              # =============================================================================
            ] ++ (if isDarwin then [ pkgs.swift ] else [] ) ++ [
              # =============================================================================
              # UTILITIES
              # =============================================================================
              git
              curl
              jq
              which
            ];
            shellHook = ''
              echo "[monorepo] Dev shell ready."
              echo "Tools: docker, compose, node (npm/yarn/pnpm), python (pip/poetry), julia, go, rust, java (maven/gradle), dotnet, elixir/erlang, php/composer, dart/flutter, kotlin, ${if isDarwin then "swift" else ""}"
              if ! command -v docker >/dev/null 2>&1; then
                echo "WARN: docker not on PATH" >&2
              fi
            '';
          };
        };
      }
    );
}
