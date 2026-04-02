package web

// TODO:
// [ ] implement ConnectRPC server:
//     NewConnectServer() http.Handler
//     registers all proto service handlers from gen/
//     supports: Connect, gRPC, gRPC-web protocols simultaneously
// [ ] implement ConnectRPC client:
//     NewConnectClient(baseURL string) — for inter-service calls
//     reads target URL from env — never hardcoded
// [ ] implement ConnectRPC interceptors:
//     auth interceptor — validates PASETO
//     otel interceptor — traces every call
//     retry interceptor — idempotent methods only
//     timeout interceptor — per-method timeout from config

import (
	"context"
	"net/http"
	"time"

	"connectrpc.com/connect"
)

// NewConnectMux returns an empty http.ServeMux; register generated Connect handlers with MountConnect.
func NewConnectMux() *http.ServeMux {
	return http.NewServeMux()
}

// MountConnect registers a Connect-generated http.Handler at path (e.g. "/rpc/...").
func MountConnect(mux *http.ServeMux, path string, h http.Handler) {
	if mux == nil || h == nil {
		return
	}
	mux.Handle(path, h)
}

// ConnectHandlerOptions builds connect.HandlerOption slices (compression, interceptors from interceptor.go).
func ConnectHandlerOptions(interceptors ...connect.Interceptor) []connect.HandlerOption {
	if len(interceptors) == 0 {
		return nil
	}
	return []connect.HandlerOption{connect.WithInterceptors(interceptors...)}
}

// RunConnectHTTP serves the mux until ctx is cancelled (graceful shutdown).
func RunConnectHTTP(ctx context.Context, addr string, h http.Handler) error {
	srv := &http.Server{
		Addr:              addr,
		Handler:           h,
		ReadHeaderTimeout: 10 * time.Second,
	}
	errCh := make(chan error, 1)
	go func() { errCh <- srv.ListenAndServe() }()
	select {
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		return srv.Shutdown(shutdownCtx)
	case err := <-errCh:
		return err
	}
}
