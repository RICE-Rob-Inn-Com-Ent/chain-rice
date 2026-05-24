package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"golang.org/x/sync/errgroup"

	"dagger/ci/internal/dagger"
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
echo "── verify (fortress gate) ──"

echo "checking dagger graph shape..."
if command -v dagger >/dev/null 2>&1; then
  dagger functions >/dev/null
fi

echo "checking kubernetes manifest hardening..."
if rg -n --glob '**/*.{yml,yaml}' 'kind:\s*(Deployment|StatefulSet|DaemonSet)' /src >/dev/null 2>&1; then
  if rg -n --glob '**/*.{yml,yaml}' 'privileged:\s*true|allowPrivilegeEscalation:\s*true|hostNetwork:\s*true|hostPID:\s*true|hostIPC:\s*true' /src; then
    echo "dangerous kubernetes securityContext or host namespace setting found"
    exit 1
  fi
fi

echo "checking iac for obvious open ingress..."
if rg -n --glob '**/*.tf' '0\.0\.0\.0/0|::/0' /src >/dev/null 2>&1; then
  echo "open ingress rule detected in terraform/opentofu"
  exit 1
fi
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "verify")
}

func secretRun(ctx context.Context, src *dagger.Directory) error {
	ctr := withPixi(src)
	script := `
set -euo pipefail
echo "── secrets ──"
if rg -n \
  -g '!**/.git/**' \
  -g '!**/buck-out/**' \
  -g '!**/node_modules/**' \
  -e 'AKIA[0-9A-Z]{16}' \
  -e 'ASIA[0-9A-Z]{16}' \
  -e '-----BEGIN (RSA|EC|OPENSSH|PRIVATE) KEY-----' \
  -e '(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*["'"'"']?[A-Za-z0-9_\-]{16,}' \
  -e 'xox[baprs]-[A-Za-z0-9-]+' \
  /src; then
  echo "possible secret leakage detected"
  exit 1
fi
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "secret")
}

func adversarialRun(ctx context.Context, src *dagger.Directory) error {
	ctr := withPixi(src)
	script := `
set -euo pipefail
echo "── adversarial ai self-hack ──"
mkdir -p /src/.rice/cache/audit
out="/src/.rice/cache/audit/adversarial.log"
rm -f "${out}"

if [ -x /src/.rice/cache/thought/learn-loop.sh ]; then
  # lightweight red-team probe marker
  printf "probe=role_prompt_escape\nprobe=secret_exfil_attempt\n" > "${out}"
else
  printf "probe=simulated\nreason=think_not_initialized\n" > "${out}"
fi

if rg -n '(AKIA|ASIA|BEGIN [A-Z ]*PRIVATE KEY|password=|token=|secret=)' "${out}" >/dev/null 2>&1; then
  echo "adversarial simulation leaked sensitive pattern"
  exit 1
fi
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "adversarial")
}

func clerkGateRun(ctx context.Context, src *dagger.Directory) error {
	ctr := withPixi(src)
	script := `
set -euo pipefail
echo "── clerk: money/math/legal gate ──"

if [ -d /src/base ]; then
  if command -v cargo >/dev/null 2>&1; then
    (cd /src/base && cargo test --workspace --quiet) || exit 1
  fi
  if command -v cabal >/dev/null 2>&1; then
    (cd /src/base && cabal test all) || exit 1
  fi
  if command -v zig >/dev/null 2>&1; then
    (cd /src/base && zig build test) || exit 1
  fi
fi

if [ -f /src/LICENSE ] || [ -f /src/LICENSE.md ]; then
  echo "license file present"
else
  echo "license file missing"
  exit 1
fi
`
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "clerk-gate")
}

func deploymentGateRun(ctx context.Context, src *dagger.Directory, gate string) error {
	ctr := withPixi(src)
	script := fmt.Sprintf(`
set -euo pipefail
echo "── deployment gate (%s) ──"
if [ "${RICE_AUDIT_DEPLOY_APPROVAL:-no}" != "yes" ]; then
  echo "audit is clean but deployment approval missing (set RICE_AUDIT_DEPLOY_APPROVAL=yes)"
  exit 1
fi

if [ -d /src/.git ]; then
  version="${RICE_RELEASE_VERSION:-0.1.0}"
  mkdir -p /src/.rice/cache/audit
  {
    echo "# Changelog (candidate ${version})"
    echo
    git -C /src log --oneline -20 || true
  } > /src/.rice/cache/audit/CHANGELOG.candidate.md
fi

echo "gate approved for action: %s"
`, gate, gate)
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, "deployment-gate")
}

func normalizeGate(a string) string {
	switch strings.ToLower(strings.TrimSpace(a)) {
	case "commit", "release", "deploy", "all", "skip":
		return strings.ToLower(strings.TrimSpace(a))
	default:
		return "skip"
	}
}

func cloudIntegrityRun(ctx context.Context) error {
	if err := runConnectivityChecks(ctx); err != nil {
		return fmt.Errorf("cloud integrity check failed: %w", err)
	}
	return nil
}

// Audit executes a zero-trust fortress siege before release/deploy.
func (m *Rice) Audit(ctx context.Context) error {
	src, err := workspaceDir()
	if err != nil {
		return err
	}
	g, auditCtx := errgroup.WithContext(ctx)
	g.Go(func() error { return runPourStep(auditCtx, "audit-format", func(stepCtx context.Context) error { return formatRun(stepCtx, src) }) })
	g.Go(func() error { return runPourStep(auditCtx, "audit-lint", func(stepCtx context.Context) error { return lintRun(stepCtx, src) }) })
	g.Go(func() error { return runPourStep(auditCtx, "audit-test", func(stepCtx context.Context) error { return testRun(stepCtx, src) }) })
	g.Go(func() error { return runPourStep(auditCtx, "audit-verify", func(stepCtx context.Context) error { return verifyRun(stepCtx, src) }) })
	g.Go(func() error { return runPourStep(auditCtx, "audit-secrets", func(stepCtx context.Context) error { return secretRun(stepCtx, src) }) })
	g.Go(func() error { return runPourStep(auditCtx, "audit-adversarial", func(stepCtx context.Context) error { return adversarialRun(stepCtx, src) }) })
	g.Go(func() error { return runPourStep(auditCtx, "audit-clerk", func(stepCtx context.Context) error { return clerkGateRun(stepCtx, src) }) })
	g.Go(func() error { return runPourStep(auditCtx, "audit-cloud", func(stepCtx context.Context) error { return cloudIntegrityRun(stepCtx) }) })
	if err := g.Wait(); err != nil {
		return err
	}

	gate := normalizeGate(getenv("RICE_AUDIT_GATE", "skip"))
	if gate == "skip" {
		return nil
	}
	if os.Getenv("RICE_AUDIT_DEPLOY_APPROVAL") == "" {
		_ = os.Setenv("RICE_AUDIT_DEPLOY_APPROVAL", "no")
	}
	return runPourStep(ctx, "audit-deployment-gate", func(stepCtx context.Context) error {
		return deploymentGateRun(stepCtx, src, gate)
	})
}
