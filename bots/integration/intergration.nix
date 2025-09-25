# Bot Integration Services development environment (Python 3.11)
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Notes:
# - Uses latest stable nixpkgs by default via getFlake (overridable via `pkgs`).
# - Focused on integrations, APIs, and orchestration; no AI training libs included.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  python = pkgs.python311;
  ps = pkgs.python311Packages;

  pythonEnv = python.withPackages (ps: [
    # HTTP clients
    ps.httpx
    ps.requests
    ps.aiohttp

    # Websockets / Socket.IO
    ps.websockets
    ps."python-socketio"

    # Chat platform SDKs
    ps."python-telegram-bot"
    ps.discordpy
    ps."slack-sdk"

    # API clients
    ps.openai
    ps."huggingface-hub"

    # Serialization / data
    ps.pydantic
    ps.pyyaml
    ps.orjson

    # Scheduling
    ps.apscheduler

    # Logging
    ps.loguru
    ps.structlog
  ]);

in pkgs.mkShell {
  name = "bot-integration-dev";

  packages = [
    pythonEnv

    # Useful CLI tooling
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.openssl
    pkgs.pkg-config
  ];

  shellHook = ''
    export PYTHONNOUSERSITE=1
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
    echo "[bot-integration-dev] Python $(python --version) ready."
  '';
}
