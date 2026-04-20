package main

import (
	"context"
	"fmt"
)

// Forge runs buck2 build //... then docker compose up -d via experimental privileged nesting (host Docker).
func (m *Rice) Forge(ctx context.Context) error {
	src := workspaceDir()
	ctr := withPixi(src)
	buck := `
set -euo pipefail
echo "🧑‍🏭 forging environment..."
apt-get update -qq
apt-get install -y -qq zstd curl ca-certificates
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/facebook/buck2/releases/latest/download/buck2-x86_64-unknown-linux-musl.zst | zstd -d -o /usr/local/bin/buck2
chmod +x /usr/local/bin/buck2
buck2 build //...
`
	ctr = withBash(ctr, buck)
	ctr = withBashPrivileged(ctr, `cd /src && docker compose up -d && echo "✅ environment ready"`)
	if err := mustSync(ctx, ctr, "forge"); err != nil {
		return err
	}
	out := ctr.Directory("/src")
	if _, err := out.Export(ctx, "."); err != nil {
		return fmt.Errorf("export workspace after forge: %w", err)
	}
	return nil
}
