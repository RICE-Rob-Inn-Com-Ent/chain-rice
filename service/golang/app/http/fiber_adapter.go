package http

import (
	"context"
	"net/http"

	"github.com/gofiber/fiber/v2"
)

// FiberRouter adapts Fiber framework to Router interface
type FiberRouter struct {
	app *fiber.App
}

// NewFiberRouter creates a new Fiber router adapter
func NewFiberRouter(config fiber.Config) *FiberRouter {
	return &FiberRouter{
		app: fiber.New(config),
	}
}

// GetFiberApp returns the underlying Fiber app (for advanced usage)
func (r *FiberRouter) GetFiberApp() *fiber.App {
	return r.app
}

// Group implements Router interface
func (r *FiberRouter) Group(prefix string) RouterGroup {
	return &FiberRouterGroup{
		group: r.app.Group(prefix),
	}
}

// GET implements Router interface
func (r *FiberRouter) GET(path string, handler HandlerFunc) {
	r.app.Get(path, adaptHandler(handler))
}

// POST implements Router interface
func (r *FiberRouter) POST(path string, handler HandlerFunc) {
	r.app.Post(path, adaptHandler(handler))
}

// PUT implements Router interface
func (r *FiberRouter) PUT(path string, handler HandlerFunc) {
	r.app.Put(path, adaptHandler(handler))
}

// PATCH implements Router interface
func (r *FiberRouter) PATCH(path string, handler HandlerFunc) {
	r.app.Patch(path, adaptHandler(handler))
}

// DELETE implements Router interface
func (r *FiberRouter) DELETE(path string, handler HandlerFunc) {
	r.app.Delete(path, adaptHandler(handler))
}

// Use implements Router interface
func (r *FiberRouter) Use(middleware ...MiddlewareFunc) {
	for _, m := range middleware {
		r.app.Use(adaptMiddleware(m))
	}
}

// Listen implements Router interface
func (r *FiberRouter) Listen(addr string) error {
	return r.app.Listen(addr)
}

// Shutdown implements Router interface
func (r *FiberRouter) Shutdown(ctx context.Context) error {
	return r.app.ShutdownWithContext(ctx)
}

// FiberRouterGroup adapts Fiber group to RouterGroup interface
type FiberRouterGroup struct {
	group fiber.Router
}

// Group implements RouterGroup interface
func (g *FiberRouterGroup) Group(prefix string) RouterGroup {
	return &FiberRouterGroup{
		group: g.group.Group(prefix),
	}
}

// GET implements RouterGroup interface
func (g *FiberRouterGroup) GET(path string, handler HandlerFunc) {
	g.group.Get(path, adaptHandler(handler))
}

// POST implements RouterGroup interface
func (g *FiberRouterGroup) POST(path string, handler HandlerFunc) {
	g.group.Post(path, adaptHandler(handler))
}

// PUT implements RouterGroup interface
func (g *FiberRouterGroup) PUT(path string, handler HandlerFunc) {
	g.group.Put(path, adaptHandler(handler))
}

// PATCH implements RouterGroup interface
func (g *FiberRouterGroup) PATCH(path string, handler HandlerFunc) {
	g.group.Patch(path, adaptHandler(handler))
}

// DELETE implements RouterGroup interface
func (g *FiberRouterGroup) DELETE(path string, handler HandlerFunc) {
	g.group.Delete(path, adaptHandler(handler))
}

// Use implements RouterGroup interface
func (g *FiberRouterGroup) Use(middleware ...MiddlewareFunc) {
	for _, m := range middleware {
		g.group.Use(adaptMiddleware(m))
	}
}

// FiberContext adapts Fiber context to Context interface
type FiberContext struct {
	ctx *fiber.Ctx
}

// Request implements Context interface
func (c *FiberContext) Request() *http.Request {
	// Convert Fiber's fasthttp.Request to net/http.Request
	// Note: This is a simplified conversion; for full compatibility,
	// consider using a proper adapter or working with fasthttp directly
	req := c.ctx.Request()

	// Create a basic http.Request from fasthttp request
	httpReq, err := http.NewRequest(
		string(req.Header.Method()),
		string(req.RequestURI()),
		nil,
	)
	if err != nil {
		// Return a minimal request if conversion fails
		httpReq, _ = http.NewRequest("GET", "/", nil)
	}

	// Copy headers
	req.Header.VisitAll(func(key, value []byte) {
		httpReq.Header.Set(string(key), string(value))
	})

	return httpReq
}

// Response implements Context interface
func (c *FiberContext) Response() http.ResponseWriter {
	return &fiberResponseWriter{ctx: c.ctx}
}

// Params implements Context interface
func (c *FiberContext) Params(key string) string {
	return c.ctx.Params(key)
}

// Query implements Context interface
func (c *FiberContext) Query(key string) string {
	return c.ctx.Query(key)
}

// Header implements Context interface
func (c *FiberContext) Header(key string) string {
	return c.ctx.Get(key)
}

// SetHeader implements Context interface
func (c *FiberContext) SetHeader(key, value string) {
	c.ctx.Set(key, value)
}

// Status implements Context interface
func (c *FiberContext) Status(code int) {
	c.ctx.Status(code)
}

// JSON implements Context interface
func (c *FiberContext) JSON(code int, data interface{}) error {
	return c.ctx.Status(code).JSON(data)
}

// Body implements Context interface
func (c *FiberContext) Body() []byte {
	return c.ctx.Body()
}

// BindJSON implements Context interface
func (c *FiberContext) BindJSON(dest interface{}) error {
	return c.ctx.BodyParser(dest)
}

// Next implements Context interface
func (c *FiberContext) Next() error {
	return c.ctx.Next()
}

// Locals implements Context interface
func (c *FiberContext) Locals(key string, value ...interface{}) interface{} {
	if len(value) > 0 {
		c.ctx.Locals(key, value[0])
		return value[0]
	}
	return c.ctx.Locals(key)
}

// fiberResponseWriter adapts Fiber context to http.ResponseWriter
type fiberResponseWriter struct {
	ctx *fiber.Ctx
}

func (w *fiberResponseWriter) Header() http.Header {
	return make(http.Header) // Fiber manages headers differently
}

func (w *fiberResponseWriter) Write(b []byte) (int, error) {
	return w.ctx.Write(b)
}

func (w *fiberResponseWriter) WriteHeader(statusCode int) {
	w.ctx.Status(statusCode)
}

// adaptHandler converts HandlerFunc to Fiber handler
func adaptHandler(handler HandlerFunc) fiber.Handler {
	return func(c *fiber.Ctx) error {
		ctx := &FiberContext{ctx: c}
		return handler(ctx)
	}
}

// adaptMiddleware converts MiddlewareFunc to Fiber middleware
func adaptMiddleware(middleware MiddlewareFunc) fiber.Handler {
	return func(c *fiber.Ctx) error {
		ctx := &FiberContext{ctx: c}
		next := func(ctx Context) error {
			return ctx.Next()
		}
		wrapped := middleware(next)
		return wrapped(ctx)
	}
}
