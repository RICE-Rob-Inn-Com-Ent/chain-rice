package web

// Fiber middleware: CORS, recovery, request IDs, security headers, timeout, and Dead Man's Switch.

import (
	"context"
	"os"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/fiber/v2/middleware/requestid"
	"github.com/gofiber/fiber/v2/middleware/timeout"
)

const (
	// EnvDMSOfflineDays is the author offline threshold in whole days (default 7).
	EnvDMSOfflineDays = "RICE_DMS_OFFLINE_DAYS"
	// EnvDMSPingPath is the relative path under the mounted API group for author heartbeats (default "_system/author/ping").
	EnvDMSPingPath = "RICE_DMS_PING_PATH"
)

// DeadMansSwitch tracks author presence. If no heartbeat for longer than [Threshold], the switch
// trips and [DeadMansSwitchGuard] begins the self-destruct sequence (hard 503 on application routes).
type DeadMansSwitch struct {
	mu sync.RWMutex

	lastSeen  time.Time
	threshold time.Duration
	tripped   atomic.Bool
	onTrip    func()

	skipPrefixes []string
	pingPath     string
}

// NewDeadMansSwitch starts in a healthy state (last seen = now). Call [DeadMansSwitch.Start] to arm the watcher.
func NewDeadMansSwitch(threshold time.Duration, onTrip func()) *DeadMansSwitch {
	if threshold <= 0 {
		threshold = 7 * 24 * time.Hour
	}
	d := &DeadMansSwitch{
		lastSeen:  time.Now(),
		threshold: threshold,
		onTrip:    onTrip,
		pingPath:  "_system/author/ping",
		skipPrefixes: []string{
			"/health", "/health/", "/healthz", "/live", "/livez", "/ready", "/readyz",
			"/source",
		},
	}
	if p := strings.TrimSpace(os.Getenv(EnvDMSPingPath)); p != "" {
		d.pingPath = strings.TrimPrefix(strings.TrimSpace(p), "/")
	}
	return d
}

// DeadMansSwitchFromEnv uses [EnvDMSOfflineDays] (default 7) for the threshold.
func DeadMansSwitchFromEnv(onTrip func()) *DeadMansSwitch {
	days := 7
	if s := strings.TrimSpace(os.Getenv(EnvDMSOfflineDays)); s != "" {
		if n, err := strconv.Atoi(s); err == nil && n > 0 {
			days = n
		}
	}
	return NewDeadMansSwitch(time.Duration(days)*24*time.Hour, onTrip)
}

// Touch records author presence (idempotent). Safe to call from login hooks or the ping handler.
func (d *DeadMansSwitch) Touch() {
	if d == nil {
		return
	}
	d.mu.Lock()
	d.lastSeen = time.Now()
	d.mu.Unlock()
}

// Tripped reports whether self-destruct is armed.
func (d *DeadMansSwitch) Tripped() bool {
	if d == nil {
		return false
	}
	return d.tripped.Load()
}

// Start runs a background watch: when wall-clock time since last [Touch] exceeds [Threshold], the switch trips once.
func (d *DeadMansSwitch) Start(ctx context.Context) {
	if d == nil {
		return
	}
	go func() {
		t := time.NewTicker(time.Hour)
		defer t.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-t.C:
				d.evaluateTrip()
			}
		}
	}()
}

func (d *DeadMansSwitch) evaluateTrip() {
	d.mu.RLock()
	ls := d.lastSeen
	th := d.threshold
	d.mu.RUnlock()
	if time.Since(ls) <= th {
		return
	}
	if d.tripped.CompareAndSwap(false, true) {
		if d.onTrip != nil {
			d.onTrip()
		}
	}
}

func (d *DeadMansSwitch) skipPath(path string) bool {
	for _, p := range d.skipPrefixes {
		if p != "" && strings.HasPrefix(path, p) {
			return true
		}
	}
	return false
}

// DeadMansSwitchGuard returns middleware that blocks traffic once the switch has tripped (self-destruct),
// except probe paths in [DeadMansSwitch.skipPrefixes].
func DeadMansSwitchGuard(d *DeadMansSwitch) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if d == nil {
			return c.Next()
		}
		if d.skipPath(c.Path()) {
			return c.Next()
		}
		d.evaluateTrip()
		if d.tripped.Load() {
			return c.Status(fiber.StatusServiceUnavailable).JSON(RPCStatus{
				Code:    "SELF_DESTRUCT",
				Message: ErrDeadMansSwitchTripped.Error(),
			})
		}
		return c.Next()
	}
}

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

func securityHeaders(c *fiber.Ctx) error {
	c.Set("X-Content-Type-Options", "nosniff")
	c.Set("X-Frame-Options", "DENY")
	c.Set("Referrer-Policy", "strict-origin-when-cross-origin")
	return c.Next()
}
