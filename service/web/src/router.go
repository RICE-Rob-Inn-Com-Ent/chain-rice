package web

// Fiber routing: versioned API groups, static assets, and Dead Man's Switch author heartbeat.

import (
	"os"
	"strings"

	"github.com/gofiber/fiber/v2"
)

const (
	// EnvAPIVersion sets the URL segment after /api/ (default "v1").
	EnvAPIVersion = "RICE_API_VERSION"
)

// FastFiberConfig returns Fiber settings tuned for low routing overhead (immutable strings, no banner).
func FastFiberConfig() fiber.Config {
	return fiber.Config{
		DisableStartupMessage: true,
		Immutable:             true,
		StrictRouting:         true,
		CaseSensitive:         false,
		ReduceMemoryUsage:     true,
		ErrorHandler:          FiberErrorHandler,
	}
}

// APIVersion returns the API path segment (e.g. "v1") from [EnvAPIVersion] or default v1.
func APIVersion() string {
	v := strings.TrimSpace(strings.TrimPrefix(os.Getenv(EnvAPIVersion), "/"))
	if v == "" {
		return "v1"
	}
	return v
}

// APIRouter is an optional hook for generated or hand-written handlers.
type APIRouter struct {
	StaticPath string
	StaticRoot string
	Register   func(r fiber.Router)
	// DeadMans, when set, registers the author heartbeat route and should be paired with [DeadMansSwitchGuard].
	DeadMans *DeadMansSwitch
}

// RegisterRoutes attaches versioned API groups and static assets. Call after middleware chain.
// When [APIRouter.DeadMans] is set, registers POST /<pingPath> under /api/<version>/ for [DeadMansSwitch.Touch].
func RegisterRoutes(app *fiber.App, api *APIRouter) {
	if app == nil {
		return
	}
	ver := APIVersion()
	v1 := app.Group("/api/" + ver)
	v1.Get("/ping", func(c *fiber.Ctx) error {
		return c.SendString("pong")
	})
	if api != nil && api.DeadMans != nil {
		registerAuthorHeartbeat(v1, api.DeadMans)
	}
	if api != nil && api.Register != nil {
		api.Register(v1)
	}
	if api != nil && api.StaticPath != "" && api.StaticRoot != "" {
		app.Static(api.StaticPath, api.StaticRoot)
	}
}

// UseDeadMansSwitch installs [DeadMansSwitchGuard] globally (place after recover, before business routes).
func UseDeadMansSwitch(app *fiber.App, d *DeadMansSwitch) {
	if app == nil || d == nil {
		return
	}
	app.Use(DeadMansSwitchGuard(d))
}

func registerAuthorHeartbeat(r fiber.Router, d *DeadMansSwitch) {
	if r == nil || d == nil {
		return
	}
	rel := strings.TrimPrefix(strings.TrimSpace(d.pingPath), "/")
	r.Post("/"+rel, func(c *fiber.Ctx) error {
		d.Touch()
		return c.SendStatus(fiber.StatusNoContent)
	})
}
