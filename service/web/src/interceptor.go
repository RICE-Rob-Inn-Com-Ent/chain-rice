package web

// TODO:
// [ ] implement ConnectRPC auth interceptor:
//     validates PASETO token on every non-public RPC
//     public methods list from RICE_WEB_PUBLIC_METHODS env var
// [ ] implement ConnectRPC logging interceptor:
//     logs every RPC: method, duration, status, trace_id
//     uses zap logger from bench/
// [ ] implement ConnectRPC timeout interceptor:
//     per-method timeout from RICE_WEB_METHOD_TIMEOUTS env var
//     default timeout from RICE_WEB_DEFAULT_TIMEOUT_S

import (
	"context"

	"connectrpc.com/connect"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

// UnaryLoggingInterceptor is a gRPC unary interceptor stub (attach OTel / zap here).
func UnaryLoggingInterceptor(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
	return h(ctx, req)
}

// StreamLoggingInterceptor is a gRPC stream interceptor stub.
func StreamLoggingInterceptor(srv any, ss grpc.ServerStream, info *grpc.StreamServerInfo, h grpc.StreamHandler) error {
	return h(srv, ss)
}

// UnaryAuthInterceptor reads gRPC metadata (e.g. authorization) before invoking the handler.
func UnaryAuthInterceptor(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
	_, _ = metadata.FromIncomingContext(ctx)
	return h(ctx, req)
}

// ConnectUnaryLogging is a Connect interceptor for unary RPCs (metrics/tracing hooks).
func ConnectUnaryLogging() connect.Interceptor {
	return connect.UnaryInterceptorFunc(func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			return next(ctx, req)
		}
	})
}
