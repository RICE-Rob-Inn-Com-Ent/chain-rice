// Package web is SMITH HTTP and RPC transport: Fiber apps, gRPC servers, Connect handlers,
// mail (Postal), gocloud storage, queue hooks, middleware, and TLS/PQ-oriented HTTP clients.
//
// Building blocks (see server.go for listen env vars such as [EnvWebPort], [EnvWebBodyLimitMB], [EnvSourceURL]):
//
//   - Fiber: server.go — ServerConfig, DefaultServerConfig, NewFiber, RunFiber
//   - gRPC (kit.Server): grpc.go — NewGRPCServer, NewHFTGRPCServer
//   - Connect / HTTP2: connect.go — NewConnectMux, NewHFTHTTPServer, NewHFTConnectHTTPClient
//   - Routing and handlers: router.go, handler.go
//   - Middleware: middleware.go, interceptor.go
//   - Errors and health: errors.go, health.go
//   - Mail: mail.go — NewMailClient, NewSecureMailClient
//   - Object storage and secrets: storage.go, secret.go — NewPQHTTPClient, NewPQTLSClientConfig
//   - Queue integration: queue.go
//   - Optional HFT/scout/telepathy helpers: scout.go, telepathy.go, brain_trim.go
package web
