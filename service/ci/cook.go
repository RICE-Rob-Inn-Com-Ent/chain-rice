package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func cookChiefScript(project string) string {
	slug := strings.TrimSpace(project)
	return fmt.Sprintf(`
set -euo pipefail
REPO="${RICE_MONO_ROOT:-/src}"
cd "$REPO"
export PATH="$REPO/.pixi/envs/default/bin:/root/.pixi/bin:/usr/local/bin:/usr/bin:${HOME}/.cargo/bin:${PATH}"

if [[ ! -f .rice/cache/forge.ok ]]; then
  echo "error: run rice forge first" >&2
  exit 1
fi

export CHIEF_PROJECT=%q
export RICE_MONO_ROOT="$REPO"

echo "── cook: Mint apply-all ──"
cargo run -q --manifest-path base/Cargo.toml -p mint --bin mint_overlay_check -- --apply-all

echo "── cook: cue cmd genChief ──"
cue cmd genChief ./infra/_tool.cue

if command -v buck2 >/dev/null 2>&1; then
  buck2 build //infra/package:validate_package_cue //infra/build:validate_build_cue 2>/dev/null || true
fi

mkdir -p .rice/cache
echo "project=%s" > .rice/cache/cook.ok
echo "✅ cook: CHIEF overlay applied for %s"
`, slug, slug, slug)
}

// Cook applies CHIEF overlays (Mint + genChief). Use rice serve for release artifacts.
func (m *Rice) Cook(ctx context.Context, project string) error {
	if strings.TrimSpace(project) == "" {
		return fmt.Errorf("project name required: rice cook <project>")
	}
	if _, err := chiefProjectDir(project); err != nil {
		return err
	}
	src, err := workspaceDir(ctx)
	if err != nil {
		return err
	}
	if err := runPourStep(ctx, "cook", func(stepCtx context.Context) error {
		ctr := withBash(withPixi(src), cookChiefScript(project))
		if err := mustSync(stepCtx, ctr, "cook"); err != nil {
			return err
		}
		return exportWorkspace(stepCtx, ctr)
	}); err != nil {
		return err
	}
	ok := filepath.Join(moduleRoot(), ".rice", "cache", "cook.ok")
	if _, err := os.Stat(ok); err != nil {
		return fmt.Errorf("cook: cook.ok missing: %w", err)
	}
	fmt.Printf("✅ cook %q complete\n", project)
	return nil
}
