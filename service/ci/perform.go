package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
)

const performScript = `
set -euo pipefail
REPO="${RICE_MONO_ROOT:-/src}"
export RICE_ATLAS_OUT="/src/atlas.sys"
test -s "${RICE_ATLAS_OUT}"
wc -c "${RICE_ATLAS_OUT}"
echo "✅ perform: atlas.sys v2 (body-odin)"
`

// Perform runs hardware discovery and writes atlas.sys at repository root.
func (m *Rice) Perform(ctx context.Context) error {
	root := moduleRoot()
	if err := runPourStep(ctx, "perform", func(stepCtx context.Context) error {
		src, err := workspaceDir(stepCtx)
		if err != nil {
			return err
		}
		ctr := withBash(withOdin(src), performScript)
		if err := mustSync(stepCtx, ctr, "perform"); err != nil {
			return err
		}
		if err := exportWorkspace(stepCtx, ctr); err != nil {
			return err
		}
		atlasOut := filepath.Join(root, "atlas.sys")
		if _, err := ctr.File(filepath.Join(riceWorkspaceMount, "atlas.sys")).Export(stepCtx, atlasOut); err != nil {
			return fmt.Errorf("export atlas.sys: %w", err)
		}
		return nil
	}); err != nil {
		return err
	}
	atlas := filepath.Join(root, "atlas.sys")
	st, err := os.Stat(atlas)
	if err != nil || st.Size() == 0 {
		return fmt.Errorf("perform: atlas.sys missing or empty")
	}
	fmt.Printf("perform: atlas.sys (%d bytes)\n", st.Size())
	return nil
}
