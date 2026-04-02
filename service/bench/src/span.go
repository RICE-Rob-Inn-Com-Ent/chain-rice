package bench

// TODO:
// [ ] implement span event helpers:
//     RecordError(span, err) — adds error event to span
//     RecordDBQuery(span, query, duration) — DB query event
//     RecordNATSPublish(span, subject, size) — NATS event
// [ ] implement span link helpers:
//     LinkToParent(ctx, remoteCtx) — cross-service span linking
//     used when NATS message triggers new trace

import (
	"context"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"
)

// StartSpan starts a span with the given tracer and name.
func StartSpan(ctx context.Context, tr trace.Tracer, name string, opts ...trace.SpanStartOption) (context.Context, trace.Span) {
	return tr.Start(ctx, name, opts...)
}

// RecordError marks the span as error and records the error.
func RecordError(span trace.Span, err error) {
	if span == nil || err == nil {
		return
	}
	span.RecordError(err)
	span.SetStatus(codes.Error, err.Error())
}

// SetOK marks the span status as OK.
func SetOK(span trace.Span) {
	if span == nil {
		return
	}
	span.SetStatus(codes.Ok, "")
}

// Event adds a named event with optional attributes.
func Event(span trace.Span, name string, attrs ...attribute.KeyValue) {
	if span == nil {
		return
	}
	span.AddEvent(name, trace.WithAttributes(attrs...))
}

// InjectTraceContext propagates the current span context into carrier (e.g. HTTP headers).
func InjectTraceContext(ctx context.Context, carrier propagation.TextMapCarrier) {
	otel.GetTextMapPropagator().Inject(ctx, carrier)
}

// ExtractTraceContext restores context from carrier (incoming headers).
func ExtractTraceContext(ctx context.Context, carrier propagation.TextMapCarrier) context.Context {
	return otel.GetTextMapPropagator().Extract(ctx, carrier)
}
