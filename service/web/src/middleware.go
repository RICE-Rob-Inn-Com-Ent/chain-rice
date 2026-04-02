package web

// TODO:
// [ ] implement CORS middleware:
//     CORS() fiber.Handler
//     allowed origins from RICE_WEB_CORS_ORIGINS env var
//     never allow * in production — RICE_ENV check
// [ ] implement request ID middleware:
//     RequestID() fiber.Handler
//     generates UUID v7 per request
//     sets X-Request-ID header
// [ ] implement recover middleware:
//     Recover() fiber.Handler
//     catches panics → logs → returns 500
//     publishes panic event to NATS security.panic.{service}
// [ ] implement compression middleware:
//     Compress() fiber.Handler
//     gzip/brotli based on Accept-Encoding

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/fiber/v2/middleware/requestid"
	"github.com/gofiber/fiber/v2/middleware/timeout"
)

// DefaultMiddlewareChain applies CORS, panic recovery, request IDs, structured logging, per-request timeout, and security headers.
func DefaultMiddlewareChain(app *fiber.App, corsOrigins []string, handlerTimeout time.Duration) {
	if app == nil {
		return
	}
	app.Use(recover.New())
	app.Use(requestid.New())
	app.Use(logger.New())
	if len(corsOrigins) > 0 {
		app.Use(cors.New(cors.Config{
			AllowOrigins: joinOrigins(corsOrigins),
		}))
	}
	app.Use(securityHeaders)
	if handlerTimeout > 0 {
		app.Use(timeout.NewWithContext(func(c *fiber.Ctx) error { return c.Next() }, handlerTimeout))
	}
}

func joinOrigins(origins []string) string {
	if len(origins) == 0 {
		return ""
	}
	s := origins[0]
	for i := 1; i < len(origins); i++ {
		s += "," + origins[i]
	}
	return s
}

// securityHeaders adds minimal "helmet-like" headers (Fiber has no official helmet middleware).
func securityHeaders(c *fiber.Ctx) error {
	c.Set("X-Content-Type-Options", "nosniff")
	c.Set("X-Frame-Options", "DENY")
	c.Set("Referrer-Policy", "strict-origin-when-cross-origin")
	return c.Next()
}
