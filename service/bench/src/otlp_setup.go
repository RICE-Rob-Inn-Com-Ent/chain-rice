package bench

// TODO:
// [ ] implement OTel SDK setup:
//     SetupOTel(ctx, serviceName string) (shutdown func(), err error)
//     reads OTEL_EXPORTER_OTLP_ENDPOINT from env
//     reads OTEL_SERVICE_NAME from env
//     configures: TracerProvider, MeterProvider, LoggerProvider
// [ ] configure OTLP gRPC exporter:
//     otlptracegrpc.New() with endpoint from env
//     otlpmetricgrpc.New() with endpoint from env
//     retry policy: exponential backoff, max 5 attempts
// [ ] configure resource:
//     semconv.ServiceNameKey = OTEL_SERVICE_NAME
//     semconv.ServiceVersionKey = build-time version
//     semconv.DeploymentEnvironmentKey = RICE_ENV
// [ ] implement graceful shutdown:
//     shutdown() flushes all pending spans/metrics
//     called on SIGTERM/SIGINT

import (
	"context"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.34.0"
)

func installOTLP(ctx context.Context, cfg PipelineConfig) (func(context.Context) error, error) {
	if cfg.TraceSampleRatio <= 0 {
		cfg.TraceSampleRatio = 1.0
	}
	if cfg.BatchTimeout <= 0 {
		cfg.BatchTimeout = 5 * time.Second
	}
	if cfg.BatchExportMax <= 0 {
		cfg.BatchExportMax = 512
	}
	if cfg.MetricExportInterval <= 0 {
		cfg.MetricExportInterval = 60 * time.Second
	}

	res, err := resource.Merge(
		resource.Default(),
		resource.NewSchemaless(semconv.ServiceName(cfg.ServiceName)),
	)
	if err != nil {
		return nil, err
	}

	topts := []otlptracegrpc.Option{
		otlptracegrpc.WithEndpoint(cfg.OTLPEndpoint),
	}
	if cfg.Insecure {
		topts = append(topts, otlptracegrpc.WithInsecure())
	}
	if len(cfg.Headers) > 0 {
		topts = append(topts, otlptracegrpc.WithHeaders(cfg.Headers))
	}

	texp, err := otlptracegrpc.New(ctx, topts...)
	if err != nil {
		return nil, err
	}

	batchOpts := []sdktrace.BatchSpanProcessorOption{
		sdktrace.WithBatchTimeout(cfg.BatchTimeout),
		sdktrace.WithMaxExportBatchSize(cfg.BatchExportMax),
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithResource(res),
		sdktrace.WithBatcher(texp, batchOpts...),
		sdktrace.WithSampler(sdktrace.TraceIDRatioBased(cfg.TraceSampleRatio)),
	)
	otel.SetTracerProvider(tp)

	mopts := []otlpmetricgrpc.Option{
		otlpmetricgrpc.WithEndpoint(cfg.OTLPEndpoint),
	}
	if cfg.Insecure {
		mopts = append(mopts, otlpmetricgrpc.WithInsecure())
	}
	if len(cfg.Headers) > 0 {
		mopts = append(mopts, otlpmetricgrpc.WithHeaders(cfg.Headers))
	}

	mexp, err := otlpmetricgrpc.New(ctx, mopts...)
	if err != nil {
		_ = tp.Shutdown(ctx)
		return nil, err
	}

	reader := metric.NewPeriodicReader(mexp, metric.WithInterval(cfg.MetricExportInterval))
	mp := metric.NewMeterProvider(
		metric.WithResource(res),
		metric.WithReader(reader),
	)
	otel.SetMeterProvider(mp)

	return func(ctx context.Context) error {
		errM := mp.Shutdown(ctx)
		errT := tp.Shutdown(ctx)
		if errM != nil {
			return errM
		}
		return errT
	}, nil
}
