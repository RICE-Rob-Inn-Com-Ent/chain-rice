package kit

// gRPC server/client defaults for SMITH: OTel, kit metadata, panic recovery, retries.

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/retry"
	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/reflection"
	"google.golang.org/grpc/status"
)

// gRPC type aliases (replaces former ricegrpc subpackage).
type (
	Server                 = grpc.Server
	ServerOption           = grpc.ServerOption
	DialOption             = grpc.DialOption
	ClientConn             = grpc.ClientConn
	UnaryServerInfo        = grpc.UnaryServerInfo
	UnaryHandler           = grpc.UnaryHandler
	StreamServerInfo       = grpc.StreamServerInfo
	StreamHandler          = grpc.StreamHandler
	ServerStream           = grpc.ServerStream
	ServiceRegistrar       = grpc.ServiceRegistrar
	UnaryClientInterceptor = grpc.UnaryClientInterceptor
)

var (
	// StatsHandler wires OTel metrics/traces for servers (use with [grpc.StatsHandler]).
	StatsHandler = grpc.StatsHandler
	// WithStatsHandler passes a [stats.Handler] into [grpc.NewServer].
	WithStatsHandler = grpc.WithStatsHandler
	// DialContext connects with a caller context (deprecated API; prefer [NewClient]).
	DialContext = grpc.DialContext
	// Dial is the legacy blocking dial helper.
	Dial = grpc.Dial
)

// FromIncomingContext returns incoming metadata from ctx.
var FromIncomingContext = metadata.FromIncomingContext

// defaultRetry is a conservative unary retry policy (transient codes only).
var defaultUnaryRetry = retry.UnaryClientInterceptor(
	retry.WithMax(3),
	retry.WithCodes(codes.Unavailable, codes.ResourceExhausted, codes.Aborted),
)

// NewServer returns a [grpc.Server] with OTel stats, kit unary interceptor (metadata + panic + logging),
// and keepalive defaults. Extra opts append and can override behavior where gRPC allows.
func NewServer(opts ...grpc.ServerOption) *grpc.Server {
	base := []grpc.ServerOption{
		grpc.StatsHandler(otelgrpc.NewServerHandler()),
		grpc.ChainUnaryInterceptor(unaryServerInterceptor),
		grpc.KeepaliveParams(keepalive.ServerParameters{
			MaxConnectionIdle: 15 * time.Minute,
			Time:              30 * time.Second,
			Timeout:           5 * time.Second,
		}),
		grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
			MinTime:             5 * time.Second,
			PermitWithoutStream: true,
		}),
	}
	all := append(base, opts...)
	return grpc.NewServer(all...)
}

func unaryServerInterceptor(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (resp any, err error) {
	start := time.Now()
	if md, ok := metadata.FromIncomingContext(ctx); ok {
		meta := metadataToKit(md)
		kc := NewContext(ctx, meta)
		ctx = kc.ToContext()
	}
	if span := trace.SpanFromContext(ctx); span.IsRecording() {
		span.SetAttributes(attribute.String("rice.grpc.method", info.FullMethod))
	}
	defer func() {
		if r := recover(); r != nil {
			slog.ErrorContext(ctx, "grpc unary panic", "method", info.FullMethod, "recover", r)
			err = ToStatusError(Internal("grpc handler panic").WithDetails(map[string]any{"method": info.FullMethod}))
		}
		st, _ := status.FromError(err)
		slog.InfoContext(ctx, "grpc unary", "method", info.FullMethod,
			"duration_ms", time.Since(start).Milliseconds(), "code", st.Code().String())
	}()
	return h(ctx, req)
}

func metadataToKit(md metadata.MD) *Metadata {
	if len(md) == 0 {
		return nil
	}
	m := &Metadata{}
	for k, vals := range md {
		if len(vals) == 0 {
			continue
		}
		m.Set(k, vals[0])
	}
	return m
}

// NewClient dials target with OTel propagation, outgoing kit metadata injection, and unary retries.
// Context cancellation applies to the overall dial when supported by underlying transport options.
func NewClient(target string, opts ...grpc.DialOption) (*grpc.ClientConn, error) {
	base := []grpc.DialOption{
		grpc.WithStatsHandler(otelgrpc.NewClientHandler()),
		grpc.WithChainUnaryInterceptor(
			defaultUnaryRetry,
			otelgrpc.UnaryClientInterceptor(),
			unaryClientMetadataInterceptor,
		),
		grpc.WithKeepaliveParams(keepalive.ClientParameters{
			Time:                30 * time.Second,
			Timeout:             5 * time.Second,
			PermitWithoutStream: true,
		}),
	}
	all := append(base, opts...)
	return grpc.NewClient(target, all...)
}

func unaryClientMetadataInterceptor(ctx context.Context, method string, req, reply any, cc *grpc.ClientConn, invoker grpc.UnaryInvoker, opts ...grpc.CallOption) error {
	ctx = appendOutgoingKitMetadata(ctx)
	return invoker(ctx, method, req, reply, cc, opts...)
}

func appendOutgoingKitMetadata(ctx context.Context) context.Context {
	kc := FromContext(ctx)
	if kc == nil {
		return ctx
	}
	var pairs []string
	if kc.Meta != nil {
		kc.Meta.mu.RLock()
		for k, v := range kc.Meta.m {
			pairs = append(pairs, k, v)
		}
		kc.Meta.mu.RUnlock()
	}
	if kc.TraceID.IsValid() {
		pairs = append(pairs, MetaTraceID, kc.TraceID.String())
	}
	if kc.SpanID.IsValid() {
		pairs = append(pairs, MetaSpanID, kc.SpanID.String())
	}
	if len(pairs) == 0 {
		return ctx
	}
	return metadata.AppendToOutgoingContext(ctx, pairs...)
}

// ToStatusError maps err to a gRPC status. [*Error] uses [Error.GRPCStatus]; otherwise [codes.Internal].
func ToStatusError(err error) error {
	if err == nil {
		return nil
	}
	var ke *Error
	if errors.As(err, &ke) && ke != nil {
		st := ke.GRPCStatus()
		if st == nil {
			return status.Error(codes.Internal, err.Error())
		}
		return st.Err()
	}
	if _, ok := status.FromError(err); ok {
		return err
	}
	return status.Error(codes.Internal, err.Error())
}

// HealthCheckServer is the concrete type returned by [NewHealthServer].
type HealthCheckServer = health.Server

// NewHealthServer allocates the default gRPC health implementation.
func NewHealthServer() *health.Server {
	return health.NewServer()
}

// RegisterHealthServer registers the standard gRPC health service.
func RegisterHealthServer(reg grpc.ServiceRegistrar, srv healthpb.HealthServer) {
	healthpb.RegisterHealthServer(reg, srv)
}

// RegisterReflection enables gRPC reflection (dev / tooling only at call sites).
func RegisterReflection(s *Server) {
	reflection.Register(s)
}
