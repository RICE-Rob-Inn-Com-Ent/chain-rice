package kit

// Orchestrator: OTel providers, validator, logging, root [Context], CLI bridge, and package shortcuts.
// Blank imports keep MVS alignment for Fiber, HTTP/gRPC OTel contrib, and the OTel API.

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"

	"github.com/go-playground/validator/v10"
	_ "github.com/gofiber/contrib/otelfiber/v2"
	_ "github.com/gofiber/fiber/v2"
	_ "go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	_ "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/metric"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
	"go.opentelemetry.io/otel/trace"
	"google.golang.org/grpc/codes"
)

// Build metadata (set via Back2 / Buck2 / go build -ldflags).
//
// Example:
//
//	-ldflags "-X github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src.Version=0.4.1 \
//	  -X github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src.BuildTime=2026-05-01T12:00:00Z \
//	  -X github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src.GitCommit=abc123"
var (
	BuildTime = "(unknown)"
	GitCommit = "(unknown)"
)

// KitConfig holds service-level options applied by [NewKit].
type KitConfig struct {
	ServiceName string
}

// Kit is the SMITH runtime bundle: validation, telemetry, logging, and the root [Context].
type Kit struct {
	Validator *validator.Validate
	Config    KitConfig
	Log       *slog.Logger
	Tracer    trace.Tracer
	Meter     metric.Meter

	tp   *sdktrace.TracerProvider
	mp   *sdkmetric.MeterProvider
	root *Context
}

// NewKit initializes global OTel tracer/meter providers, the shared validator (rice uuid/slug tags),
// default slog, and a root [Context] tagged with the service name.
// (The name [New] is reserved for the [*Error] constructor in [error.go].)
func NewKit() (*Kit, error) {
	ctx := context.Background()
	sn := KitConfig{ServiceName: os.Getenv("OTEL_SERVICE_NAME")}.ServiceName
	if sn == "" {
		sn = "smith/kit"
	}

	res, err := resource.New(ctx,
		resource.WithTelemetrySDK(),
		resource.WithAttributes(semconv.ServiceName(sn)),
	)
	if err != nil {
		return nil, fmt.Errorf("kit: resource: %w", err)
	}

	tp := sdktrace.NewTracerProvider(sdktrace.WithResource(res))
	otel.SetTracerProvider(tp)

	mp := sdkmetric.NewMeterProvider(sdkmetric.WithResource(res))
	otel.SetMeterProvider(mp)

	v := Validator()
	log := slog.Default()

	meta := &Metadata{}
	meta.Set("rice.service", sn)
	root := NewContext(ctx, meta)

	return &Kit{
		Validator: v,
		Config:    KitConfig{ServiceName: sn},
		Log:       log,
		Tracer:    otel.Tracer(sn),
		Meter:     otel.Meter(sn),
		tp:        tp,
		mp:        mp,
		root:      root,
	}, nil
}

// Root returns the root [Context] created by [NewKit] (service metadata and background parent).
func (k *Kit) Root() *Context {
	if k == nil || k.root == nil {
		return NewContext(context.Background(), nil)
	}
	return k.root
}

// Close shuts down OTel tracer and meter providers (flush/export). Pass a deadline via ctx.
func (k *Kit) Close(ctx context.Context) error {
	if k == nil {
		return nil
	}
	var errs error
	if k.tp != nil {
		errs = errors.Join(errs, k.tp.Shutdown(ctx))
	}
	if k.mp != nil {
		errs = errors.Join(errs, k.mp.Shutdown(ctx))
	}
	return errs
}

// Execute runs a Cobra [Command] with [Execute] semantics and the kit logger as [slog.Default].
func (k *Kit) Execute(cmd Command) error {
	if k == nil {
		return errors.New("kit: Execute: nil *Kit")
	}
	if k.Log != nil {
		slog.SetDefault(k.Log)
	}
	return Execute(cmd)
}

// SanityCheck exercises uuid, validation, and telemetry handles (for the standalone kit tool and CI).
func SanityCheck(k *Kit) error {
	if k == nil {
		return errors.New("kit: SanityCheck: nil *Kit")
	}
	u, err := NewUUID()
	if err != nil {
		return err
	}
	if IsNil(u) {
		return errors.New("kit: sanity: uuid is nil")
	}
	if _, err := Parse(u.String()); err != nil {
		return err
	}

	type row struct {
		S string `json:"s" validate:"uuid"`
	}
	if err := k.Validator.Struct(&row{S: "not-a-uuid"}); err == nil {
		return errors.New("kit: sanity: expected validation failure")
	}

	if k.Tracer == nil {
		return errors.New("kit: sanity: nil Tracer")
	}
	ctx, span := k.Tracer.Start(context.Background(), "kit.sanity")
	span.End()
	_ = ctx

	return nil
}

// Err is a compact entry point for constructors that return [*Error] (see [NotFound], [New], etc.).
type errShortcuts struct{}

// Err groups error constructors.
var Err errShortcuts

func (errShortcuts) New(code, msg string, status int, c codes.Code) *Error {
	return New(code, msg, status, c)
}
func (errShortcuts) Internal(msg string) *Error   { return Internal(msg) }
func (errShortcuts) BadRequest(msg string) *Error { return BadRequest(msg) }
func (errShortcuts) NotFound(msg string) *Error   { return NotFound(msg) }
func (errShortcuts) Conflict(msg string) *Error   { return Conflict(msg) }
func (errShortcuts) Unauthorized(msg string) *Error {
	return Unauthorized(msg)
}

// Unauthenticated is the same as [Unauthorized] (401 / gRPC Unauthenticated); prefer this name at auth boundaries.
func (errShortcuts) Unauthenticated(msg string) *Error {
	return Unauthorized(msg)
}

// ID groups [UUID] helpers. The value type is named [UUID], so the shortcut cannot be named UUID.
type idShortcuts struct{}

// ID is the package-level shortcut for uuid operations: kit.ID.New(), kit.ID.Parse(s), etc.
var ID idShortcuts

func (idShortcuts) New() (UUID, error)           { return NewUUID() }
func (idShortcuts) MustNew() UUID                { return MustNew() }
func (idShortcuts) Parse(s string) (UUID, error) { return Parse(s) }
func (idShortcuts) MustParse(s string) UUID      { return MustParse(s) }
func (idShortcuts) NewString() string            { return NewString() }
func (idShortcuts) Mock() UUID                   { return MockUUID() }
func (idShortcuts) ValidateString(s string) bool { return Validate(s) }
