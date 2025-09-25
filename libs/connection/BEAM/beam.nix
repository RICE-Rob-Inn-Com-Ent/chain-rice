# BEAM bridge to Go backend (Elixir/Erlang) — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Essentials only to build Elixir/Erlang clients talking to a Go backend
# via gRPC/HTTP with protobuf models. Application deps like:
# - GRPC (grpc-elixir), protobuf-elixir, Jason, HTTPoison/Finch
# are resolved via Mix/Hex in your project. This shell provides BEAM toolchain
# and protobuf/gRPC codegen utilities.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  # Pin BEAM toolchain to Erlang/OTP 26 + Elixir 1.15
  beam = pkgs.beam.packages.erlangR26;
  erlang = beam.erlang;
  elixir = beam.elixir_1_15;
  rebar3 = beam.rebar3;

  # Protobuf and gRPC tooling
  protoc = pkgs.protobuf;
  buf = pkgs.buf;
  grpcurl = pkgs.grpcurl;

in pkgs.mkShell {
  name = "beam-bridge-dev";

  packages = [
    # BEAM toolchain
    erlang
    elixir
    rebar3

    # Protobuf/gRPC tools for schema generation and testing
    protoc
    buf
    grpcurl

    # Minimal CLI utilities
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.openssl
    pkgs.pkg-config
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Keep Mix/Hex per-project to avoid global pollution
    export MIX_HOME="$PWD/.mix"
    export HEX_HOME="$PWD/.hex"
    export REBAR_CACHE_DIR="$PWD/.cache/rebar3"

    # Ensure local Mix bin path is used for tasks like credo/dialyzer if added later
    export PATH="$MIX_HOME/bin:$PATH"

    echo "[beam-bridge-dev] Erlang $(${erlang}/bin/erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null | tr -d '"' | tr -d '\n') / Elixir $(${elixir}/bin/elixir -v | tail -n1 | awk '{print $2}') ready."
    echo "NuGet-equivalent for Elixir is Mix/Hex; run 'mix local.hex --force' and 'mix local.rebar --force' on first use."
    echo "Elixir deps to add in mix.exs: grpc, protobuf, jason, httpoison or finch."
    echo "Protobuf tools: protoc=${protoc}/bin/protoc, buf=${buf}/bin/buf, grpcurl available."
  '';
}
