# Python bridge to Python servers (FastAPI/Starlette) — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Essential integration/middleware libraries only (no AI, DB, analytics, or viz).

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  python = pkgs.python311;

  pythonEnv = python.withPackages (ps: [
    # Framework and ASGI base
    ps.fastapi
    ps.starlette

    # HTTP clients/servers
    ps.aiohttp
    ps.httpx
    ps.requests

    # Validation & serialization
    ps.pydantic

    # ASGI servers
    ps.uvicorn
    ps.hypercorn

    # WebSockets
    ps.websockets

    # Logging
    ps.loguru
  ]);

in pkgs.mkShell {
  name = "python-bridge-fastapi-dev";

  packages = [
    pythonEnv

    # Useful CLI tools
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

    echo "[python-bridge-fastapi-dev] Python $(python --version) ready for API/middleware bridging."
    echo "Run: uvicorn app:app --reload or hypercorn app:app --reload"
  '';
}
