package queue

// TODO:
// [ ] implement Temporal client:
//     NewClient(ctx) (client.Client, error)
//     reads TEMPORAL_URL from env
//     namespace from RICE_TEMPORAL_NAMESPACE env var
// [ ] implement workflow execution:
//     StartWorkflow(ctx, client, options, workflow, args) (WorkflowRun, error)
//     workflow options: TaskQueue, ID, RetryPolicy — all from env
// [ ] implement workflow queries:
//     QueryWorkflow(ctx, client, workflowID, queryType, args) (any, error)
// [ ] implement workflow signals:
//     SignalWorkflow(ctx, client, workflowID, signal, payload) error
// [ ] implement workflow cancellation:
//     CancelWorkflow(ctx, client, workflowID, reason string) error

import (
	"context"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/converter"
	"go.temporal.io/sdk/interceptor"
)

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
