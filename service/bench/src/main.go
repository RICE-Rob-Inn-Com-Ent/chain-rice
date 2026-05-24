// Package bench is SMITH observability: OpenTelemetry pipelines, Zap logging bridged to OTel,
// Fiber/gRPC/HTTP instrumentation, trace propagation, Pyroscope profiling, Trino analytics access,
// and health aggregation for CI/Dagger modules.
//
// Entry points and where they live:
//
//   - OTLP trace/metrics install and shutdown: collector.go — InstallOTelSDK, DefaultPipelineConfig, SetupPropagators
//   - Global tracer access: tracer.go — Tracer
//   - Span helpers: span.go — StartSpan, RecordError, InjectTraceContext, ExtractTraceContext
//   - Structured logs: logger.go — NewProductionLogger, NewDevelopmentLogger, NewZapWithOTelCore
//   - Transport middleware: middleware.go — FiberOTel, GRPCServerStatsHandler, GRPCClientStatsHandler, InstrumentHTTPHandler
//   - Dagger module OTel: dagger_module.go — InitDaggerModuleOTel, ShutdownDaggerModuleOTel
//   - Env propagation for subprocesses: propagation.go
//   - Continuous profiling: profiler.go — StartPyroscope, StopPyroscope
//   - Health rollups: health.go — NewHealthAggregator
//   - Trino SQL: trino.go — OpenTrino, PingTrino, QueryTrino
//   - Metrics helpers: metric.go
package bench
