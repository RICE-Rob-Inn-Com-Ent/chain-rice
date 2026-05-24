package main

import (
	"context"
	"fmt"
	"strings"
)

func prepareScript(project string, minimal bool, force bool) string {
	profile := ""
	if minimal {
		profile = "--minimal"
	}
	forceFlag := ""
	if force {
		forceFlag = "--force"
	}
	slug := strings.TrimSpace(project)
	return fmt.Sprintf(`
set -euo pipefail
REPO="${RICE_MONO_ROOT:-/src}"
cd "$REPO"
export PATH="/root/.pixi/bin:$REPO/.pixi/envs/default/bin:${HOME}/.cargo/bin:${PATH}"
export RICE_MONO_ROOT="$REPO"

if [[ ! -f .rice/cache/forge.ok ]]; then
  echo "error: run rice forge before prepare" >&2
  exit 1
fi

if [[ -d "custom/%s/bowl" ]] && [[ "%s" != "--force" ]]; then
  cargo run -q --manifest-path base/Cargo.toml -p mint --bin mint_prepare -- --project %q --mirror-only
else
  cargo run -q --manifest-path base/Cargo.toml -p mint --bin mint_prepare -- --project %q %s %s
  cargo run -q --manifest-path base/Cargo.toml -p mint --bin mint_prepare -- --project %q --mirror-only %s
fi
echo "✅ rice prepare %q (scaffold + stack mirror)"
`, slug, forceFlag, slug, slug, profile, forceFlag, slug, forceFlag, slug)
}

// Prepare scaffolds custom/<project>/ and mirrors the monorepo .rice stack tree.
func (m *Rice) Prepare(ctx context.Context, project string) error {
	if strings.TrimSpace(project) == "" {
		return fmt.Errorf("project name required: rice prepare <project>")
	}
	src, err := workspaceDir(ctx)
	if err != nil {
		return err
	}
	minimal := strings.EqualFold(strings.TrimSpace(getenv("RICE_PREPARE_PROFILE", "")), "minimal")
	force := strings.EqualFold(strings.TrimSpace(getenv("RICE_PREPARE_FORCE", "")), "true")
	if err := runPourStep(ctx, "prepare", func(stepCtx context.Context) error {
		ctr := withBash(withPixi(src), prepareScript(project, minimal, force))
		if err := mustSync(stepCtx, ctr, "prepare"); err != nil {
			return err
		}
		return exportWorkspace(stepCtx, ctr)
	}); err != nil {
		return err
	}
	fmt.Printf("✅ prepare %q complete\n", project)
	return nil
}
