# PHP bridge to Go backend — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Essential integration/middleware only (no web frameworks/AI/analytics).
# PHP libraries like guzzlehttp/guzzle, symfony/http-client, psr/http-message,
# psr/http-factory, and monolog/monolog are resolved via Composer in your project.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  php = pkgs.php82 or pkgs.php;

  phpWithExt = php.withExtensions (exts: with exts; [
    curl
    json
    openssl
  ]);

  composer = pkgs.phpPackages.composer;

  # Protobuf/gRPC tooling for schema work and testing
  protoc = pkgs.protobuf;
  buf = pkgs.buf;
  grpcurl = pkgs.grpcurl;

in pkgs.mkShell {
  name = "php-bridge-dev";

  packages = [
    phpWithExt
    composer

    # Useful CLI utilities
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.openssl
    pkgs.pkg-config

    # Proto/gRPC CLIs
    protoc
    buf
    grpcurl
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Composer cache per-project to avoid global pollution
    export COMPOSER_HOME="$PWD/.composer"

    echo "[php-bridge-dev] PHP $(${phpWithExt}/bin/php -v | head -n1) with Composer $(composer --version | awk '{print $3}') ready."
    echo "Use Composer to add: guzzlehttp/guzzle, symfony/http-client, psr/http-message, psr/http-factory, monolog/monolog."
    echo "Protobuf tools: protoc=${protoc}/bin/protoc, buf=${buf}/bin/buf, grpcurl available."

    # Quick tips:
    # composer init --no-interaction
    # composer require guzzlehttp/guzzle:^7 psr/http-message psr/http-factory monolog/monolog symfony/http-client
  '';
}
