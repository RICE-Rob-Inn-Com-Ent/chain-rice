package main

import (
	"context"
	"fmt"
	"path/filepath"
)

// Perform runs Odin hardware discovery and writes atlas.sys at repository root.
func (m *Rice) Perform(ctx context.Context) error {
	src, err := workspaceDir()
	if err != nil {
		return err
	}
	runner := filepath.ToSlash(filepath.Join("frontend", "inventory", "perform"))
	atlasOut := filepath.ToSlash(filepath.Join("/src", "atlas.sys"))
	script := fmt.Sprintf(`
set -euo pipefail
echo "── perform ── hardware discovery (Odin)"
if ! command -v odin >/dev/null 2>&1; then
  echo "odin compiler not found in environment"
  exit 1
fi
cd /src/%s
odin run . -file -define:RICE_ATLAS_OUT="%s"
test -s "%s"
echo "atlas.sys generated at %s"
`, runner, atlasOut, atlasOut, atlasOut)
	ctr := withPixi(src)
	ctr = withBash(ctr, script)
	if err := mustSync(ctx, ctr, "perform-odin"); err != nil {
		return err
	}
	if _, err := ctr.Directory("/src").Export(ctx, "."); err != nil {
		return fmt.Errorf("export workspace after perform: %w", err)
	}
	return nil
}
