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

	ricegrpc "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src/ricegrpc"
)

// NewGRPCServer builds a gRPC server with reflection and the standard health service (for probes and mesh checks).
func NewGRPCServer(opts ...ricegrpc.ServerOption) *ricegrpc.Server {
	s := ricegrpc.NewServer(opts...)
	hs := ricegrpc.NewHealthServer()
	ricegrpc.RegisterHealthServer(s, hs)
	ricegrpc.RegisterReflection(s)
	return s
}

// ListenGRPC listens on addr (e.g. ":50051") and blocks until the server stops.
func ListenGRPC(s *ricegrpc.Server, addr string) error {
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return err
	}
	return s.Serve(ln)
}
