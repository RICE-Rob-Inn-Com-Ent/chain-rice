package web

// Global health: Kubernetes-style probes plus quantum entanglement stability (telepathy probe).

import (
	"context"
	"errors"
	"sync"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/gofiber/fiber/v2"
)

// ProbeRegistry holds readiness checks (database, queue, entanglement, etc.).
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

func runReadinessProbes(ctx context.Context, reg *ProbeRegistry) error {
	if reg == nil {
		return nil
	}
	reg.mu.RLock()
	checks := append([]func(context.Context) error{}, reg.Ready...)
	reg.mu.RUnlock()
	for _, fn := range checks {
		if err := fn(ctx); err != nil {
			return err
		}
	}
	return nil
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
		ctx := c.UserContext()
		if err := runReadinessProbes(ctx, reg); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": err.Error()})
		}
		return c.SendStatus(fiber.StatusOK)
	})
}

// EntanglementStabilityMonitor probes [QuantumLinkManager] Link → SyncState → Collapse to verify
// in-process entanglement has not decohered (AGPL stack health signal for the telepathy plane).
type EntanglementStabilityMonitor struct {
	mu sync.RWMutex

	Quantum *QuantumLinkManager
	route   SubPacketRoute

	lastProbeAt time.Time
	probeNanos  int64
	stable      bool
	lastErr     string
}

// NewEntanglementStabilityMonitor builds a monitor with a canonical probe route on the web plane.
func NewEntanglementStabilityMonitor(ql *QuantumLinkManager) *EntanglementStabilityMonitor {
	return &EntanglementStabilityMonitor{
		Quantum: ql,
		route: SubPacketRoute{
			Origin: kit.Pin{Component: "web", Name: "entanglement-probe-a"},
			Dest:   kit.Pin{Component: "web", Name: "entanglement-probe-b"},
		},
	}
}

// Probe runs one Bell-state exercise (link, dual sync, collapse). Safe to register as a readiness check.
func (e *EntanglementStabilityMonitor) Probe(ctx context.Context) error {
	if e == nil || e.Quantum == nil {
		return errors.New("web.health: nil entanglement monitor or quantum link")
	}
	t0 := time.Now()
	id, err := e.Quantum.Link(ctx, e.route)
	if err != nil {
		e.record(t0, false, err)
		return err
	}
	if err := e.Quantum.SyncState(ctx, id); err != nil {
		e.record(t0, false, err)
		return err
	}
	if err := e.Quantum.SyncState(ctx, id); err != nil {
		e.record(t0, false, err)
		return err
	}
	if _, err := e.Quantum.CollapseWavefunction(ctx, id); err != nil {
		e.record(t0, false, err)
		return err
	}
	e.record(t0, true, nil)
	return nil
}

func (e *EntanglementStabilityMonitor) record(t0 time.Time, ok bool, err error) {
	e.mu.Lock()
	defer e.mu.Unlock()
	e.lastProbeAt = time.Now()
	e.probeNanos = time.Since(t0).Nanoseconds()
	e.stable = ok
	if err != nil {
		e.lastErr = err.Error()
		return
	}
	e.lastErr = ""
}

// Snapshot returns the latest probe outcome for JSON health bodies.
func (e *EntanglementStabilityMonitor) Snapshot() EntanglementHealth {
	if e == nil {
		return EntanglementHealth{Stable: false, LastError: "nil monitor"}
	}
	e.mu.RLock()
	defer e.mu.RUnlock()
	if e.lastProbeAt.IsZero() {
		return EntanglementHealth{
			Stable:     true,
			ProbeRoute: e.route.Origin.String() + "→" + e.route.Dest.String(),
		}
	}
	return EntanglementHealth{
		Stable:         e.stable,
		LastCheck:      e.lastProbeAt.UTC().Format(time.RFC3339Nano),
		LastError:      e.lastErr,
		ProbeLatencyMs: e.probeNanos / 1e6,
		ProbeRoute:     e.route.Origin.String() + "→" + e.route.Dest.String(),
	}
}

// EntanglementHealth is embedded in [GlobalHealthResponse].
type EntanglementHealth struct {
	Stable         bool   `json:"stable"`
	LastCheck      string `json:"last_check,omitempty"`
	LastError      string `json:"last_error,omitempty"`
	ProbeLatencyMs int64  `json:"probe_latency_ms,omitempty"`
	ProbeRoute     string `json:"probe_route,omitempty"`
}

// GlobalHealthResponse is returned by GET /health.
type GlobalHealthResponse struct {
	Status       string             `json:"status"`
	Ready        bool               `json:"ready"`
	Entanglement EntanglementHealth `json:"entanglement"`
	Components   map[string]string  `json:"components,omitempty"`
}

// HealthSummary is a JSON payload for dependency status (extend as needed).
type HealthSummary struct {
	Status     string            `json:"status"`
	Components map[string]string `json:"components,omitempty"`
}

// RegisterGlobalHealth mounts /health (full), /health/live, /health/ready, and keeps /livez /readyz via [RegisterFiberHealth].
func RegisterGlobalHealth(app *fiber.App, reg *ProbeRegistry, ens *EntanglementStabilityMonitor) {
	if app == nil {
		return
	}
	RegisterFiberHealth(app, reg)

	app.Get("/health/live", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})
	app.Get("/health/ready", func(c *fiber.Ctx) error {
		ctx := c.UserContext()
		if err := runReadinessProbes(ctx, reg); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": err.Error()})
		}
		return c.SendStatus(fiber.StatusOK)
	})
	app.Get("/health", func(c *fiber.Ctx) error {
		ctx := c.UserContext()
		resp := GlobalHealthResponse{
			Status: "ok",
			Ready:  true,
		}
		if err := runReadinessProbes(ctx, reg); err != nil {
			resp.Status = "degraded"
			resp.Ready = false
			if resp.Components == nil {
				resp.Components = map[string]string{}
			}
			resp.Components["readiness"] = err.Error()
			if ens != nil {
				resp.Entanglement = ens.Snapshot()
			} else {
				resp.Entanglement = EntanglementHealth{Stable: true, ProbeRoute: "disabled"}
			}
			return c.Status(fiber.StatusServiceUnavailable).JSON(resp)
		}
		if ens != nil {
			resp.Entanglement = ens.Snapshot()
		} else {
			resp.Entanglement = EntanglementHealth{Stable: true, ProbeRoute: "disabled"}
		}
		if ens != nil && !resp.Entanglement.Stable {
			resp.Status = "degraded"
			resp.Ready = false
		}
		code := fiber.StatusOK
		if !resp.Ready {
			code = fiber.StatusServiceUnavailable
		}
		return c.Status(code).JSON(resp)
	})
}
