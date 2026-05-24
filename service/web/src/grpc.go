package web

// gRPC (kit) servers with HFT keepalive tuning and KING/CLERK unary + stream ingress hooks.

import (
	"context"
	"net"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
)

// NewGRPCServer builds a gRPC server with reflection and the standard health service (for probes and mesh checks).
func NewGRPCServer(opts ...kit.ServerOption) *kit.Server {
	s := kit.NewServer(opts...)
	hs := kit.NewHealthServer()
	kit.RegisterHealthServer(s, hs)
	kit.RegisterReflection(s)
	return s
}

// HFTGRPCServerOptions returns [grpc.ServerOption] values for short-interval keepalives and tighter idle bounds.
func HFTGRPCServerOptions() []grpc.ServerOption {
	return []grpc.ServerOption{
		grpc.KeepaliveParams(keepalive.ServerParameters{
			MaxConnectionIdle: 2 * time.Minute,
			Time:              10 * time.Second,
			Timeout:           2 * time.Second,
		}),
		grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
			MinTime:             1 * time.Second,
			PermitWithoutStream: true,
		}),
	}
}

// NewHFTGRPCServer is like [NewGRPCServer] but prepends HFT keepalives and KING/CLERK interceptors before opts.
func NewHFTGRPCServer(k MeshKingOrchestrator, c MeshClerkValidator, opts ...kit.ServerOption) *kit.Server {
	prefix := []grpc.ServerOption{
		grpc.ChainUnaryInterceptor(kingClerkUnaryGRPC(k, c)),
		grpc.ChainStreamInterceptor(kingMeshStreamGRPC(k)),
	}
	prefix = append(prefix, HFTGRPCServerOptions()...)
	all := append(prefix, opts...)
	return NewGRPCServer(all...)
}

func kingClerkUnaryGRPC(k MeshKingOrchestrator, c MeshClerkValidator) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
		if k != nil {
			var err error
			ctx, err = k.PrepareGRPCInbound(ctx, info.FullMethod)
			if err != nil {
				return nil, err
			}
		}
		if c != nil {
			if err := c.ValidateGRPCUnary(ctx, info.FullMethod, req); err != nil {
				return nil, kit.ToStatusError(err)
			}
		}
		return h(ctx, req)
	}
}

func kingMeshStreamGRPC(k MeshKingOrchestrator) grpc.StreamServerInterceptor {
	return func(srv any, ss grpc.ServerStream, info *grpc.StreamServerInfo, h grpc.StreamHandler) error {
		if k == nil {
			return h(srv, ss)
		}
		ctx, err := k.PrepareGRPCInbound(ss.Context(), info.FullMethod)
		if err != nil {
			return err
		}
		wrapped := &grpcStreamContext{ServerStream: ss, ctx: ctx}
		return h(srv, wrapped)
	}
}

type grpcStreamContext struct {
	grpc.ServerStream
	ctx context.Context
}

func (w *grpcStreamContext) Context() context.Context { return w.ctx }

// ListenGRPC listens on addr (e.g. ":50051") and blocks until the server stops.
func ListenGRPC(s *kit.Server, addr string) error {
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return err
	}
	return s.Serve(ln)
}
