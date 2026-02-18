package observability

import (
	"context"
	"fmt"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	tracesdk "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
	"go.opentelemetry.io/otel/trace"
	"go.uber.org/zap"
)

// TracingConfig holds tracing configuration
type TracingConfig struct {
	ServiceName  string
	ServiceVersion string
	Environment   string
	JaegerEndpoint string
	Logger         *zap.SugaredLogger
}

// InitTracing initializes OpenTelemetry tracing
func InitTracing(config TracingConfig) (func(), error) {
	if config.JaegerEndpoint == "" {
		config.JaegerEndpoint = "http://localhost:14268/api/traces"
	}

	// Create Jaeger exporter
	exp, err := jaeger.New(jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(config.JaegerEndpoint)))
	if err != nil {
		return nil, fmt.Errorf("failed to create Jaeger exporter: %w", err)
	}

	// Create resource
	res, err := resource.New(context.Background(),
		resource.WithAttributes(
			semconv.ServiceNameKey.String(config.ServiceName),
			semconv.ServiceVersionKey.String(config.ServiceVersion),
			semconv.DeploymentEnvironmentKey.String(config.Environment),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create resource: %w", err)
	}

	// Create tracer provider
	tp := tracesdk.NewTracerProvider(
		tracesdk.WithBatcher(exp),
		tracesdk.WithResource(res),
	)

	// Set global tracer provider
	otel.SetTracerProvider(tp)

	// Set global propagator
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	// Return cleanup function
	return func() {
		if err := tp.Shutdown(context.Background()); err != nil {
			if config.Logger != nil {
				config.Logger.Errorf("Error shutting down tracer provider: %v", err)
			}
		}
	}, nil
}

// GetTracer returns a tracer for the given name
func GetTracer(name string) trace.Tracer {
	return otel.Tracer(name)
}
