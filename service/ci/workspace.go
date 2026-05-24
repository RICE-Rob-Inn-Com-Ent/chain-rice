package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"dagger/ci/internal/dagger"
)

const (
	riceWorkspaceMount = "/src"
	riceDevImage       = "ubuntu:24.04"
)

// Rice is the Dagger module type for SMITH CI (pour, perform, forge, think, audit, prepare, cook, serve, pipeline).
type Rice struct{}

func moduleRoot() string {
	if r := strings.TrimSpace(os.Getenv("DAGGER_HOST_LOCAL_REPO")); r != "" {
		return r
	}
	wd, err := os.Getwd()
	if err != nil {
		return "."
	}
	dir, _ := filepath.Abs(wd)
	for {
		if _, err := os.Stat(filepath.Join(dir, "dagger.json")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return wd
		}
		dir = parent
	}
}

func workspaceDir(ctx context.Context) (*dagger.Directory, error) {
	_ = ctx
	return dag.CurrentModule().Source().Directory("../.."), nil
}

// Bootstrap order (no chicken-and-egg):
//   1) Odin only  → rice perform / body scan (no pixi, no pour.ok)
//   2) Odin + body → sync pixi.toml for this machine
//   3) pixi install → cue, buf, …
//   4) cue emit (pour) → body again re-syncs platforms after CUE overwrite
const (
	odinSDKRoot       = "/opt/odin-sdk"
	odinPathSnippet   = `
ODIN_SDK="` + odinSDKRoot + `"

use_odin_sdk() {
  if [[ -d "$ODIN_SDK/base" && -x "$ODIN_SDK/odin" ]]; then
    export ODIN_ROOT="$ODIN_SDK"
    export PATH="$ODIN_ROOT:$PATH"
    return 0
  fi
  return 1
}

build_odin() {
  if use_odin_sdk; then
    return 0
  fi
  apt-get update -qq
  apt-get install -y -qq git curl ca-certificates build-essential clang llvm
  if [[ ! -d /tmp/Odin/.git ]]; then
    git clone --depth 1 https://github.com/odin-lang/Odin.git /tmp/Odin
  fi
  make -C /tmp/Odin release
  rm -rf "$ODIN_SDK"
  mkdir -p "$ODIN_SDK"
  cp -a /tmp/Odin/. "$ODIN_SDK/"
  use_odin_sdk
  odin version
}
`

	bodyOdinSnippet = `
# Atlas scan (BARD perform) — no pixi.toml changes on rice perform.
run_body_atlas() {
  build_odin
  cd /src/frontend/inventory/perform
  export RICE_ATLAS_OUT=/src/atlas.sys
  odin build . -file -o:none
  ./perform
  cd /src
  test -s /src/atlas.sys
}

# Full body (atlas + pixi platform) for rice pour bootstrap only.
run_body_full() {
  build_odin
  cd /src/frontend/inventory
  export RICE_MONO_ROOT=/src
  export RICE_ATLAS_OUT=/src/atlas.sys
  odin run body_main.odin -file || run_body_atlas
  cd /src
}
`

	odinBootstrapScript = `
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
` + odinPathSnippet + bodyOdinSnippet + `
build_odin
run_body_atlas
echo "odin bootstrap complete"
`

	pixiBootstrapScript = `
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export PATH="/root/.pixi/bin:` + odinSDKRoot + `:/src/infra/bootstrap/.pixi/envs/default/bin:/src/.pixi/envs/default/bin:${PATH}"
` + odinPathSnippet + bodyOdinSnippet + `

install_pixi_tools() {
  if ! command -v pixi >/dev/null 2>&1; then
    curl -fsSL https://pixi.sh/install.sh | bash
  fi
  export PATH="/root/.pixi/bin:${PATH}"
  cd /src/infra/bootstrap
  pixi install --locked
  export PATH="/src/infra/bootstrap/.pixi/envs/default/bin:${PATH}"
  cd /src
  if [[ -f /src/pixi.lock ]] && pixi lock --check 2>/dev/null; then
    pixi install --locked || true
  fi
}

# Fast path: bootstrap pixi env exists — still run body (pixi.toml may have changed).
if [[ -x /src/infra/bootstrap/.pixi/envs/default/bin/cue ]] || [[ -x /src/.pixi/envs/default/bin/cue ]]; then
  run_body_full
  install_pixi_tools
  echo "pixi env ready (body re-synced)"
  exit 0
fi

apt-get update -qq
apt-get install -y -qq git curl ca-certificates ripgrep zstd build-essential pkg-config clang llvm
build_odin
run_body_full

install_pixi_tools
pixi run build-rice-lsp 2>/dev/null || true
echo "pixi bootstrap complete"
`
)

func baseContainer(src *dagger.Directory) *dagger.Container {
	return dag.Container().
		From(riceDevImage).
		WithMountedDirectory(riceWorkspaceMount, src).
		WithWorkdir(riceWorkspaceMount).
		WithEnvVariable("RICE_MONO_ROOT", riceWorkspaceMount).
		WithEnvVariable("HOME", "/root")
}

// withOdin — BARD body only (atlas.sys + pixi.toml). No pixi, no pour.ok.
func withOdin(src *dagger.Directory) *dagger.Container {
	path := odinSDKRoot + ":/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	return baseContainer(src).
		WithEnvVariable("ODIN_ROOT", odinSDKRoot).
		WithEnvVariable("PATH", path).
		WithExec([]string{"bash", "-lc", odinBootstrapScript})
}

// withPixi — Odin body then pixi install (or body-only refresh if .pixi already exists).
func withPixi(src *dagger.Directory) *dagger.Container {
	path := riceWorkspaceMount + "/.pixi/envs/default/bin:/root/.pixi/bin:" + odinSDKRoot + ":/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	return baseContainer(src).
		WithEnvVariable("ODIN_ROOT", odinSDKRoot).
		WithEnvVariable("PATH", path).
		WithExec([]string{"bash", "-lc", pixiBootstrapScript})
}

func chiefProjectDir(project string) (string, error) {
	p := strings.TrimSpace(project)
	if p == "" {
		return "", fmt.Errorf("project name required")
	}
	root := moduleRoot()
	for _, candidate := range []string{
		filepath.Join(root, "custom", p),
		filepath.Join(root, "custom", strings.ToLower(p)),
	} {
		if st, err := os.Stat(candidate); err == nil && st.IsDir() {
			if _, err := os.Stat(filepath.Join(candidate, "bowl")); err == nil {
				return candidate, nil
			}
		}
	}
	return "", fmt.Errorf("CHIEF project not found under custom/: %q (need bowl)", p)
}

func withBash(ctr *dagger.Container, script string) *dagger.Container {
	return ctr.WithExec([]string{"bash", "-euo", "pipefail", "-c", script})
}

func mustSync(ctx context.Context, ctr *dagger.Container, step string) error {
	if _, err := ctr.Stdout(ctx); err != nil {
		return fmt.Errorf("%s: %w", step, err)
	}
	return nil
}

func runBash(ctx context.Context, src *dagger.Directory, step, script string) error {
	wrapped := fmt.Sprintf(`set -euo pipefail
export RICE_MONO_ROOT=%q
export PATH="/root/.pixi/bin:` + odinSDKRoot + `:%s/.pixi/envs/default/bin:/usr/local/bin:/usr/bin:/bin"
export ODIN_ROOT="` + odinSDKRoot + `"
cd "$RICE_MONO_ROOT"
%s`, riceWorkspaceMount, riceWorkspaceMount, script)
	ctr := withBash(withPixi(src), wrapped)
	return mustSync(ctx, ctr, step)
}

func exportWorkspace(ctx context.Context, ctr *dagger.Container) error {
	if _, err := ctr.Directory(riceWorkspaceMount).Export(ctx, "."); err != nil {
		return fmt.Errorf("export workspace: %w", err)
	}
	return nil
}

func runPourStep(ctx context.Context, name string, fn func(context.Context) error) error {
	fmt.Printf("▶ %s\n", name)
	if err := fn(ctx); err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

func getenv(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func checkLocalReplaceDeps(root string) error {
	_ = root
	return nil
}

func runConnectivityChecks(ctx context.Context) error {
	_ = ctx
	return nil
}

func defaultChiefProjects() []string {
	raw := strings.TrimSpace(getenv("RICE_CHIEF_PROJECTS", "code-rice.com egos.app"))
	return strings.Fields(raw)
}
