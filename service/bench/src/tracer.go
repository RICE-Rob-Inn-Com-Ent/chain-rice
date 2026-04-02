package bench

// TODO:
// [ ] implement tracer wrapper:
//     Tracer(name string) trace.Tracer — from global provider
// [ ] implement span helpers:
//     StartSpan(ctx, name string) (context.Context, trace.Span)
//     EndSpan(span, err error) — records error if non-nil
// [ ] implement span attributes:
//     WithRole(span, role string) — adds rice.role attribute
//     WithService(span, service string) — adds rice.service
//     WithUserID(span, id string) — adds user.id (GDPR-safe)
// [ ] implement trace context propagation:
//     InjectHTTP(ctx, headers http.Header)
//     ExtractHTTP(ctx, headers http.Header) context.Context
//     InjectNATS(ctx, msg *nats.Msg)
//     ExtractNATS(msg *nats.Msg) context.Context

import (
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/trace"
)

// Tracer returns a tracer from the global TracerProvider (set by InstallOTelSDK).
func Tracer(name string, opts ...trace.TracerOption) trace.Tracer {
	return otel.Tracer(name, opts...)
}
