package bench

import (
	"context"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

var daggerModuleTP *sdktrace.TracerProvider

// InitDaggerModuleOTel wires propagator + tracer provider for the rice Dagger Go module (dagger/rice).
func InitDaggerModuleOTel(ctx context.Context, res *resource.Resource) context.Context {
	otel.SetTextMapPropagator(Propagator)
	ctx = Propagator.Extract(ctx, NewEnvCarrier(true))
	if res == nil {
		res = resource.Default()
	}
	daggerModuleTP = sdktrace.NewTracerProvider(sdktrace.WithResource(res))
	otel.SetTracerProvider(daggerModuleTP)
	return ctx
}

// ShutdownDaggerModuleOTel shuts down the module tracer provider.
func ShutdownDaggerModuleOTel(ctx context.Context) error {
	if daggerModuleTP == nil {
		return nil
	}
	err := daggerModuleTP.Shutdown(ctx)
	daggerModuleTP = nil
	return err
}
