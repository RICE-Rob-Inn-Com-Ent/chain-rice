package bench

// TODO:
// [ ] implement metric instruments:
//     Counter(name, desc string) metric.Int64Counter
//     Histogram(name, desc string, buckets []float64) metric.Float64Histogram
//     Gauge(name, desc string) metric.Float64ObservableGauge
// [ ] implement kingdom-wide metrics:
//     rice.request.count — per service, per method
//     rice.request.duration — histogram with role label
//     rice.error.count — per error code
//     rice.db.query.duration — YugabyteDB query latency
//     rice.nats.publish.count — messages published
//     rice.temporal.workflow.duration — workflow duration
// [ ] implement metric labels:
//     all labels soft-coded: role, service, method, status
//     never hardcode label values

import (
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
)

// Meter returns a meter from the global MeterProvider (set by InstallOTelSDK).
func Meter(name string, opts ...metric.MeterOption) metric.Meter {
	return otel.Meter(name, opts...)
}

// Int64Counter is a thin helper around Meter.Int64Counter.
func Int64Counter(m metric.Meter, name string, opts ...metric.Int64CounterOption) (metric.Int64Counter, error) {
	return m.Int64Counter(name, opts...)
}

// Float64Histogram wraps Meter.Float64Histogram.
func Float64Histogram(m metric.Meter, name string, opts ...metric.Float64HistogramOption) (metric.Float64Histogram, error) {
	return m.Float64Histogram(name, opts...)
}

// Int64UpDownCounter wraps Meter.Int64UpDownCounter (gauges / active work).
func Int64UpDownCounter(m metric.Meter, name string, opts ...metric.Int64UpDownCounterOption) (metric.Int64UpDownCounter, error) {
	return m.Int64UpDownCounter(name, opts...)
}

// Attributes builds OTel attributes from key/value pairs (must be even length).
func Attributes(kv ...string) []attribute.KeyValue {
	if len(kv)%2 != 0 {
		return nil
	}
	out := make([]attribute.KeyValue, 0, len(kv)/2)
	for i := 0; i < len(kv); i += 2 {
		out = append(out, attribute.String(kv[i], kv[i+1]))
	}
	return out
}
