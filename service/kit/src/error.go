package kit

// SMITH / .rice errors: one type for handlers (Fiber), gRPC status, logs, and OTel.

import (
	"context"
	"errors"
	"fmt"
	"maps"
	"net/http"
	"runtime/debug"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"go.opentelemetry.io/otel/attribute"
	otelcodes "go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	"google.golang.org/genproto/googleapis/rpc/errdetails"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const errDomainRice = "rice"

// Error is the canonical service error for HTTP (Fiber), gRPC, and observability.
// Treat instances as immutable once returned to callers; use WithDetails, Wrap,
// and WithTraceID to derive new values.
type Error struct {
	ID      uuid.UUID
	Code    string
	Message string
	Status  int
	GRPC    codes.Code
	Details map[string]any
	// TraceID links this error to an OTel trace (hex string); optional if unset.
	TraceID string
	Cause   error
}

// AppError is an alias for [*Error] for older call sites and [Tester] helpers.
type AppError = Error

// New allocates a fresh [*Error] with a new [uuid.UUID] and the given mappings.
func New(code string, msg string, status int, grpcCode codes.Code) *Error {
	return &Error{
		ID:      uuid.New(),
		Code:    code,
		Message: msg,
		Status:  status,
		GRPC:    grpcCode,
	}
}

// Internal is a 500 / [codes.Internal] error with code INTERNAL_SERVER_ERROR.
func Internal(msg string) *Error {
	return New("INTERNAL_SERVER_ERROR", msg, http.StatusInternalServerError, codes.Internal)
}

// BadRequest is 400 / [codes.InvalidArgument].
func BadRequest(msg string) *Error {
	return New("BAD_REQUEST", msg, http.StatusBadRequest, codes.InvalidArgument)
}

// NotFound is 404 / [codes.NotFound].
func NotFound(msg string) *Error {
	return New("NOT_FOUND", msg, http.StatusNotFound, codes.NotFound)
}

// Conflict is 409 / [codes.AlreadyExists] (e.g. Postgres unique_violation).
func Conflict(msg string) *Error {
	return New("CONFLICT", msg, http.StatusConflict, codes.AlreadyExists)
}

// Unauthorized is 401 / [codes.Unauthenticated].
func Unauthorized(msg string) *Error {
	return New("UNAUTHORIZED", msg, http.StatusUnauthorized, codes.Unauthenticated)
}

// NewAppError builds an [*Error] with unknown gRPC code (legacy helper for tests).
func NewAppError(code, message string, cause error) *AppError {
	e := New(code, message, http.StatusInternalServerError, codes.Unknown)
	e.Cause = cause
	return e
}

// Error implements [error].
func (e *Error) Error() string {
	if e == nil {
		return ""
	}
	if e.Message != "" {
		return e.Message
	}
	return e.Code
}

// Unwrap returns the wrapped cause, if any.
func (e *Error) Unwrap() error {
	if e == nil {
		return nil
	}
	return e.Cause
}

// clone returns a shallow copy with a cloned Details map (no shared map reference).
func (e *Error) clone() *Error {
	if e == nil {
		return nil
	}
	cp := *e
	if len(e.Details) > 0 {
		cp.Details = maps.Clone(e.Details)
	}
	return &cp
}

// WithDetails returns a new [*Error] with entries merged into Details (later keys overwrite).
func (e *Error) WithDetails(d map[string]any) *Error {
	if e == nil {
		return nil
	}
	if len(d) == 0 {
		return e.clone()
	}
	cp := e.clone()
	if cp.Details == nil {
		cp.Details = make(map[string]any, len(d))
	}
	for k, v := range d {
		cp.Details[k] = v
	}
	return cp
}

// WithTraceID returns a copy with TraceID set (hex or opaque id string).
func (e *Error) WithTraceID(traceID string) *Error {
	if e == nil {
		return nil
	}
	cp := e.clone()
	cp.TraceID = traceID
	return cp
}

// WithTraceFromContext sets TraceID from the trace currently in ctx, if valid.
func (e *Error) WithTraceFromContext(ctx context.Context) *Error {
	if e == nil {
		return nil
	}
	sc := trace.SpanContextFromContext(ctx)
	if !sc.IsValid() {
		return e.clone()
	}
	cp := e.clone()
	cp.TraceID = sc.TraceID().String()
	return cp
}

// Wrap returns a copy with Cause set to fmt.Errorf("%s: %w", msg, err).
// If err is nil, returns a clone with Cause unchanged.
func (e *Error) Wrap(err error, msg string) *Error {
	if e == nil {
		return nil
	}
	cp := e.clone()
	if err == nil {
		return cp
	}
	if msg == "" {
		cp.Cause = err
		return cp
	}
	cp.Cause = fmt.Errorf("%s: %w", msg, err)
	return cp
}

// GRPCStatus builds a gRPC [status.Status] with optional [errdetails.ErrorInfo] metadata.
func (e *Error) GRPCStatus() *status.Status {
	if e == nil {
		return nil
	}
	st := status.New(e.GRPC, e.Message)
	md := detailsToMetaString(e.Details)
	if len(md) > 0 {
		info := &errdetails.ErrorInfo{
			Reason:   e.Code,
			Domain:   errDomainRice,
			Metadata: md,
		}
		if with, derr := st.WithDetails(info); derr == nil {
			st = with
		}
	}
	return st
}

// AsFiber writes JSON {id,code,message,details?} with HTTP Status and returns the Fiber error from JSON encoding.
func (e *Error) AsFiber(c *fiber.Ctx) error {
	if e == nil {
		return nil
	}
	payload := fiber.Map{
		"id":      e.ID.String(),
		"code":    e.Code,
		"message": e.Message,
	}
	if len(e.Details) > 0 {
		payload["details"] = e.Details
	}
	return c.Status(e.Status).JSON(payload)
}

// Record attaches error identity and details to span and marks the span as error.
func (e *Error) Record(span trace.Span) {
	if e == nil || span == nil || !span.IsRecording() {
		return
	}
	span.SetAttributes(
		attribute.String("rice.error.id", e.ID.String()),
		attribute.String("rice.error.code", e.Code),
		attribute.Int("rice.error.http_status", e.Status),
		attribute.Int("rice.error.grpc_code", int(e.GRPC)),
	)
	if e.TraceID != "" {
		span.SetAttributes(attribute.String("rice.error.trace_id", e.TraceID))
	}
	const maxDetailAttrs = 32
	n := 0
	for k, v := range e.Details {
		if n >= maxDetailAttrs {
			span.SetAttributes(attribute.Int("rice.error.details_truncated", len(e.Details)-maxDetailAttrs))
			break
		}
		span.SetAttributes(attribute.String("rice.error.detail."+k, fmt.Sprint(v)))
		n++
	}
	span.SetStatus(otelcodes.Error, e.Message)
	span.RecordError(e)
}

func detailsToMetaString(d map[string]any) map[string]string {
	if len(d) == 0 {
		return nil
	}
	out := make(map[string]string, len(d))
	for k, v := range d {
		out[k] = fmt.Sprint(v)
	}
	return out
}

// Wrap returns fmt.Errorf("%s: %w", msg, err).
func Wrap(err error, msg string) error {
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: %w", msg, err)
}

// Wrapf wraps err with formatted context.
func Wrapf(err error, format string, args ...interface{}) error {
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: %w", fmt.Sprintf(format, args...), err)
}

// Join combines multiple errors (stdlib [errors.Join]).
func Join(errs ...error) error {
	return errors.Join(errs...)
}

// Is reports whether err matches target (stdlib [errors.Is]).
func Is(err, target error) bool {
	return errors.Is(err, target)
}

// As finds the first error in err's chain that matches target (stdlib [errors.As]).
func As(err error, target any) bool {
	return errors.As(err, target)
}

// Unwrap returns the next error in err's chain (stdlib [errors.Unwrap]).
func Unwrap(err error) error {
	return errors.Unwrap(err)
}

// StackTrace returns the current goroutine stack (for logs when wrapping is not enough).
func StackTrace() []byte {
	return debug.Stack()
}
