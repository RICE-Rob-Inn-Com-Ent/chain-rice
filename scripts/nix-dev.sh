#!/usr/bin/env bash
# Unified entry to run ChainRice dev via `nix run .#dev` or `nix dev`
set -euo pipefail

if [ ! -f "flake.nix" ]; then
  echo "Please run from the repository root containing flake.nix" >&2
  exit 1
fi

# Enter monorepo dev shell and start everything; auto-open handled by start-all.sh
nix --extra-experimental-features 'nix-command flakes' develop .#monorepo --impure -c bash ./scripts/start-all.sh


