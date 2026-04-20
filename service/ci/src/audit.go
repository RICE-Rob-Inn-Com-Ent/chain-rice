package main

import (
	"context"
	"fmt"
	"strings"

	"golang.org/x/sync/errgroup"

	"dagger/rice/src/internal/dagger"
)

func formatRun(ctx context.Context, src *dagger.Directory) error {
	ctr := withPixi(src)
	script := `
set -euo pipefail
echo "── format ──"
cue vet infra/configs/*.cue
buf lint infra/schemas/*.proto
bash -lc 'shopt -s globstar nullglob; cd base && rustfmt --check **/*.rs'
bash -lc 'shopt -s globstar nullglob; cd base && fourmolu --mode check **/*.hs'
cd base && zig fmt --check .
cd service && gofmt -l ./...
cd service && mix format --check-formatted
cd frontend/browser && biome format --write=false .
cd frontend/screen && dart format --set-exit-if-changed .
cd frontend/vendor && odin fmt -vet .
cd function && ruff format --check .
vale infra/docs/**/*.md
bash -lc 'shopt -s globstar nullglob; taplo fmt --check **/*.toml'
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "format")
}

func lintRun(ctx context.Context, src *dagger.Directory) error {
	ctr := withPixi(src)
	script := `
set -euo pipefail
echo "── lint ──"
buf breaking --against '.git#branch=main' infra/schemas/*.proto
cd base && cargo clippy -- -D warnings
cd base && hlint .
cd base && zig build
cd service && golangci-lint run
cd service && mix credo --strict
cd frontend/browser && biome lint .
cd frontend/screen && dart analyze
cd function && ruff check .
cd function && basedpyright
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "lint")
}

func testRun(ctx context.Context, src *dagger.Directory) error {
	ctr := withPixi(src)
	script := `
set -euo pipefail
echo "── test ──"
cd base && cargo test
cd base && cargo test base/mint/
cd base && cabal test
cd base && zig build test
cd service && go test ./...
cd service && mix test
cd frontend/browser && bun run vitest
cd frontend/browser && bun run playwright test
cd frontend/screen && flutter test
cd frontend/screen && patrol test
cd function && pytest function/test/
cd function && pytest function/test/ --integration
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "test")
}

func verifyRun(ctx context.Context, src *dagger.Directory) error {
	ctr := withPixi(src)
	script := `
set -euo pipefail
echo "── verify ──"
echo "TODO: restore full verify (secrets, security, penetration, infra gate)"
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "verify")
}

func normalizeGate(a string) string {
	switch strings.ToLower(strings.TrimSpace(a)) {
	case "commit", "release", "deploy", "all", "skip":
		return strings.ToLower(strings.TrimSpace(a))
	default:
		return "skip"
	}
}

// Audit runs format, lint, test, verify in parallel, then optional gate steps.
func (m *Rice) Audit(ctx context.Context) error {
	src := workspaceDir()
	g, ctx := errgroup.WithContext(ctx)
	g.Go(func() error { return formatRun(ctx, src) })
	g.Go(func() error { return lintRun(ctx, src) })
	g.Go(func() error { return testRun(ctx, src) })
	g.Go(func() error { return verifyRun(ctx, src) })
	if err := g.Wait(); err != nil {
		return err
	}
	gate := normalizeGate(getenv("RICE_AUDIT_GATE", "skip"))
	if gate == "skip" {
		return nil
	}
	ctr := withPixi(src)
	ctr = withBash(ctr, fmt.Sprintf(`
set -euo pipefail
echo "── gate (%s) ──"
echo "TODO: wire gate actions for RICE_AUDIT_GATE=%s"
`, gate, gate))
	return mustSync(ctx, ctr, "gate")
}
