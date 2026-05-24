// Package web is the HTTP/RPC transport layer: Fiber, gRPC, Connect, gocloud integrations.
package web

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
)

const (
	// EnvWebPort is the listen address for Fiber (e.g. ":8080" or "0.0.0.0:8080").
	EnvWebPort = "RICE_WEB_PORT"
	// EnvWebBodyLimitMB caps request bodies in megabytes ([ServerConfig.BodyLimit]).
	EnvWebBodyLimitMB = "RICE_WEB_BODY_LIMIT_MB"
	// EnvSourceURL satisfies AGPL-3.0 corresponding-source notice; exposed at GET /source.
	EnvSourceURL = "RICE_SOURCE_URL"
)

// ServerConfig holds Fiber server tuning and optional TLS (production ingress may terminate TLS instead).
type ServerConfig struct {
	Addr                  string
	ReadTimeout           time.Duration
	WriteTimeout          time.Duration
	IdleTimeout           time.Duration
	BodyLimit             int
	DisableStartupMessage bool
	TLS                   *tls.Config
}

// DefaultServerConfig returns sane defaults for an API behind a reverse proxy.
func DefaultServerConfig(addr string) ServerConfig {
	if addr == "" {
		addr = ":8080"
	}
	return ServerConfig{
		Addr:         addr,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
		BodyLimit:    4 * 1024 * 1024,
	}
}

// NewFiber builds a Fiber app with [FastFiberConfig] defaults merged with timeouts and limits from cfg.
func NewFiber(cfg ServerConfig) *fiber.App {
	fc := FastFiberConfig()
	fc.ReadTimeout = cfg.ReadTimeout
	fc.WriteTimeout = cfg.WriteTimeout
	fc.IdleTimeout = cfg.IdleTimeout
	fc.BodyLimit = cfg.BodyLimit
	fc.DisableStartupMessage = cfg.DisableStartupMessage
	return fiber.New(fc)
}

// RegisterAGPLSourceEndpoint mounts GET /source with AGPL-3.0 notice and optional [EnvSourceURL] for corresponding source.
func RegisterAGPLSourceEndpoint(app *fiber.App) {
	if app == nil {
		return
	}
	app.Get("/source", func(c *fiber.Ctx) error {
		u := strings.TrimSpace(os.Getenv(EnvSourceURL))
		return c.JSON(fiber.Map{
			"license":    "AGPL-3.0",
			"spdx_id":    "AGPL-3.0-only",
			"notice":     "This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License. Corresponding source must be offered to users interacting with it over a network.",
			"source_url": u,
		})
	})
}

// Bootstrap wires optional API routes, CORS, and handler timeouts for [RunBootstrap].
type Bootstrap struct {
	API            *APIRouter
	CORSOrigins    []string
	HandlerTimeout time.Duration
	// OnTelepathyReady is invoked after the local telepathy bridge and quantum link are online.
	OnTelepathyReady func(ql *QuantumLinkManager)
}

func normalizeListenAddr(addr string) string {
	addr = strings.TrimSpace(addr)
	if addr == "" {
		return ":8080"
	}
	if strings.HasPrefix(addr, ":") || strings.Contains(addr, ":") {
		return addr
	}
	return ":" + addr
}

func bodyLimitFromEnv(defaultBytes int) int {
	s := strings.TrimSpace(os.Getenv(EnvWebBodyLimitMB))
	if s == "" {
		return defaultBytes
	}
	mb, err := strconv.Atoi(s)
	if err != nil || mb <= 0 {
		return defaultBytes
	}
	return mb * 1024 * 1024
}

// RunBootstrap initializes the stack from telepathy through the Fiber listener: local bridge + quantum link,
// Anti-Manifesto env, Dead Man's Switch, entanglement health probes, middleware, AGPL /source, global health, routes, then [ListenAndServeContext].
func RunBootstrap(ctx context.Context, b *Bootstrap) error {
	if b == nil {
		b = &Bootstrap{}
	}

	bridge := NewLocalTelepathicBridge()
	ql := NewQuantumLink(bridge, nil)
	if b.OnTelepathyReady != nil {
		b.OnTelepathyReady(ql)
	}

	InitAntiManifestoFromEnv()

	dms := DeadMansSwitchFromEnv(nil)
	dms.Start(ctx)

	ens := NewEntanglementStabilityMonitor(ql)
	reg := &ProbeRegistry{}
	reg.RegisterReadiness(func(c context.Context) error { return ens.Probe(c) })

	addr := normalizeListenAddr(os.Getenv(EnvWebPort))
	cfg := DefaultServerConfig(addr)
	cfg.BodyLimit = bodyLimitFromEnv(cfg.BodyLimit)

	app := NewFiber(cfg)
	DefaultMiddlewareChain(app, b.CORSOrigins, b.HandlerTimeout)
	UseDeadMansSwitch(app, dms)

	RegisterAGPLSourceEndpoint(app)
	RegisterGlobalHealth(app, reg, ens)

	api := b.API
	if api == nil {
		api = &APIRouter{}
	}
	if api.DeadMans == nil {
		api.DeadMans = dms
	}
	RegisterRoutes(app, api)

	return ListenAndServeContext(ctx, app, cfg.Addr)
}

// Listen starts the HTTP server (blocking). Prefer ListenAndServeContext for graceful shutdown.
func Listen(app *fiber.App, addr string) error {
	if app == nil {
		return errors.New("web: nil app")
	}
	return app.Listen(addr)
}

// ListenAndServeContext runs the server until ctx is cancelled, then shuts down gracefully.
func ListenAndServeContext(ctx context.Context, app *fiber.App, addr string) error {
	if app == nil {
		return errors.New("web: nil app")
	}
	errCh := make(chan error, 1)
	go func() {
		errCh <- app.Listen(addr)
	}()
	select {
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		return app.ShutdownWithContext(shutdownCtx)
	case err := <-errCh:
		if err != nil {
			return fmt.Errorf("fiber listen: %w", err)
		}
		return nil
	}
}

// ListenTLS serves with TLS when cfg.TLS is set (or pass cert files via Fiber's ListenTLS).
func ListenTLS(app *fiber.App, addr string, certFile, keyFile string) error {
	if app == nil {
		return errors.New("web: nil app")
	}
	return app.ListenTLS(addr, certFile, keyFile)
}
