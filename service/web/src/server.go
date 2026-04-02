// Package web is the HTTP/RPC transport layer: Fiber, gRPC, Connect, gocloud integrations.
package web

// TODO:
// [ ] implement Fiber server setup:
//     NewServer() *fiber.App
//     reads RICE_WEB_PORT from env
//     configure: prefork=false, concurrency, body limit
//     body limit from RICE_WEB_BODY_LIMIT_MB env var
// [ ] implement graceful shutdown:
//     Shutdown(ctx) error — waits for in-flight requests
//     timeout from RICE_WEB_SHUTDOWN_TIMEOUT_S env var
// [ ] implement TLS:
//     TLS cert/key from SOPS secrets
//     RICE_WEB_TLS=true activates TLS
//     mTLS via SPIFFE when RICE_WEB_MTLS=true

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"time"

	"github.com/gofiber/fiber/v2"
)

// ServerConfig holds Fiber server tuning and optional TLS (production ingress may terminate TLS instead).
type ServerConfig struct {
	Addr            string
	ReadTimeout     time.Duration
	WriteTimeout    time.Duration
	IdleTimeout     time.Duration
	BodyLimit       int
	DisableStartupMessage bool
	TLS             *tls.Config
}

// DefaultServerConfig returns sane defaults for an API behind a reverse proxy.
func DefaultServerConfig(addr string) ServerConfig {
	return ServerConfig{
		Addr:         addr,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
		BodyLimit:    4 * 1024 * 1024,
	}
}

// NewFiber builds a Fiber app with timeouts and optional proxy settings.
func NewFiber(cfg ServerConfig) *fiber.App {
	app := fiber.New(fiber.Config{
		ReadTimeout:           cfg.ReadTimeout,
		WriteTimeout:          cfg.WriteTimeout,
		IdleTimeout:           cfg.IdleTimeout,
		BodyLimit:             cfg.BodyLimit,
		DisableStartupMessage: cfg.DisableStartupMessage,
	})
	return app
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
