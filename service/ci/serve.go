package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func serveScript(project string) string {
	slug := strings.TrimSpace(project)
	return fmt.Sprintf(`
set -euo pipefail
REPO="${RICE_MONO_ROOT:-/src}"
cd "$REPO"
export PATH="$REPO/.pixi/envs/default/bin:/root/.pixi/bin:/usr/local/bin:/usr/bin:${PATH}"
export CHIEF_PROJECT=%q

if [[ ! -f .rice/cache/cook.ok ]]; then
  echo "error: run rice cook %s first" >&2
  exit 1
fi

mkdir -p .rice/cache/serve/%s
OUT="$REPO/.rice/cache/serve/%s"

echo "── serve: release buck build ──"
if command -v buck2 >/dev/null 2>&1; then
  buck2 build //infra/package:validate_package_cue //infra/build:validate_build_cue
fi

DEPLOY_MODE="${RICE_SERVE_MODE:-local}"
if [[ -f custom/%s/infra/terraform.rice ]] && rg -q 'deployMode.*cloud' custom/%s/infra/terraform.rice 2>/dev/null; then
  DEPLOY_MODE=cloud
fi

echo "deploy_mode=${DEPLOY_MODE}" > "${OUT}/serve.env"
echo "project=%s" >> "${OUT}/serve.env"
echo "timestamp=$(date -u +%%FT%%TZ)" >> "${OUT}/serve.env"

if [[ "${DEPLOY_MODE}" = "cloud" && -d .opentofu ]]; then
  cp -a .opentofu "${OUT}/opentofu"
  echo "serve: cloud bundle staged at ${OUT}/opentofu"
else
  echo "serve: local bundle at ${OUT}"
fi

if [[ -f .docker/docker-compose.yml ]]; then
  mkdir -p "${OUT}/docker"
  cp -a .docker "${OUT}/docker"
  if command -v docker >/dev/null 2>&1; then
    docker compose -f .docker/docker-compose.yml build
  fi
fi

if [[ -d custom/%s/frontend ]] && command -v flutter >/dev/null 2>&1; then
  cd "custom/%s/frontend"
  flutter pub get
  flutter build web --release -o "${OUT}/web"
fi

echo ok > "${OUT}/serve.ok"
echo "✅ serve %s complete (${DEPLOY_MODE})"
`, slug, slug, slug, slug, slug, slug, slug, slug, slug, slug)
}

// Serve builds production artifacts for a CHIEF project (after cook).
func (m *Rice) Serve(ctx context.Context, project string) error {
	if strings.TrimSpace(project) == "" {
		return fmt.Errorf("project name required: rice serve <project>")
	}
	if _, err := chiefProjectDir(project); err != nil {
		return err
	}
	src, err := workspaceDir(ctx)
	if err != nil {
		return err
	}
	if err := runPourStep(ctx, "serve", func(stepCtx context.Context) error {
		ctr := withBash(withPixi(src), serveScript(project))
		if err := mustSync(stepCtx, ctr, "serve"); err != nil {
			return err
		}
		return exportWorkspace(stepCtx, ctr)
	}); err != nil {
		return err
	}
	out := filepath.Join(moduleRoot(), ".rice", "cache", "serve", strings.TrimSpace(project), "serve.ok")
	if _, err := os.Stat(out); err != nil {
		return fmt.Errorf("serve did not complete: %w", err)
	}
	fmt.Printf("✅ serve %q complete\n", project)
	return nil
}
