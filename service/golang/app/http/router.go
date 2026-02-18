package http

import (
	"context"
	"net/http"
)

// Router defines an abstraction for HTTP routing
// This allows swapping between different HTTP frameworks (Fiber, Gin, Echo, etc.)
type Router interface {
	// Group creates a new route group
	Group(prefix string) RouterGroup

	// GET registers a GET route
	GET(path string, handler HandlerFunc)

	// POST registers a POST route
	POST(path string, handler HandlerFunc)

	// PUT registers a PUT route
	PUT(path string, handler HandlerFunc)

	// PATCH registers a PATCH route
	PATCH(path string, handler HandlerFunc)

	// DELETE registers a DELETE route
	DELETE(path string, handler HandlerFunc)

	// Use registers middleware
	Use(middleware ...MiddlewareFunc)

	// Listen starts the server
	Listen(addr string) error

	// Shutdown gracefully shuts down the server
	Shutdown(ctx context.Context) error
}

// RouterGroup represents a group of routes
type RouterGroup interface {
	// Group creates a nested route group
	Group(prefix string) RouterGroup

	// GET registers a GET route
	GET(path string, handler HandlerFunc)

	// POST registers a POST route
	POST(path string, handler HandlerFunc)

	// PUT registers a PUT route
	PUT(path string, handler HandlerFunc)

	// PATCH registers a PATCH route
	PATCH(path string, handler HandlerFunc)

	// DELETE registers a DELETE route
	DELETE(path string, handler HandlerFunc)

	// Use registers middleware for this group
	Use(middleware ...MiddlewareFunc)
}

// HandlerFunc represents an HTTP handler function
type HandlerFunc func(Context) error

// MiddlewareFunc represents middleware function
type MiddlewareFunc func(HandlerFunc) HandlerFunc

// Context represents HTTP request/response context
type Context interface {
	// Request returns the underlying HTTP request
	Request() *http.Request

	// Response returns the response writer
	Response() http.ResponseWriter

	// Params returns route parameters
	Params(key string) string

	// Query returns query parameter
	Query(key string) string

	// Header returns request header
	Header(key string) string

	// SetHeader sets response header
	SetHeader(key, value string)

	// Status sets response status code
	Status(code int)

	// JSON sends JSON response
	JSON(code int, data interface{}) error

	// Body returns request body
	Body() []byte

	// BindJSON binds JSON request body to struct
	BindJSON(dest interface{}) error

	// Next continues to next middleware/handler
	Next() error

	// Locals stores/retrieves local values
	Locals(key string, value ...interface{}) interface{}
}
