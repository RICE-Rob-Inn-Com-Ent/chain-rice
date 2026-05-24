package web

// ConnectRPC wiring: HFT-oriented handler/client defaults plus KING (mesh orchestration)
// and CLERK (financial/math validation) hooks. Generated handlers pass options from
// [HFTConnectHandlerOptions] or [ConnectBridge.HandlerOptions].

import (
	"context"
	"errors"
	"net/http"
	"os"
	"strings"
	"time"

	"connectrpc.com/connect"
)

// EnvConnectBaseURL is read by [ConnectBaseURL] for inter-service Connect clients (never hardcode URLs).
const EnvConnectBaseURL = "RICE_CONNECT_BASE_URL"

// HFTCompressMinBytes avoids compressing small hot-path messages (CPU > wire savings).
const HFTCompressMinBytes = 4096

// MeshKingOrchestrator is the KING integration point: route tables, fan-out, back-pressure, and
// request-scoped mesh metadata before application logic runs.
type MeshKingOrchestrator interface {
	PrepareConnectInbound(ctx context.Context, procedure string) (context.Context, error)
	PrepareGRPCInbound(ctx context.Context, fullMethod string) (context.Context, error)
}

// MeshClerkValidator is the CLERK integration point: decimals, bounds, NaN/Inf guards, and
// other numeric invariants on unary RPC payloads before commit.
type MeshClerkValidator interface {
	ValidateConnectUnary(ctx context.Context, spec connect.Spec, msg any) error
	ValidateGRPCUnary(ctx context.Context, fullMethod string, req any) error
}

// NopMeshKing is a no-op [MeshKingOrchestrator].
type NopMeshKing struct{}

func (NopMeshKing) PrepareConnectInbound(ctx context.Context, _ string) (context.Context, error) {
	return ctx, nil
}

func (NopMeshKing) PrepareGRPCInbound(ctx context.Context, _ string) (context.Context, error) {
	return ctx, nil
}

// NopMeshClerk is a no-op [MeshClerkValidator].
type NopMeshClerk struct{}

func (NopMeshClerk) ValidateConnectUnary(context.Context, connect.Spec, any) error { return nil }

func (NopMeshClerk) ValidateGRPCUnary(context.Context, string, any) error { return nil }

// ConnectBridge binds KING + CLERK for Connect handlers built from generated New*Handler constructors.
type ConnectBridge struct {
	King  MeshKingOrchestrator
	Clerk MeshClerkValidator
}

// HandlerOptions returns [connect.HandlerOption] for low-latency stacks: strips default gzip,
// raises compression thresholds, injects KING/CLERK, then appends extra interceptors.
func (b *ConnectBridge) HandlerOptions(extraInterceptors ...connect.Interceptor) []connect.HandlerOption {
	k, c := meshFromBridge(b)
	ic := []connect.Interceptor{ConnectKingClerkInterceptor(k, c)}
	ic = append(ic, extraInterceptors...)
	return HFTConnectHandlerOptions(ic...)
}

func meshFromBridge(b *ConnectBridge) (MeshKingOrchestrator, MeshClerkValidator) {
	if b == nil {
		return nil, nil
	}
	return b.King, b.Clerk
}

// ConnectBaseURL returns [EnvConnectBaseURL] trimmed, for use with generated Connect clients.
func ConnectBaseURL() string {
	return strings.TrimSpace(os.Getenv(EnvConnectBaseURL))
}

// HFTConnectHandlerOptions builds server-side options tuned for small, frequent RPCs (HFT-style):
// disables handler gzip, sets a high compression threshold, and applies interceptors.
func HFTConnectHandlerOptions(interceptors ...connect.Interceptor) []connect.HandlerOption {
	opts := []connect.HandlerOption{
		connect.WithCompression("gzip", nil, nil),
		connect.WithCompressMinBytes(HFTCompressMinBytes),
	}
	if len(interceptors) > 0 {
		opts = append(opts, connect.WithInterceptors(interceptors...))
	}
	return opts
}

// HFTConnectClientOptions configures binary gRPC-over-HTTP/2 clients: no inbound gzip, high compress floor.
func HFTConnectClientOptions(extra ...connect.ClientOption) []connect.ClientOption {
	base := []connect.ClientOption{
		connect.WithGRPC(),
		connect.WithAcceptCompression("gzip", nil, nil),
		connect.WithCompressMinBytes(HFTCompressMinBytes),
	}
	return append(base, extra...)
}

// NewHFTConnectHTTPClient returns an [http.Client] with PQ TLS from [NewPQHTTPTransport] and pooled HTTP/2.
func NewHFTConnectHTTPClient() *http.Client {
	t := NewPQHTTPTransport(nil)
	t.MaxIdleConns = 256
	t.MaxIdleConnsPerHost = 64
	t.ForceAttemptHTTP2 = true
	t.IdleConnTimeout = 90 * time.Second
	return &http.Client{Transport: t}
}

// ConnectKingClerkInterceptor runs KING then CLERK on unary RPCs; streaming runs KING only (no first-frame message).
func ConnectKingClerkInterceptor(k MeshKingOrchestrator, c MeshClerkValidator) connect.Interceptor {
	return kingClerkConnectInterceptor{k: k, c: c}
}

type kingClerkConnectInterceptor struct {
	k MeshKingOrchestrator
	c MeshClerkValidator
}

func (i kingClerkConnectInterceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		spec := req.Spec()
		if i.k != nil {
			var err error
			ctx, err = i.k.PrepareConnectInbound(ctx, spec.Procedure)
			if err != nil {
				return nil, err
			}
		}
		if i.c != nil {
			if err := i.c.ValidateConnectUnary(ctx, spec, req.Any()); err != nil {
				return nil, clerkConnectError(err)
			}
		}
		return next(ctx, req)
	}
}

func (i kingClerkConnectInterceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return func(ctx context.Context, conn connect.StreamingHandlerConn) error {
		if i.k != nil && conn != nil {
			var err error
			ctx, err = i.k.PrepareConnectInbound(ctx, conn.Spec().Procedure)
			if err != nil {
				return err
			}
		}
		return next(ctx, conn)
	}
}

func (i kingClerkConnectInterceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return func(ctx context.Context, spec connect.Spec) connect.StreamingClientConn {
		if i.k != nil {
			var err error
			ctx, err = i.k.PrepareConnectInbound(ctx, spec.Procedure)
			if err != nil {
				return &blockedStreamingClientConn{spec: spec, err: err}
			}
		}
		return next(ctx, spec)
	}
}

func clerkConnectError(err error) error {
	if err == nil {
		return nil
	}
	var ce *connect.Error
	if errors.As(err, &ce) {
		return err
	}
	return connect.NewError(connect.CodeInvalidArgument, err)
}

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

// NewHFTHTTPServer is an [http.Server] preset for low-latency Connect over cleartext or TLS (set TLSConfig separately).
func NewHFTHTTPServer(addr string, h http.Handler) *http.Server {
	return &http.Server{
		Addr:              addr,
		Handler:           h,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       120 * time.Second,
	}
}

// RunConnectHTTP serves the mux until ctx is cancelled (graceful shutdown).
func RunConnectHTTP(ctx context.Context, addr string, h http.Handler) error {
	srv := NewHFTHTTPServer(addr, h)
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
