package web

// TODO:
// [ ] implement gRPC server:
//     NewGRPCServer() *grpc.Server
//     with OTel interceptor, auth interceptor, recovery interceptor
// [ ] implement gRPC health service:
//     grpc_health_v1.RegisterHealthServer()
//     SERVING status when all deps healthy
// [ ] implement gRPC reflection:
//     reflection.Register(server) — enabled when RICE_GRPC_REFLECT=true
//     dev only — never in production

import (
	"net"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/reflection"
)

// NewGRPCServer builds a gRPC server with reflection and the standard health service (for probes and mesh checks).
func NewGRPCServer(opts ...grpc.ServerOption) *grpc.Server {
	s := grpc.NewServer(opts...)
	hs := health.NewServer()
	healthpb.RegisterHealthServer(s, hs)
	reflection.Register(s)
	return s
}

// ListenGRPC listens on addr (e.g. ":50051") and blocks until the server stops.
func ListenGRPC(s *grpc.Server, addr string) error {
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return err
	}
	return s.Serve(ln)
}
