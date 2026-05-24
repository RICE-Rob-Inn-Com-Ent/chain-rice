package main

import (
	"context"
	"os"
	"path/filepath"
)

const pourPipelineScript = `
set -euo pipefail
REPO="${RICE_MONO_ROOT:-/src}"
cd "$REPO"
export PATH="$REPO/infra/bootstrap/.pixi/envs/default/bin:$REPO/.pixi/envs/default/bin:/root/.pixi/bin:/usr/local/bin:/usr/bin:$PATH"

if [[ ! -f cue.mod/module.cue ]] && [[ -f cue.mod.example ]]; then
  mkdir -p cue.mod
  cp cue.mod.example cue.mod/module.cue
fi

echo "── pour: cue emit ──"
cue cmd emit ./infra/out/_tool.cue

echo "── pour: cue genMonorepo ──"
cue cmd genMonorepo ./infra/_tool.cue

echo "── pour: body (re-sync pixi after CUE emit) ──"
export RICE_ATLAS_OUT="$REPO/atlas.sys"
export RICE_MONO_ROOT="$REPO"
cd "$REPO/frontend/inventory"
if ! odin run body_main.odin -file; then
  echo "── pour: body_main failed — perform scan fallback ──"
  cd perform
  odin build . -file -o:none
  ./perform
fi
cd "$REPO"

echo "── pour: proto ──"
if command -v buf >/dev/null 2>&1 && [[ -f infra/proto/buf.yaml ]]; then
  buf lint infra/proto 2>/dev/null || true
  [[ -f infra/proto/buf.gen.yaml ]] && buf generate infra/proto || true
fi
mkdir -p .rice/cache/proto

echo "── pour: docs-site ──"
if [[ -f docs-site/mkdocs.yml ]] && command -v mkdocs >/dev/null 2>&1; then
  mkdocs build -f docs-site/mkdocs.yml -d docs-site/site || true
fi

mkdir -p .rice/cache
echo ok > .rice/cache/pour.ok
echo "✅ pour: MASON skeleton + toolchain"
`

// Pour hydrates the monorepo: CUE emit + genMonorepo + proto/docs (no buck2, no CHIEF).
func (m *Rice) Pour(ctx context.Context) error {
	root := moduleRoot()
	if err := runPourStep(ctx, "pour", func(stepCtx context.Context) error {
		src, err := workspaceDir(stepCtx)
		if err != nil {
			return err
		}
		ctr := withBash(withPixi(src), pourPipelineScript)
		if err := mustSync(stepCtx, ctr, "pour"); err != nil {
			return err
		}
		return exportWorkspace(stepCtx, ctr)
	}); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(root, ".rice", "cache", "pour.ok"), []byte("ok\n"), 0o644)
}
