// Package foundation holds blank imports so kit/go.mod retains the shared SMITH
// baseline for Fiber and OpenTelemetry across the workspace (MVS alignment).
package foundation

import (
	_ "github.com/gofiber/contrib/otelfiber/v2"
	_ "github.com/gofiber/fiber/v2"
	_ "go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	_ "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	_ "go.opentelemetry.io/otel"
)
