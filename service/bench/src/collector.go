package bench

// TODO:
// [ ] implement OTel collector config:
//     ConfigureCollector() — sets up batch processors
//     batch size from RICE_OTEL_BATCH_SIZE env var
//     export interval from RICE_OTEL_INTERVAL_S env var
// [ ] implement span processor:
//     kingdom-wide: receives spans from ALL roles via OTLP
//     forwards to Tempo via otlptracegrpc
// [ ] implement metric reader:
//     PeriodicReader with interval from RICE_METRIC_INTERVAL_S
//     forwards to VictoriaMetrics via otlpmetricgrpc

import (
	"context"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"
)

// PipelineConfig describes OTLP export + batching aligned with an OTel Collector receiver (gRPC).
type PipelineConfig struct {
	ServiceName string
	// OTLPEndpoint is host:port, e.g. "otel-collector:4317".
	OTLPEndpoint string
	// Insecure skips TLS (typical in-cluster gRPC).
	Insecure bool
	// Headers for OTLP auth (e.g. "Authorization" -> "Bearer ...").
	Headers map[string]string

	// TraceSampleRatio in [0,1] for TraceIDRatioBased sampling (1 = always).
	TraceSampleRatio float64

	// BatchTimeout is the span batch delay before export.
	BatchTimeout time.Duration
	// BatchExportMax is the max batch size for spans.
	BatchExportMax int
	// MetricExportInterval is the periodic reader interval for metrics.
	MetricExportInterval time.Duration
}

// DefaultPipelineConfig returns sane defaults for local dev / k8s sidecar collector.
func DefaultPipelineConfig(serviceName, otlpEndpoint string) PipelineConfig {
	return PipelineConfig{
		ServiceName:          serviceName,
		OTLPEndpoint:         otlpEndpoint,
		Insecure:             true,
		TraceSampleRatio:     1.0,
		BatchTimeout:         5 * time.Second,
		BatchExportMax:       512,
		MetricExportInterval: 60 * time.Second,
	}
}

// SetupPropagators installs W3C TraceContext + Baggage on the global OTel instance.
func SetupPropagators() {
	otel.SetTextMapPropagator(
		propagation.NewCompositeTextMapPropagator(
			propagation.TraceContext{},
			propagation.Baggage{},
		),
	)
}

// InstallOTelSDK wires tracer + meter providers, OTLP gRPC exporters, batch span processor,
// and periodic metric reader. Call SetupPropagators first. Returns shutdown for graceful drain.
func InstallOTelSDK(ctx context.Context, cfg PipelineConfig) (func(context.Context) error, error) {
	return installOTLP(ctx, cfg)
}
