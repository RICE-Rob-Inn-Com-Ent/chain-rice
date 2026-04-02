package web

// TODO:
// [ ] implement route registration:
//     RegisterRoutes(app *fiber.App, handlers ...Handler)
//     all routes versioned: /v1/, /v2/ — version from RICE_API_VERSION
// [ ] implement route groups per service:
//     /v1/token — blockchain operations
//     /v1/auth — identity operations
//     /v1/data — database operations
//     /v1/queue — async job operations
// [ ] implement route documentation:
//     /openapi.json — generated from proto contracts via MASON
//     /docs — Swagger UI when RICE_WEB_DOCS=true (dev only)

import (
	"github.com/gofiber/fiber/v2"
)

// RegisterRoutes attaches versioned API groups and static assets. Call after middleware chain.
func RegisterRoutes(app *fiber.App, api *APIRouter) {
	if app == nil {
		return
	}
	v1 := app.Group("/api/v1")
	v1.Get("/ping", func(c *fiber.Ctx) error {
		return c.SendString("pong")
	})
	if api != nil && api.Register != nil {
		api.Register(v1)
	}
	if api != nil && api.StaticPath != "" && api.StaticRoot != "" {
		app.Static(api.StaticPath, api.StaticRoot)
	}
}

// APIRouter is an optional hook for generated or hand-written handlers.
type APIRouter struct {
	StaticPath string
	StaticRoot string
	Register   func(r fiber.Router)
}
