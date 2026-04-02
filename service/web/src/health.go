package web

// TODO:
// [ ] implement health check routes:
//     GET /health → full health check (all deps)
//     GET /health/live → liveness (always 200)
//     GET /health/ready → readiness (deps checked)
// [ ] delegate to bench/health.go CheckAll()

import (
	"context"
	"sync"

	"github.com/gofiber/fiber/v2"
)

// ProbeRegistry holds readiness checks (database, queue, etc.).
type ProbeRegistry struct {
	mu sync.RWMutex
	// Ready checks return nil when dependency is healthy.
	Ready []func(ctx context.Context) error
}

// RegisterReadiness appends a check (e.g. pgx pool ping, redis ping).
func (p *ProbeRegistry) RegisterReadiness(fn func(ctx context.Context) error) {
	if p == nil || fn == nil {
		return
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	p.Ready = append(p.Ready, fn)
}

// RegisterFiberHealth mounts Kubernetes-style liveness/readiness on the Fiber app.
func RegisterFiberHealth(app *fiber.App, reg *ProbeRegistry) {
	if app == nil {
		return
	}
	app.Get("/livez", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})
	app.Get("/readyz", func(c *fiber.Ctx) error {
		if reg == nil {
			return c.SendStatus(fiber.StatusOK)
		}
		ctx := c.UserContext()
		reg.mu.RLock()
		checks := append([]func(context.Context) error(nil), reg.Ready...)
		reg.mu.RUnlock()
		for _, fn := range checks {
			if err := fn(ctx); err != nil {
				return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": err.Error()})
			}
		}
		return c.SendStatus(fiber.StatusOK)
	})
}

// HealthSummary is a JSON payload for dependency status (extend as needed).
type HealthSummary struct {
	Status     string            `json:"status"`
	Components map[string]string `json:"components,omitempty"`
}
