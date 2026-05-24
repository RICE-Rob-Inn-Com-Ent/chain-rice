package queue

import (
	"context"
	"crypto/tls"
	"net/http"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"go.opentelemetry.io/otel"
	"go.temporal.io/sdk/client"
	temporalotel "go.temporal.io/sdk/contrib/opentelemetry"
	"go.temporal.io/sdk/converter"
	"go.temporal.io/sdk/interceptor"
	"go.temporal.io/sdk/workflow"
	grpcCodes "google.golang.org/grpc/codes"
)

// DefaultTemporalTaskQueue is the default worker task queue name for SMITH orchestration.
const DefaultTemporalTaskQueue = "rice-smith"

// Temporal wraps a Temporal [client.Client] with SMITH namespace, default task queue, and observability wiring.
type Temporal struct {
	Client    client.Client
	Namespace string
	TaskQueue string
}

// ConnectTemporal dials Temporal with OpenTelemetry metrics + tracing, SMITH header propagation, and client logging.
// For mutual TLS, use [ConnectTemporalTLS]. hostPort is typically host:7233.
func ConnectTemporal(hostPort, namespace string) (*Temporal, error) {
	return connectTemporalWithDataConverter(hostPort, namespace, nil, converter.GetDefaultDataConverter())
}

// ConnectTemporalWithDataConverter is [ConnectTemporal] with a custom payload converter (e.g. [Codec.TemporalDataConverter] from [NewCodec]).
func ConnectTemporalWithDataConverter(hostPort, namespace string, dc converter.DataConverter) (*Temporal, error) {
	return connectTemporalWithDataConverter(hostPort, namespace, nil, dc)
}

// ConnectTemporalTLS is [ConnectTemporal] with a TLS config (mTLS: set [tls.Config.ClientCertificates] and [tls.Config.RootCAs]).
func ConnectTemporalTLS(hostPort, namespace string, tlsCfg *tls.Config) (*Temporal, error) {
	return connectTemporalWithDataConverter(hostPort, namespace, tlsCfg, converter.GetDefaultDataConverter())
}

// ConnectTemporalTLSWithDataConverter is [ConnectTemporalTLS] with a custom [converter.DataConverter].
func ConnectTemporalTLSWithDataConverter(hostPort, namespace string, tlsCfg *tls.Config, dc converter.DataConverter) (*Temporal, error) {
	return connectTemporalWithDataConverter(hostPort, namespace, tlsCfg, dc)
}

func connectTemporalWithDataConverter(hostPort, namespace string, tlsCfg *tls.Config, dc converter.DataConverter) (*Temporal, error) {
	hostPort = strings.TrimSpace(hostPort)
	namespace = strings.TrimSpace(namespace)
	if hostPort == "" {
		return nil, kit.BadRequest("queue.temporal: empty hostPort")
	}
	if namespace == "" {
		return nil, kit.BadRequest("queue.temporal: empty namespace")
	}
	if dc == nil {
		dc = converter.GetDefaultDataConverter()
	}

	mh := temporalotel.NewMetricsHandler(temporalotel.MetricsHandlerOptions{
		Meter: otel.Meter("rice/queue/temporal"),
		OnError: func(err error) {
			kit.Logger().Error("queue.temporal: metrics handler error", "err", err)
		},
	})

	traceIC, err := temporalotel.NewTracingInterceptor(temporalotel.TracerOptions{
		Tracer: otel.Tracer("rice/queue/temporal"),
	})
	if err != nil {
		return nil, kit.New("QUEUE_TEMPORAL_FAILED", "queue.temporal: tracing interceptor", http.StatusServiceUnavailable, grpcCodes.Unavailable).Wrap(err, "NewTracingInterceptor")
	}

	opts := client.Options{
		HostPort:       hostPort,
		Namespace:      namespace,
		MetricsHandler: mh,
		ContextPropagators: []workflow.ContextPropagator{
			SmithKitContextPropagator(),
		},
		Interceptors: []interceptor.ClientInterceptor{
			traceIC,
			NewSmithClientInterceptor(),
		},
		DataConverter: dc,
	}

	if tlsCfg != nil {
		opts.ConnectionOptions = client.ConnectionOptions{
			TLS: tlsCfg,
		}
	}

	c, err := client.Dial(opts)
	if err != nil {
		return nil, kit.New("QUEUE_TEMPORAL_FAILED", "queue.temporal: dial failed", http.StatusServiceUnavailable, grpcCodes.Unavailable).Wrap(err, "client.Dial")
	}

	return &Temporal{
		Client:    c,
		Namespace: namespace,
		TaskQueue: DefaultTemporalTaskQueue,
	}, nil
}

// CheckHealth calls Temporal's gRPC health check.
func (t *Temporal) CheckHealth(ctx *kit.Context) error {
	if t == nil || t.Client == nil {
		return kit.BadRequest("queue.temporal: nil client")
	}
	std := context.Background()
	if ctx != nil {
		std = ctx.ToContext()
	}
	_, err := t.Client.CheckHealth(std, &client.CheckHealthRequest{})
	if err != nil {
		return kit.New("QUEUE_TEMPORAL_FAILED", "queue.temporal: health check failed", http.StatusServiceUnavailable, grpcCodes.Unavailable).Wrap(err, "CheckHealth")
	}
	return nil
}

// Close releases the Temporal client connection.
func (t *Temporal) Close() {
	if t == nil || t.Client == nil {
		return
	}
	t.Client.Close()
	t.Client = nil
}

// --- low-level helpers (existing call sites) ---

// TemporalClient is the Temporal service client used by workers and schedulers.
type TemporalClient = client.Client

// TemporalDialOptions mirrors [client.Options] for documentation; use [client.Dial].
type TemporalDialOptions = client.Options

// DialTemporal connects to Temporal with namespace, converters, and interceptors.
func DialTemporal(opts client.Options) (client.Client, error) {
	return client.Dial(opts)
}

// DialTemporalContext is like DialTemporal with a context for cancellation.
func DialTemporalContext(ctx context.Context, opts client.Options) (client.Client, error) {
	return client.DialContext(ctx, opts)
}

// DefaultDataConverter returns the SDK default payload converter stack.
func DefaultDataConverter() converter.DataConverter {
	return converter.GetDefaultDataConverter()
}

// ClientInterceptor is a Temporal client interceptor (see [interceptor] package).
type ClientInterceptor = interceptor.ClientInterceptor

// Interceptor is the combined client+worker interceptor.
type Interceptor = interceptor.Interceptor
