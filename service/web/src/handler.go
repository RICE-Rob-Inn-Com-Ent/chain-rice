package web

// TODO:
// [ ] implement base handler struct:
//     Handler struct with: logger, tracer, validator, db pool
//     injected via constructor — never global state
// [ ] implement request parsing:
//     ParseBody(ctx, v any) error — JSON or protobuf by Content-Type
//     ParseQuery(ctx, v any) error — query params → struct
// [ ] implement response helpers:
//     JSON(ctx, status int, v any) error
//     Proto(ctx, status int, msg proto.Message) error
//     Error(ctx, err error) error — converts RiceError → HTTP status

import (
	"errors"

	"github.com/gofiber/fiber/v2"
)

// JSON sends a JSON body with status code.
func JSON(c *fiber.Ctx, status int, v any) error {
	return c.Status(status).JSON(v)
}

// ErrorBody is a stable JSON error shape for API clients.
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

// OK returns 200 with optional JSON payload.
func OK(c *fiber.Ctx, v any) error {
	if v == nil {
		return c.SendStatus(fiber.StatusOK)
	}
	return c.JSON(v)
}
