# .NET bridge to Go backend (2025)
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Essentials only to build .NET clients that talk to a Go backend via
# gRPC/HTTP with protobuf models. Packages like Grpc.Net.Client, Google.Protobuf,
# Grpc.Tools, Refit, System.Text.Json/Newtonsoft.Json, Microsoft.Extensions.* are
# resolved via NuGet in your .NET projects (csproj). This shell provides the
# .NET SDK and protobuf toolchain.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  dotnet = pkgs.dotnet-sdk_8 or pkgs.dotnet-sdk;

  # Protobuf and gRPC tooling for schema compilation and testing
  protoc = pkgs.protobuf;
  buf = pkgs.buf;
  grpcurl = pkgs.grpcurl;

in pkgs.mkShell {
  name = ".net-bridge-dev";

  packages = [
    # .NET SDK 8+
    dotnet

    # Protobuf/gRPC tooling
    protoc
    buf
    grpcurl

    # Useful CLI utilities
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.openssl
    pkgs.pkg-config
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # .NET asks for DOTNET_CLI_TELEMETRY_OPTOUT in CI/dev sometimes
    export DOTNET_CLI_TELEMETRY_OPTOUT=1

    echo "[.net-bridge-dev] .NET $(${dotnet}/bin/dotnet --version) ready."
    echo "NuGet restore will pull: Grpc.Net.Client, Google.Protobuf, Grpc.Tools,"
    echo "Refit, System.Text.Json/Newtonsoft.Json, Microsoft.Extensions.Logging/DependencyInjection, etc."
    echo "Protobuf tools: protoc=${protoc}/bin/protoc, buf=${buf}/bin/buf, grpcurl available."

    # Quick tips:
    # - dotnet new console -n BridgeClient
    # - dotnet add BridgeClient package Grpc.Net.Client
    # - dotnet add BridgeClient package Google.Protobuf
    # - dotnet add BridgeClient package Grpc.Tools
    # - dotnet add BridgeClient package Refit
  '';
}
