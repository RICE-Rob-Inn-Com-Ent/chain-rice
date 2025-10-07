NIX_FLAGS ?= --extra-experimental-features 'nix-command flakes'
DEV_ATTR ?= monorepo
ARGS ?=

# Resolve Nix command: prefer system nix, then nix-portable if available
NIX_CMD := $(shell command -v nix 2>/dev/null)
ifeq ($(NIX_CMD),)
  ifneq ("$(wildcard .nix-portable/nix-portable)","")
    NIX_CMD := ./.nix-portable/nix-portable
  else
    NIX_CMD := nix
  endif
endif

.PHONY: install dev compose up down logs shell help

install:
	@echo "[install] Preparing dev environment via Nix..."
	@$(NIX_CMD) $(NIX_FLAGS) develop .#monorepo --impure -c bash -c "echo 'Dev shell OK'"
	@echo "[install] Installing Node dependencies (if present)..."
	@[ -f libs/frontend/ts/package.json ] && (cd libs/frontend/ts && npm install) || true
	@[ -f projects/chain-rice/package.json ] && (cd projects/chain-rice && npm install) || true
	@echo "[install] Python: creating venv and installing pre-commit..."
	@python3 -m venv .venv && . .venv/bin/activate && pip install -U pip pre-commit || true
	@. .venv/bin/activate && pre-commit install || true
	@echo "[install] Done."

compose:
	@$(NIX_CMD) $(NIX_FLAGS) develop .#monorepo --impure -c docker compose $(ARGS)

up:
	@$(MAKE) compose ARGS="up --build"

down:
	@$(MAKE) compose ARGS="down"

logs:
	@$(MAKE) compose ARGS="logs -f"

shell:
	@$(NIX_CMD) $(NIX_FLAGS) develop .#monorepo --impure

dev:
	@echo "Using Nix: $(NIX_CMD)"
	@$(NIX_CMD) $(NIX_FLAGS) develop .#monorepo --impure -c bash -c "docker compose up --build"

help:
	@echo "Targets:"
	@echo "  install   Setup dev env (Nix, Node deps, pre-commit)"
	@echo "  dev       Enter Nix shell and start docker compose"
	@echo "  compose   Run arbitrary docker compose via Nix (use ARGS=...)"
	@echo "  up/down   Convenience wrappers for docker compose up/down"
	@echo "  logs      Tail docker compose logs"
	@echo "  shell     Enter Nix monorepo shell"
	@echo "Variables:"
	@echo "  NIX_FLAGS='$(NIX_FLAGS)'"
	@echo "  DEV_ATTR=$(DEV_ATTR)"
	@echo "  ARGS='extra args passed to docker compose'"
