package main

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"dagger/ci/internal/dagger"
	"go.opentelemetry.io/otel/attribute"
	"golang.org/x/sync/errgroup"
)

// Pixi runs in a Docker Hub base image + binary from GitHub Releases so `rice pour`
// does not depend on anonymous pulls from ghcr.io (often 403 behind strict networks).
const pixiBaseImage = "docker.io/library/debian:bookworm-slim"

const installPixiScript = `
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl
arch=$(uname -m)
case "$arch" in
  x86_64) u="pixi-x86_64-unknown-linux-musl.tar.gz" ;;
  aarch64) u="pixi-aarch64-unknown-linux-musl.tar.gz" ;;
  *) echo "unsupported architecture for pixi bootstrap: $arch" >&2; exit 1 ;;
esac
curl -fsSL "https://github.com/prefix-dev/pixi/releases/latest/download/${u}" | tar xz -C /usr/local/bin
chmod +x /usr/local/bin/pixi
cd /src
exec pixi install --manifest-path /src/pixi.toml
`

// Rice is the Dagger module root type.
type Rice struct{}

func withPixi(src *dagger.Directory) *dagger.Container {
	return dag.Container().From(pixiBaseImage).
		WithMountedDirectory("/src", src).
		WithWorkdir("/src").
		WithEnvVariable("DEBIAN_FRONTEND", "noninteractive").
		WithExec([]string{"bash", "-euo", "pipefail", "-c", installPixiScript})
}

func withBash(ctr *dagger.Container, script string) *dagger.Container {
	return ctr.WithExec([]string{"bash", "-euo", "pipefail", "-c", script})
}

func withBashPrivileged(ctr *dagger.Container, script string) *dagger.Container {
	return ctr.WithExec([]string{"bash", "-euo", "pipefail", "-c", script}, dagger.ContainerWithExecOpts{
		ExperimentalPrivilegedNesting: true,
	})
}

// workspaceDir is the module context (dagger.json root + include). We overlay the
// monorepo root pixi.toml and pixi.lock (Go embed cannot use .. paths outside this package).
func workspaceDir() (*dagger.Directory, error) {
	root := moduleRoot()
	tomlPath := filepath.Join(root, "pixi.toml")
	lockPath := filepath.Join(root, "pixi.lock")
	toml, err := os.ReadFile(tomlPath)
	if err != nil {
		return nil, fmt.Errorf("read root pixi.toml: %w", err)
	}
	lock, err := os.ReadFile(lockPath)
	if err != nil {
		return nil, fmt.Errorf("read root pixi.lock: %w", err)
	}
	base := dag.ModuleSource(".").ContextDirectory().
		WithNewFile("pixi.toml", string(toml)).
		WithNewFile("pixi.lock", string(lock))
	return base, nil
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

func moduleRoot() string {
	wd, err := os.Getwd()
	if err != nil {
		return "."
	}
	// Monorepo root: has pixi.toml and service/bench (go replace targets), not only service/ci.
	for d := wd; ; d = filepath.Dir(d) {
		pixi := filepath.Join(d, "pixi.toml")
		bench := filepath.Join(d, "service", "bench")
		if st, e := os.Stat(pixi); e == nil && !st.IsDir() {
			if st2, e2 := os.Stat(bench); e2 == nil && st2.IsDir() {
				return d
			}
		}
		parent := filepath.Dir(d)
		if parent == d {
			break
		}
	}
	return wd
}

func hasAnyGlob(root string, globs ...string) bool {
	for _, pattern := range globs {
		matches, err := filepath.Glob(filepath.Join(root, pattern))
		if err == nil && len(matches) > 0 {
			return true
		}
	}
	return false
}

func runBash(ctx context.Context, src *dagger.Directory, label, script string) error {
	ctr := withPixi(src)
	ctr = withBash(ctr, script)
	return mustSync(ctx, ctr, label)
}

func copyFile(src, dst string, mode os.FileMode) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	out, err := os.OpenFile(dst, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, mode)
	if err != nil {
		return err
	}
	defer out.Close()
	if _, err := io.Copy(out, in); err != nil {
		return err
	}
	return nil
}

func targetForGenerated(rel string) (string, bool) {
	parts := strings.Split(filepath.ToSlash(rel), "/")
	if len(parts) == 0 {
		return "", false
	}
	switch parts[0] {
	case "base", "custom", "frontend", "function", "infra", "service":
		return filepath.Join(parts...), true
	case "root":
		return filepath.Join(parts[1:]...), true
	default:
		return filepath.Join(parts...), true
	}
}

func redistributeGenerated(root string) error {
	sources := []string{
		filepath.Join(root, "infra", "package"),
		filepath.Join(root, "infra", "out"),
	}
	for _, srcBase := range sources {
		stat, err := os.Stat(srcBase)
		if err != nil || !stat.IsDir() {
			continue
		}
		err = filepath.WalkDir(srcBase, func(path string, d os.DirEntry, walkErr error) error {
			if walkErr != nil {
				return walkErr
			}
			if d.IsDir() {
				return nil
			}
			rel, err := filepath.Rel(srcBase, path)
			if err != nil {
				return err
			}
			target, ok := targetForGenerated(rel)
			if !ok {
				return nil
			}
			info, err := d.Info()
			if err != nil {
				return err
			}
			return copyFile(path, filepath.Join(root, target), info.Mode())
		})
		if err != nil {
			return err
		}
	}
	return nil
}

func checkLocalReplaceDeps(root string) error {
	// Monorepo-only check: Dagger's module runtime tree may omit sibling packages
	// even though host builds resolve go.mod replace directives.
	if _, err := os.Stat(filepath.Join(root, "pixi.toml")); err != nil {
		return nil
	}
	required := []string{
		filepath.Join(root, "service", "bench"),
		filepath.Join(root, "service", "kit"),
	}
	for _, p := range required {
		info, err := os.Stat(p)
		if err != nil || !info.IsDir() {
			return fmt.Errorf("local replace dependency not found: %s", p)
		}
	}
	return nil
}

func synthViaBuck2(ctx context.Context, src *dagger.Directory, kind string) error {
	var targetHint string
	switch kind {
	case "docker":
		targetHint = "Dockerfile"
	case "tofu":
		targetHint = ".tf"
	case "k8s":
		targetHint = ".yaml/.yml"
	default:
		targetHint = kind
	}
	script := fmt.Sprintf(`
set -euo pipefail
echo "── buck2 synth (%s) ──"
command -v buck2 >/dev/null 2>&1 || {
  apt-get update -qq
  apt-get install -y -qq zstd curl ca-certificates
  curl --proto '=https' --tlsv1.2 -sSfL https://github.com/facebook/buck2/releases/latest/download/buck2-x86_64-unknown-linux-musl.zst | zstd -d -o /usr/local/bin/buck2
  chmod +x /usr/local/bin/buck2
}
buck2 build //...
mkdir -p "infra/out/%s"
python3 - <<'PY'
import os, shutil
root = "/src"
out = os.path.join(root, "infra", "out", "%s")
os.makedirs(out, exist_ok=True)
for dirpath, _, files in os.walk(os.path.join(root, "buck-out")):
    for name in files:
        low = name.lower()
        src = os.path.join(dirpath, name)
        take = False
        if "%s" == "docker":
            take = low == "dockerfile" or low.endswith(".dockerfile")
        elif "%s" == "tofu":
            take = low.endswith(".tf")
        elif "%s" == "k8s":
            take = low.endswith(".yaml") or low.endswith(".yml")
        if take:
            dst = os.path.join(out, name)
            if os.path.exists(dst):
                base, ext = os.path.splitext(name)
                i = 1
                while os.path.exists(dst):
                    dst = os.path.join(out, f"{base}-{i}{ext}")
                    i += 1
            shutil.copy2(src, dst)
PY
echo "synthesized %s artifacts (%s)"
`, kind, kind, kind, kind, kind, kind, kind, targetHint)
	return runBash(ctx, src, "buck2-synth-"+kind, script)
}

func generateDocsIndex(root string) error {
	docsOut := filepath.Join(root, ".rice", "cache", "docs")
	if err := os.MkdirAll(docsOut, 0o755); err != nil {
		return err
	}
	var docs []string
	err := filepath.WalkDir(root, func(path string, d os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if d.IsDir() {
			base := filepath.Base(path)
			if base == ".git" || base == "node_modules" || base == "buck-out" || strings.HasPrefix(path, filepath.Join(root, ".rice")) {
				return filepath.SkipDir
			}
			return nil
		}
		if strings.HasSuffix(strings.ToLower(d.Name()), ".md") {
			rel, err := filepath.Rel(root, path)
			if err != nil {
				return err
			}
			docs = append(docs, filepath.ToSlash(rel))
		}
		return nil
	})
	if err != nil {
		return err
	}
	sort.Strings(docs)
	var b strings.Builder
	b.WriteString("# Project Documentation Index\n\n")
	for _, d := range docs {
		b.WriteString("- [" + d + "](" + d + ")\n")
	}
	return os.WriteFile(filepath.Join(docsOut, "INDEX.md"), []byte(b.String()), 0o644)
}

func shouldCheckCloud(kind string) bool {
	switch kind {
	case "aws":
		return strings.TrimSpace(os.Getenv("AWS_ACCESS_KEY_ID")) != "" || strings.TrimSpace(os.Getenv("AWS_PROFILE")) != ""
	case "gcp":
		return strings.TrimSpace(os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")) != "" || strings.TrimSpace(os.Getenv("GCP_PROJECT")) != ""
	case "azure":
		return strings.TrimSpace(os.Getenv("AZURE_TENANT_ID")) != "" || strings.TrimSpace(os.Getenv("AZURE_CLIENT_ID")) != ""
	default:
		return false
	}
}

func hostFromEndpoint(raw string) string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return ""
	}
	if strings.Contains(raw, "://") {
		if u, err := url.Parse(raw); err == nil {
			return u.Host
		}
	}
	return raw
}

func checkHTTP(ctx context.Context, endpoint string) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return err
	}
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 500 {
		return fmt.Errorf("unhealthy status: %d", resp.StatusCode)
	}
	return nil
}

func checkTCP(addr string) error {
	conn, err := net.DialTimeout("tcp", addr, 5*time.Second)
	if err != nil {
		return err
	}
	return conn.Close()
}

func runConnectivityChecks(ctx context.Context) error {
	var checks []struct {
		name string
		fn   func() error
	}
	if shouldCheckCloud("aws") {
		checks = append(checks, struct {
			name string
			fn   func() error
		}{name: "aws", fn: func() error { return checkHTTP(ctx, "https://sts.amazonaws.com") }})
	}
	if shouldCheckCloud("gcp") {
		checks = append(checks, struct {
			name string
			fn   func() error
		}{name: "gcp", fn: func() error { return checkHTTP(ctx, "https://storage.googleapis.com") }})
	}
	if shouldCheckCloud("azure") {
		checks = append(checks, struct {
			name string
			fn   func() error
		}{name: "azure", fn: func() error { return checkHTTP(ctx, "https://management.azure.com") }})
	}
	if trino := hostFromEndpoint(getenv("TRINO_ENDPOINT", "")); trino != "" {
		checks = append(checks, struct {
			name string
			fn   func() error
		}{name: "trino", fn: func() error { return checkTCP(trino) }})
	}
	if otelEP := hostFromEndpoint(getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "")); otelEP != "" {
		checks = append(checks, struct {
			name string
			fn   func() error
		}{name: "otel-collector", fn: func() error { return checkTCP(otelEP) }})
	}
	var failed []string
	for _, c := range checks {
		if err := c.fn(); err != nil {
			failed = append(failed, fmt.Sprintf("%s (%v)", c.name, err))
		}
	}
	if len(failed) > 0 {
		return fmt.Errorf("connectivity checks failed: %s", strings.Join(failed, ", "))
	}
	return nil
}

func runPourStep(ctx context.Context, name string, fn func(context.Context) error) error {
	tr := Tracer()
	stepCtx, span := tr.Start(ctx, "rice.pour."+name)
	defer span.End()
	span.SetAttributes(attribute.String("step", name))
	if err := fn(stepCtx); err != nil {
		span.RecordError(err)
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

// Pour hydrates the monorepo from infra templates and generated artifacts.
// MASON emit / workspace CUE / mint overlay run here (not as root pixi [tasks]).
func (m *Rice) Pour(ctx context.Context) error {
	root := moduleRoot()
	src, err := workspaceDir()
	if err != nil {
		return err
	}
	if err := runPourStep(ctx, "validate-local-replaces", func(context.Context) error {
		return checkLocalReplaceDeps(root)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "mason-cue-export", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "cue-export", `
set -euo pipefail
mkdir -p .rice/cache/mason
cue export ./infra/... > .rice/cache/mason/config.json
`)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "mason-cue-emit", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "mason-cue-emit", `
set -euo pipefail
cue cmd emit ./infra/out/_tool.cue
`)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "mason-gen-workspace-cue", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "mason-gen-workspace-cue", `
set -euo pipefail
command -v buck2 >/dev/null 2>&1 || {
  apt-get update -qq
  apt-get install -y -qq zstd curl ca-certificates
  curl --proto '=https' --tlsv1.2 -sSfL https://github.com/facebook/buck2/releases/latest/download/buck2-x86_64-unknown-linux-musl.zst | zstd -d -o /usr/local/bin/buck2
  chmod +x /usr/local/bin/buck2
}
buck2 build //infra/out:gen_workspace_cue
`)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "mason-overlay-schema", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "mason-overlay-schema", `
set -euo pipefail
bash ./infra/scripts/mason-overlay-terraform-keys.sh ./infra/mint/overlay-schema
`)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "mason-overlay-check", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "mason-overlay-check", `
set -euo pipefail
cd base && cargo run -p mint --bin mint_overlay_check
`)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "redistribute-generated", func(context.Context) error {
		return redistributeGenerated(root)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "buck2-parallel-synth", func(stepCtx context.Context) error {
		g, egCtx := errgroup.WithContext(stepCtx)
		for _, kind := range []string{"docker", "tofu", "k8s"} {
			kind := kind
			g.Go(func() error { return synthViaBuck2(egCtx, src, kind) })
		}
		return g.Wait()
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "redistribute-after-buck2", func(context.Context) error {
		return redistributeGenerated(root)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "docs", func(stepCtx context.Context) error {
		if err := generateDocsIndex(root); err != nil {
			return err
		}
		if hasAnyGlob(root, "infra/docs/**", "docs/**", "*.md") {
			return runBash(stepCtx, src, "docs-build", `
set -euo pipefail
if command -v mdbook >/dev/null 2>&1 && [ -f infra/docs/book.toml ]; then
  mdbook build infra/docs
elif command -v mkdocs >/dev/null 2>&1 && [ -f mkdocs.yml ]; then
  mkdocs build
else
  echo "docs engine not configured; generated documentation index only"
fi
`)
		}
		return nil
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "proto-roles", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "proto-roles", `
set -euo pipefail
roles="${RICE_ROLES:-SAGE CLERK BARD KING MASON SMITH CHIEF}"
mkdir -p .rice/cache/proto
if command -v buf >/dev/null 2>&1; then
  if [ -f buf.gen.yaml ]; then
    buf generate
  elif [ -d infra/schemas ]; then
    buf generate infra/schemas || true
  fi
fi
for role in $roles; do
  role_lc="$(echo "$role" | tr '[:upper:]' '[:lower:]')"
  out=".rice/cache/proto/${role_lc}.pb"
  if command -v protoc >/dev/null 2>&1 && ls infra/schemas/*.proto >/dev/null 2>&1; then
    protoc --proto_path=infra/schemas --include_imports --descriptor_set_out="$out" infra/schemas/*.proto
  else
    printf "role=%s\nstatus=protoc_unavailable_or_no_proto\n" "$role" > ".rice/cache/proto/${role_lc}.txt"
  fi
done
`)
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "connectivity", func(stepCtx context.Context) error {
		return runConnectivityChecks(stepCtx)
	}); err != nil {
		return err
	}

	ctr := withPixi(src)
	ctr = withBash(ctr, `
set -euo pipefail
echo "── pour completed: repository hydrated ──"
`)
	if err := mustSync(ctx, ctr, "pour-finalize"); err != nil {
		return err
	}
	if err := redistributeGenerated(root); err != nil {
		return err
	}
	if err := generateDocsIndex(root); err != nil {
		return err
	}
	return nil
}
