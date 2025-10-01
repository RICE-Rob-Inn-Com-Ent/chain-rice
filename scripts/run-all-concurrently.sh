#!/usr/bin/env bash
set -euo pipefail

echo "🚀 RICE-DEV Monorepo - Launch All Services Concurrently"
echo "======================================================="

if [ ! -f "flake.nix" ]; then
  echo "❌ Error: Please run from repo root (where flake.nix lives)."
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "❌ Error: Nix not installed."
  exit 1
fi

mkdir -p logs

# Single Nix shell session; run all processes via concurrently
nix --extra-experimental-features "nix-command flakes" develop .#monorepo --command bash -lc '
  set -euo pipefail
  corepack enable >/dev/null 2>&1 || true
  echo "📦 Pre-building targets (this may take a while)..."
  bazel build //... || true

  echo "🔥 Starting services with concurrently..."
  concurrently \
    --names "NEXT,ANGULAR,NUXT,GO,FASTAPI,BEAM,BOT_CORE,BOT_INT,RUST,SOLIDITY" \
    --prefix-colors "cyan,green,magenta,blue,yellow,red,brightBlue,brightGreen,brightMagenta,brightYellow" \
    --kill-others-on-fail \
    --raw \
    \
    "bazel run //libs/frontend/ts/next:dev --watch" \
    "bazel run //libs/frontend/ts/angular:dev --watch" \
    "bazel run //libs/frontend/ts/nuxt:dev --watch" \
    "bazel run //libs/backend:dev --watch" \
    "bazel run //libs/connection/FastAPI:dev --watch" \
    "bazel run //libs/connection/BEAM:dev --watch" \
    "bazel run //bots/core:dev --watch" \
    "bazel run //bots/integration:dev --watch" \
    "bazel run //libs/contract/rust:dev --watch" \
    "bazel run //libs/contract/solidity:dev --watch"
'

echo "✅ All processes exited."


