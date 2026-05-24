package main

import (
	"context"
	"fmt"

	"golang.org/x/sync/errgroup"
)

func forgeScriptBootstrap() string {
	return `
set -euo pipefail
mkdir -p /src/.rice/cache

if [ ! -s /src/atlas.sys ]; then
  cat > /src/atlas.sys <<'EOF'
schema=atlas.sys.v1
format=manifest
os=unknown

[Touch]
count=0

[Ears]
count=0

[Eyes]
count=0

[Perception]
count=0

[Motion]
count=0
EOF
fi
`
}

func forgeScriptDependencies() string {
	return `
set -euo pipefail
echo "── forge: dependency injection ──"
if command -v go >/dev/null 2>&1; then
  [ -f /src/service/go.mod ] && (cd /src/service && go mod download)
  [ -f /src/service/ci/go.mod ] && (cd /src/service/ci && go mod download)
fi
if command -v mix >/dev/null 2>&1 && [ -f /src/service/mix.exs ]; then
  (cd /src/service && mix local.hex --force && mix local.rebar --force && mix deps.get)
fi
if command -v bundle >/dev/null 2>&1; then
  [ -f /src/frontend/Gemfile ] && (cd /src/frontend && bundle install)
  [ -f /src/Gemfile ] && (cd /src && bundle install)
fi
`
}

func forgeScriptBuckBuild() string {
	return `
set -euo pipefail
echo "── forge: buck2 ignition ──"
if ! command -v buck2 >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq zstd curl ca-certificates
  curl --proto '=https' --tlsv1.2 -sSfL https://github.com/facebook/buck2/releases/latest/download/buck2-x86_64-unknown-linux-musl.zst | zstd -d -o /usr/local/bin/buck2
  chmod +x /usr/local/bin/buck2
fi
BUCK_COUNT="$(rg --files /src -g '**/BUCK' -g '**/BUCK.v2' | wc -l | tr -d ' ')"
echo "discovered ${BUCK_COUNT} BUCK files"
if [ "${BUCK_COUNT}" = "0" ]; then
  echo "no BUCK files found; skipping buck2 build"
  exit 0
fi
cd /src
buck2 build //...
`
}

func forgeScriptContainerIgnition() string {
	return `
set -euo pipefail
echo "── forge: container ignition ──"
cd /src

compose_bin=""
if command -v docker >/dev/null 2>&1; then
  compose_bin="docker compose"
elif command -v podman >/dev/null 2>&1; then
  if command -v podman-compose >/dev/null 2>&1; then
    compose_bin="podman-compose"
  else
    compose_bin="podman compose"
  fi
fi
if [ -z "${compose_bin}" ]; then
  echo "neither docker nor podman found on host"
  exit 1
fi

compose_file="${RICE_COMPOSE_FILE:-docker-compose.yml}"
if [ ! -f "${compose_file}" ]; then
  echo "compose file not found: ${compose_file}"
  exit 1
fi

override="/src/.rice/cache/compose.atlas.override.yml"
services="$(${compose_bin} -f "${compose_file}" config --services || true)"
{
  echo "services:"
  for svc in ${services}; do
    echo "  ${svc}:"
    echo "    volumes:"
    echo "      - /src/atlas.sys:/workspace/atlas.sys:ro"
  done
} > "${override}"

${compose_bin} -f "${compose_file}" -f "${override}" up -d --remove-orphans
echo "${compose_bin}" > /src/.rice/cache/compose.bin
`
}

func forgeScriptLogsAndWatch() string {
	return `
set -euo pipefail
echo "── forge: log dashboard + hot reload ──"
cd /src
compose_bin="$(cat /src/.rice/cache/compose.bin)"
compose_file="${RICE_COMPOSE_FILE:-docker-compose.yml}"

log_script="/src/.rice/cache/forge-logs.sh"
cat > "${log_script}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd /src
compose_bin="$(cat /src/.rice/cache/compose.bin)"
compose_file="${RICE_COMPOSE_FILE:-docker-compose.yml}"
exec ${compose_bin} -f "${compose_file}" logs -f --timestamps
EOF
chmod +x "${log_script}"

if [ -f /src/.rice/cache/forge-logs.pid ] && kill -0 "$(cat /src/.rice/cache/forge-logs.pid)" 2>/dev/null; then
  echo "log stream already running (pid $(cat /src/.rice/cache/forge-logs.pid))"
else
  nohup "${log_script}" > /src/.rice/cache/forge-dashboard.log 2>&1 &
  echo $! > /src/.rice/cache/forge-logs.pid
fi

if [ "${RICE_FORGE_WATCH:-true}" != "true" ]; then
  echo "watch mode disabled via RICE_FORGE_WATCH=false"
  exit 0
fi

watch_script="/src/.rice/cache/forge-watch.sh"
cat > "${watch_script}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd /src
compose_bin="$(cat /src/.rice/cache/compose.bin)"
compose_file="${RICE_COMPOSE_FILE:-docker-compose.yml}"
echo "watching repo for hot reload..."
if command -v inotifywait >/dev/null 2>&1; then
  while inotifywait -r -e close_write,create,move,delete \
    --exclude '(^|/)\.git/|(^|/)buck-out/|(^|/)node_modules/|(^|/)\.rice/cache/' /src; do
    buck2 build //... || true
    ${compose_bin} -f "${compose_file}" up -d --remove-orphans || true
  done
else
  last=""
  while true; do
    now="$(rg --files /src -g '!**/.git/**' -g '!**/buck-out/**' -g '!**/node_modules/**' -g '!**/.rice/cache/**' | xargs stat -c '%n:%Y' 2>/dev/null | sha256sum | awk '{print $1}')"
    if [ "${now}" != "${last}" ]; then
      last="${now}"
      buck2 build //... || true
      ${compose_bin} -f "${compose_file}" up -d --remove-orphans || true
    fi
    sleep 2
  done
fi
EOF
chmod +x "${watch_script}"

if [ -f /src/.rice/cache/forge-watch.pid ] && kill -0 "$(cat /src/.rice/cache/forge-watch.pid)" 2>/dev/null; then
  echo "watch already running (pid $(cat /src/.rice/cache/forge-watch.pid))"
else
  nohup "${watch_script}" > /src/.rice/cache/forge-watch.log 2>&1 &
  echo $! > /src/.rice/cache/forge-watch.pid
fi
`
}

// Forge ignites the hydrated repository: builds artifacts, injects runtime deps,
// lifts containers with atlas context, and starts global hot reload and logs.
func (m *Rice) Forge(ctx context.Context) error {
	src, err := workspaceDir()
	if err != nil {
		return err
	}

	if err := runPourStep(ctx, "forge-bootstrap", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "forge-bootstrap", forgeScriptBootstrap())
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "forge-parallel-build-and-deps", func(stepCtx context.Context) error {
		g, egCtx := errgroup.WithContext(stepCtx)
		g.Go(func() error { return runBash(egCtx, src, "forge-dependencies", forgeScriptDependencies()) })
		g.Go(func() error { return runBash(egCtx, src, "forge-buck2-build", forgeScriptBuckBuild()) })
		return g.Wait()
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "forge-container-ignition", func(stepCtx context.Context) error {
		ctr := withPixi(src)
		ctr = withBashPrivileged(ctr, forgeScriptContainerIgnition())
		return mustSync(stepCtx, ctr, "forge-container-ignition")
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "forge-hot-reload-and-dashboard", func(stepCtx context.Context) error {
		ctr := withPixi(src)
		ctr = withBashPrivileged(ctr, forgeScriptLogsAndWatch())
		return mustSync(stepCtx, ctr, "forge-hot-reload-and-dashboard")
	}); err != nil {
		return err
	}

	ctr := withPixi(src)
	ctr = withBash(ctr, `set -euo pipefail; echo "✅ forge ignition complete"`)
	if err := mustSync(ctx, ctr, "forge-finalize"); err != nil {
		return err
	}
	if _, err := ctr.Directory("/src").Export(ctx, "."); err != nil {
		return fmt.Errorf("export workspace after forge: %w", err)
	}
	return nil
}
