// Package ricegrpc centralizes gRPC imports on the shared kit module so every
// SMITH service gets the same google.golang.org/grpc version from kit/go.mod.
package ricegrpc

import (
	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/reflection"
)

// Server-side and client types used across web, bench, and token.
type (
	Server            = grpc.Server
	ServerOption      = grpc.ServerOption
	DialOption        = grpc.DialOption
	ClientConn        = grpc.ClientConn
	UnaryServerInfo   = grpc.UnaryServerInfo
	UnaryHandler      = grpc.UnaryHandler
	StreamServerInfo  = grpc.StreamServerInfo
	StreamHandler     = grpc.StreamHandler
	ServerStream     = grpc.ServerStream
	ServiceRegistrar = grpc.ServiceRegistrar
)

// Server constructor and interceptors.
var (
	NewServer        = grpc.NewServer
	Dial             = grpc.Dial
	DialContext      = grpc.DialContext
	StatsHandler     = grpc.StatsHandler
	WithStatsHandler = grpc.WithStatsHandler
)

// HealthCheckServer is the concrete type returned by NewHealthServer.
type HealthCheckServer = health.Server

// NewHealthServer allocates the default health service implementation.
func NewHealthServer() *health.Server {
	return health.NewServer()
}

// RegisterHealthServer wires the standard gRPC health service.
func RegisterHealthServer(reg grpc.ServiceRegistrar, srv healthpb.HealthServer) {
	healthpb.RegisterHealthServer(reg, srv)
}

// RegisterReflection enables server reflection (dev / tooling only at call sites).
func RegisterReflection(s *Server) {
	reflection.Register(s)
}

// Metadata helpers (interceptors).
var FromIncomingContext = metadata.FromIncomingContext
