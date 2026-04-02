package bench

// TODO:
// [ ] implement OTel middleware for Fiber:
//     otelfiber.Middleware() — traces every HTTP request
//     adds span with: http.method, http.route, http.status_code
// [ ] implement OTel middleware for ConnectRPC:
//     otelgrpc.UnaryServerInterceptor() — traces every RPC
//     adds span with: rpc.service, rpc.method, rpc.status_code
// [ ] implement rate limit middleware:
//     RateLimiter(rps int) fiber.Handler
//     rps from RICE_RATE_LIMIT_RPS env var
//     uses Valkey as distributed rate limit store

import (
	"net/http"

	otelfiber "github.com/gofiber/contrib/otelfiber/v2"
	"github.com/gofiber/fiber/v2"
	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"google.golang.org/grpc"
)

// FiberOTel returns Fiber middleware that traces HTTP server spans and optional metrics.
func FiberOTel(opts ...otelfiber.Option) fiber.Handler {
	return otelfiber.Middleware(opts...)
}

// GRPCServerStatsHandler instruments incoming gRPC with OpenTelemetry (use with grpc.NewServer).
func GRPCServerStatsHandler(opts ...otelgrpc.Option) grpc.ServerOption {
	return grpc.StatsHandler(otelgrpc.NewServerHandler(opts...))
}

// GRPCClientStatsHandler instruments outgoing gRPC client calls.
func GRPCClientStatsHandler(opts ...otelgrpc.Option) grpc.DialOption {
	return grpc.WithStatsHandler(otelgrpc.NewClientHandler(opts...))
}

// InstrumentHTTPHandler wraps a net/http.Handler with client/server semantic conventions.
func InstrumentHTTPHandler(operation string, h http.Handler) http.Handler {
	return otelhttp.NewHandler(h, operation)
}
