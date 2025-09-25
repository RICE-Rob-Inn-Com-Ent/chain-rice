# Protobuf compilation for multi-language setup — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Protobuf tooling only (no backend/AI/analytics). Provides protoc and
# language-specific plugins for Go, TypeScript, Dart, and optional bridges.
# Bazel can use these Nix-provided tools via --protoc and --plugin flags.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  # Core protobuf compiler
  protoc = pkgs.protobuf;

  # Go plugins
  protocGenGo = pkgs.protoc-gen-go;
  protocGenGoGrpc = pkgs.protoc-gen-go-grpc;

  # TypeScript plugin (ts-proto)
  tsProto = pkgs.nodePackages_latest."ts-proto" or null;

  # Dart plugin
  protocGenDart = pkgs.protoc-gen-dart or null;

  # Optional language-specific plugins (if available in nixpkgs)
  protocGenGrpcWeb = pkgs.protoc-gen-grpc-web or null;
  protocGenGrpcJava = pkgs.protoc-gen-grpc-java or null;
  protocGenGrpcCsharp = pkgs.protoc-gen-grpc-csharp or null;

  # Additional tools
  buf = pkgs.buf;
  grpcurl = pkgs.grpcurl;

in pkgs.mkShell {
  name = "protobuf-compilation-dev";

  packages = [
    protoc
    protocGenGo
    protocGenGoGrpc

    buf
    grpcurl

    # Helpful CLIs
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.which
    pkgs.unzip
  ] ++ pkgs.lib.optional (tsProto != null) tsProto
    ++ pkgs.lib.optional (protocGenDart != null) protocGenDart
    ++ pkgs.lib.optional (protocGenGrpcWeb != null) protocGenGrpcWeb
    ++ pkgs.lib.optional (protocGenGrpcJava != null) protocGenGrpcJava
    ++ pkgs.lib.optional (protocGenGrpcCsharp != null) protocGenGrpcCsharp;

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Ensure protoc plugins are in PATH
    export PATH=${protocGenGo}/bin:${protocGenGoGrpc}/bin:$PATH

    echo "[protobuf-compilation-dev] protoc $(protoc --version | head -n1)"
    echo "Available plugins:"
    echo "  Go: protoc-gen-go, protoc-gen-go-grpc"
    ${pkgs.lib.optionalString (tsProto != null) "echo \"  TypeScript: ts-proto\""}
    ${pkgs.lib.optionalString (protocGenDart != null) "echo \"  Dart: protoc-gen-dart\""}
    ${pkgs.lib.optionalString (protocGenGrpcWeb != null) "echo \"  gRPC-Web: protoc-gen-grpc-web\""}
    ${pkgs.lib.optionalString (protocGenGrpcJava != null) "echo \"  Java: protoc-gen-grpc-java\""}
    ${pkgs.lib.optionalString (protocGenGrpcCsharp != null) "echo \"  C#: protoc-gen-grpc-csharp\""}
    echo "Additional tools: buf, grpcurl"
    echo ""
    echo "Bazel integration:"
    echo "  bazel build //... --protoc=${protoc}/bin/protoc --plugin=protoc-gen-go=${protocGenGo}/bin/protoc-gen-go"
    echo "  bazel build //... --plugin=protoc-gen-go-grpc=${protocGenGoGrpc}/bin/protoc-gen-go-grpc"
  '';
}
