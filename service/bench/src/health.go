package bench

// TODO:
// [ ] implement health check registry:
//     Register(name string, check HealthCheck)
//     CheckAll(ctx) map[string]HealthStatus
// [ ] implement health checks:
//     CheckYugabyte(ctx, pool) HealthStatus — pgx.Ping()
//     CheckValkey(ctx, client) HealthStatus — redis.Ping()
//     CheckNATS(ctx, conn) HealthStatus — nats.Status()
//     CheckTemporal(ctx, client) HealthStatus — workflow service desc
//     CheckOTel(ctx) HealthStatus — exporter reachable
// [ ] implement health HTTP handler:
//     GET /health → 200 if all healthy, 503 if any down
//     GET /health/live → always 200 (liveness)
//     GET /health/ready → 200 if ready to serve traffic
// [ ] implement health response format:
//     { status: ok|degraded|down, checks: { name: status } }

import (
	"context"
	"sync"
)

// HealthReport aggregates dependency status for Kubernetes probes or dashboards.
type HealthReport struct {
	Status     string            `json:"status"`
	Components map[string]string `json:"components,omitempty"`
}

// Aggregator runs named readiness checks (DB, Trino, queues, external APIs).
type Aggregator struct {
	mu     sync.RWMutex
	checks map[string]func(context.Context) error
}

// NewHealthAggregator creates an empty registry.
func NewHealthAggregator() *Aggregator {
	return &Aggregator{
		checks: make(map[string]func(context.Context) error),
	}
}

// Register adds or replaces a named check.
func (a *Aggregator) Register(name string, fn func(context.Context) error) {
	if a == nil || name == "" || fn == nil {
		return
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	a.checks[name] = fn
}

// Run executes all checks and returns a report. Any failure sets status to "degraded".
func (a *Aggregator) Run(ctx context.Context) HealthReport {
	if a == nil {
		return HealthReport{Status: "ok"}
	}
	a.mu.RLock()
	defer a.mu.RUnlock()
	out := HealthReport{
		Status:     "ok",
		Components: make(map[string]string, len(a.checks)),
	}
	ok := true
	for name, fn := range a.checks {
		if err := fn(ctx); err != nil {
			out.Components[name] = err.Error()
			ok = false
			continue
		}
		out.Components[name] = "ok"
	}
	if !ok {
		out.Status = "degraded"
	}
	return out
}
