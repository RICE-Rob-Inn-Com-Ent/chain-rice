NIX_FLAGS ?= --extra-experimental-features 'nix-command flakes'
DEV_ATTR ?= dev
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

.PHONY: dev help

dev:
	@echo "Using Nix: $(NIX_CMD)"
	@$(NIX_CMD) $(NIX_FLAGS) run .#$(DEV_ATTR) -- $(ARGS)

help:
	@echo "Targets:"
	@echo "  dev      Run flake app attribute '#$(DEV_ATTR)' via Nix"
	@echo ""
	@echo "Variables:"
	@echo "  NIX_FLAGS='$(NIX_FLAGS)'"
	@echo "  DEV_ATTR=$(DEV_ATTR)"
	@echo "  ARGS='extra args passed after --'"


