package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

)

func forgeScriptBootstrap() string {
	return `
set -euo pipefail
mkdir -p /src/.rice/cache
if [[ ! -f /src/.rice/cache/pour.ok ]]; then
  echo "error: run rice pour first" >&2
  exit 1
fi
if [[ ! -s /src/atlas.sys ]]; then
  echo "error: run rice perform first" >&2
  exit 1
fi
if [[ ! -f /src/.buckconfig ]]; then
  echo "error: run rice pour first (.buckconfig missing)" >&2
  exit 1
fi
`
}

func forgeScriptBuckBuild() string {
	return `
set -euo pipefail
echo "── forge: buck2 skeleton cache ──"
if ! command -v buck2 >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq zstd curl ca-certificates
  curl --proto '=https' --tlsv1.2 -sSfL https://github.com/facebook/buck2/releases/latest/download/buck2-x86_64-unknown-linux-musl.zst | zstd -d -o /usr/local/bin/buck2
  chmod +x /usr/local/bin/buck2
fi
cd /src
BUCK_COUNT="$(find /src -name BUCK -o -name BUCK.v2 2>/dev/null | wc -l | tr -d ' ')"
echo "discovered ${BUCK_COUNT} BUCK files"
if [[ "${BUCK_COUNT}" = "0" ]]; then
  echo "error: no BUCK files — run rice pour" >&2
  exit 1
fi
buck2 build //infra/package:validate_package_cue //infra/build:validate_build_cue
buck2 build //infra/out:validate_workspace_cue 2>/dev/null || buck2 build //infra/out:render_workspace
echo ok > /src/.rice/cache/forge.ok
echo "✅ forge: buck2 cache warm"
`
}

// Forge warms monorepo buck2 cache. No CHIEF, no docker compose.
func (m *Rice) Forge(ctx context.Context) error {
	root := moduleRoot()
	src, err := workspaceDir(ctx)
	if err != nil {
		return err
	}

	if err := runPourStep(ctx, "forge-bootstrap", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "forge-bootstrap", forgeScriptBootstrap())
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "forge-buck2", func(stepCtx context.Context) error {
		return runBash(ctx, src, "forge-buck2", forgeScriptBuckBuild())
	}); err != nil {
		return err
	}

	if _, err := os.Stat(filepath.Join(root, ".rice", "cache", "forge.ok")); err != nil {
		return fmt.Errorf("forge: forge.ok missing: %w", err)
	}
	fmt.Println("✅ forge complete")
	return nil
}
