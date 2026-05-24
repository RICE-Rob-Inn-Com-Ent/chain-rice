package web

// Fiber helpers: JSON/query parsing, stable errors, and the global [FiberErrorHandler].

import (
	"errors"
	"fmt"

	"github.com/gofiber/fiber/v2"
)

// ParseJSONBody decodes JSON into v using the request Content-Type (Fiber [Ctx.BodyParser]).
func ParseJSONBody(c *fiber.Ctx, v any) error {
	if c == nil {
		return errors.New("web: nil context")
	}
	return c.BodyParser(v)
}

// ParseQuery binds query parameters into v (Fiber [Ctx.QueryParser]).
func ParseQuery(c *fiber.Ctx, v any) error {
	if c == nil {
		return errors.New("web: nil context")
	}
	return c.QueryParser(v)
}

// JSON sends a JSON body with status code.
func JSON(c *fiber.Ctx, status int, v any) error {
	return c.Status(status).JSON(v)
}

// ErrorBody is a stable JSON error shape for API clients (legacy; prefer [RPCStatus] via [FiberErrorHandler]).
type ErrorBody struct {
	Error   string `json:"error"`
	Code    string `json:"code,omitempty"`
	TraceID string `json:"trace_id,omitempty"`
}

// ErrorResponse maps an error to HTTP status and JSON (uses Locals["requestid"] if present).
func ErrorResponse(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	var fiberErr *fiber.Error
	if errors.As(err, &fiberErr) {
		code = fiberErr.Code
	}
	traceID, _ := c.Locals("requestid").(string)
	return c.Status(code).JSON(ErrorBody{
		Error:   err.Error(),
		TraceID: traceID,
	})
}

// FiberErrorHandler is the default [fiber.Config.ErrorHandler]: [*fiber.Error] codes, [ErrDeadMansSwitchTripped], else 500 [RPCStatus].
func FiberErrorHandler(c *fiber.Ctx, err error) error {
	if err == nil {
		return nil
	}
	var fe *fiber.Error
	if errors.As(err, &fe) {
		return c.Status(fe.Code).JSON(RPCStatus{
			Code:    fmt.Sprintf("HTTP_%d", fe.Code),
			Message: fe.Message,
		})
	}
	if errors.Is(err, ErrDeadMansSwitchTripped) {
		return c.Status(fiber.StatusServiceUnavailable).JSON(RPCStatus{
			Code:    "SELF_DESTRUCT",
			Message: err.Error(),
		})
	}
	return c.Status(fiber.StatusInternalServerError).JSON(RPCStatus{
		Code:    "INTERNAL",
		Message: err.Error(),
	})
}

// OK returns 200 with optional JSON payload.
func OK(c *fiber.Ctx, v any) error {
	if v == nil {
		return c.SendStatus(fiber.StatusOK)
	}
	return c.JSON(v)
}
