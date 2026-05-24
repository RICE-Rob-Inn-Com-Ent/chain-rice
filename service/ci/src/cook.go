package main

import (
	"context"
	"fmt"
	"strings"

	"dagger/ci/internal/dagger"
)

const flutterCookImage = "ghcr.io/cirruslabs/flutter:stable"

// cookFlutterWebDev runs `flutter run` for a CHIEF custom/*/ui app and keeps the web server up.
// Uses Container.Up so Dagger tunnels the exposed web port to the host until the context is cancelled.
func cookFlutterWebDev(ctx context.Context, src *dagger.Directory, uiRel string, port int) error {
	script := fmt.Sprintf(`
set -euo pipefail
cd /workspace/%s
flutter --version
flutter config --no-analytics --enable-web
flutter pub get
exec flutter run -d web-server --web-hostname=0.0.0.0 --web-port=%d
`, uiRel, port)
	ctr := dag.Container().From(flutterCookImage).
		WithMountedDirectory("/workspace", src).
		WithWorkdir("/workspace").
		WithExposedPort(port).
		WithExec([]string{"bash", "-euo", "pipefail", "-c", script})
	return ctr.Up(ctx)
}

func cookProjectPaths(project string) (uiRel string, port int, err error) {
	p := strings.TrimSpace(strings.ToLower(project))
	switch p {
	case "egos":
		return "custom/EgOS/ui", 8080, nil
	case "code-rice.com", "code-rice", "coderice":
		return "custom/code-rice.com/frontend", 8081, nil
	default:
		return "", 0, fmt.Errorf("unknown project %q: use EgOS or code-rice.com", project)
	}
}

// Cook runs the Flutter web dev server for a CHIEF custom overlay (Dagger tunnels the web port).
func (m *Rice) Cook(ctx context.Context, project string) error {
	uiRel, port, err := cookProjectPaths(project)
	if err != nil {
		return err
	}
	src, err := workspaceDir()
	if err != nil {
		return err
	}
	return cookFlutterWebDev(ctx, src, uiRel, port)
}
