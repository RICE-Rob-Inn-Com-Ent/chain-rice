package ci

import (
	"context"
	"fmt"
	"os"
	"strings"

	"dagger/rice/src/internal/dagger"
)

// Rice is the module root type; methods become `dagger call <method>`.
type Rice struct{}

const pixiImage = "ghcr.io/prefix-dev/pixi:latest"

func withPixi(src *dagger.Directory) *dagger.Container {
	return dag.Container().From(pixiImage).
		WithMountedDirectory("/src", src).
		WithWorkdir("/src").
		WithEnvVariable("DEBIAN_FRONTEND", "noninteractive").
		WithExec([]string{"pixi", "install", "-y"})
}

func withBash(ctr *dagger.Container, script string) *dagger.Container {
	return ctr.WithExec([]string{"bash", "-euo", "pipefail", "-c", script})
}

func withBashPrivileged(ctr *dagger.Container, script string) *dagger.Container {
	return ctr.WithExec([]string{"bash", "-euo", "pipefail", "-c", script}, dagger.ContainerWithExecOpts{
		ExperimentalPrivilegedNesting: true,
	})
}

func workspaceDir() *dagger.Directory {
	return dag.CurrentModule().Source()
}

func getenv(key, def string) string {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	return v
}

func mustSync(ctx context.Context, ctr *dagger.Container, label string) error {
	_, err := ctr.Sync(ctx)
	if err != nil {
		return fmt.Errorf("%s: %w", label, err)
	}
	return nil
}

// Pour installs toolchains (pixi), exports CUE, generates protos, syncs language deps,
// runs CLERK hpack layout, writes MASON .envrc from CUE, and BARD hardware placeholder.
func (m *Rice) Pour(ctx context.Context) error {
	src := workspaceDir()
	ctr := withPixi(src)
	script := `
set -euo pipefail
echo "── pour ── (restore full pipeline from MASON CUE when wired)"
echo "TODO: cue export, buf generate, mix deps, rice pour steps"
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "pour")
}
