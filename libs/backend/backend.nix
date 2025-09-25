# Go backend development environment for Cosmos SDK (2025)
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Build/test Go backends with Cosmos SDK, gRPC/Protobuf, REST, DB, and auth tooling.
# Note: Go modules (like cosmos-sdk, tendermint, etc.) are resolved by `go mod` in your project.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  # Go toolchain 1.21+
  go = pkgs.go_1_22 or pkgs.go_1_21;

  # Protobuf / gRPC toolchain
  protoc = pkgs.protobuf;
  buf = pkgs.buf;
  protocGenGo = pkgs.protoc-gen-go;
  protocGenGoGrpc = pkgs.protoc-gen-go-grpc;
  grpcurl = pkgs.grpcurl;

  # Helpful Go tools
  gopls = pkgs.gopls;
  delve = pkgs.delve;
  golangci = pkgs.golangci-lint;
  gotestsum = pkgs.gotestsum;
  mockgen = pkgs.golangci-lint.overrideAttrs (_: {}); # fallback if golang/mock not packaged

  # Cosmos/Tendermint utilities (binary tooling where available)
  ignite = pkgs.ignite or pkgs.go-ethereum; # ignite CLI if available
  cometbft = pkgs.cometbft or pkgs.tendermint; # modern Tendermint fork

  # Databases and clients
  postgresql = pkgs.postgresql;
  redis = pkgs.redis;
  sqlite = pkgs.sqlite;

in pkgs.mkShell {
  name = "go-cosmos-backend-dev";

  packages = [
    # Go toolchain and helpers
    go
    gopls
    delve
    golangci
    gotestsum

    # Proto/gRPC
    protoc
    buf
    protocGenGo
    protocGenGoGrpc
    grpcurl

    # Cosmos/Tendermint
    ignite
    cometbft

    # Common CLIs
    pkgs.git
    pkgs.curl
    pkgs.jq

    # DB clients/servers for local dev
    postgresql
    redis
    sqlite
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # GOPATH and bins
    export GOPATH=${"$PWD"}/.gopath
    export GOBIN=${"$GOPATH"}/bin
    export PATH=$GOBIN:$PATH

    # Protobuf plugins so tools can find them
    export PATH=${protocGenGo}/bin:${protocGenGoGrpc}/bin:$PATH

    # If a go.mod exists, download modules (including):
    # - github.com/cosmos/cosmos-sdk
    # - github.com/tendermint/tendermint (or cometbft)
    # - google.golang.org/grpc, google.golang.org/protobuf
    # - github.com/gorilla/mux, github.com/go-chi/chi/v5
    # - github.com/go-resty/resty/v2
    # - gorm.io/gorm, github.com/jackc/pgx/v5, github.com/redis/go-redis/v9
    # - go.uber.org/zap, github.com/sirupsen/logrus, github.com/rs/zerolog
    # - github.com/spf13/viper, github.com/kelseyhightower/envconfig
    # - github.com/golang-jwt/jwt/v5, golang.org/x/oauth2
    # - github.com/stretchr/testify, go.uber.org/mock/gomock
    # - github.com/spf13/cobra, github.com/google/uuid, github.com/patrickmn/go-cache
    if [ -f go.mod ]; then
      echo "[go-cosmos-backend-dev] Detected go.mod; running 'go mod download'..."
      go mod download || true
    fi

    echo "[go-cosmos-backend-dev] Go $(${go}/bin/go version) ready. Protobuf: ${protoc}/bin/protoc, gRPC plugins installed."
    echo "Tip: use 'buf generate' or 'protoc --go_out --go-grpc_out' to regenerate stubs."
  '';
}
