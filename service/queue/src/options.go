package queue

import (
	"math"
	"time"

	"go.temporal.io/sdk/temporal"
)

// DefaultRetryPolicy returns the SMITH default Temporal retry policy: exponential backoff with a 60s cap.
// MaximumAttempts is 0 (unlimited); cap attempts with [QueueOptions.TemporalRetryPolicy] after [WithMaxRetries].
func DefaultRetryPolicy() temporal.RetryPolicy {
	return temporal.RetryPolicy{
		InitialInterval:    time.Second,
		MaximumInterval:    60 * time.Second,
		BackoffCoefficient: 2.0,
		MaximumAttempts:    0,
	}
}

// QueueOptions holds settings shared by Temporal workers and NATS consumers (timeouts, concurrency, task queue, ack behavior).
type QueueOptions struct {
	// MaxConcurrentActivities is passed to the Temporal worker (e.g. worker.Options.MaxConcurrentActivityExecutionSize).
	// Zero means callers should apply their own default when building worker options.
	MaxConcurrentActivities int

	// TaskQueueName is the Temporal task queue and the logical queue name for NATS routing docs.
	TaskQueueName string

	// WorkflowExecutionTimeout bounds workflow runs when starting workflows from the client.
	WorkflowExecutionTimeout time.Duration

	// AckWait is the NATS JetStream ack wait / consumer ack deadline (e.g. PullSubscribe AckWait).
	AckWait time.Duration

	// ConsumerFetchBatch is the JetStream pull batch size for [PullConsumer]. Zero defaults to 10.
	ConsumerFetchBatch int

	// ConsumerFetchMaxWait is the max wait per [jetstream.Consumer.Fetch] call. Zero defaults to 5s.
	ConsumerFetchMaxWait time.Duration

	// MaxRetries caps Temporal retries when building a policy via [QueueOptions.TemporalRetryPolicy] (0 = unlimited).
	MaxRetries int32
}

// Option configures [QueueOptions].
type Option func(*QueueOptions)

// NewQueueOptions returns defaults merged with any functional options.
func NewQueueOptions(opts ...Option) QueueOptions {
	q := defaultQueueOptions()
	for _, o := range opts {
		if o != nil {
			o(&q)
		}
	}
	return q
}

func defaultQueueOptions() QueueOptions {
	return QueueOptions{
		MaxConcurrentActivities:  0,
		TaskQueueName:            DefaultTemporalTaskQueue,
		WorkflowExecutionTimeout: time.Hour,
		AckWait:                  30 * time.Second,
		ConsumerFetchBatch:       0,
		ConsumerFetchMaxWait:     0,
		MaxRetries:               0,
	}
}

// WithTimeout sets [QueueOptions.WorkflowExecutionTimeout] (Temporal workflow run budget from the client).
func WithTimeout(d time.Duration) Option {
	return func(q *QueueOptions) {
		if q == nil || d <= 0 {
			return
		}
		q.WorkflowExecutionTimeout = d
	}
}

// WithMaxRetries sets [QueueOptions.MaxRetries] for [QueueOptions.TemporalRetryPolicy] (Temporal MaximumAttempts).
func WithMaxRetries(n int) Option {
	return func(q *QueueOptions) {
		if q == nil || n < 0 {
			return
		}
		if n > math.MaxInt32 {
			n = math.MaxInt32
		}
		q.MaxRetries = int32(n)
	}
}

// WithTaskQueue sets [QueueOptions.TaskQueueName] for Temporal workers and NATS naming.
func WithTaskQueue(name string) Option {
	return func(q *QueueOptions) {
		if q == nil || name == "" {
			return
		}
		q.TaskQueueName = name
	}
}

// WithMaxConcurrentActivities sets [QueueOptions.MaxConcurrentActivities].
func WithMaxConcurrentActivities(n int) Option {
	return func(q *QueueOptions) {
		if q == nil || n < 0 {
			return
		}
		q.MaxConcurrentActivities = n
	}
}

// WithAckWait sets [QueueOptions.AckWait] for NATS consumers.
func WithAckWait(d time.Duration) Option {
	return func(q *QueueOptions) {
		if q == nil || d <= 0 {
			return
		}
		q.AckWait = d
	}
}

// WithConsumerFetchBatch sets the JetStream pull batch size for [PullConsumer].
func WithConsumerFetchBatch(n int) Option {
	return func(q *QueueOptions) {
		if q == nil || n < 0 {
			return
		}
		q.ConsumerFetchBatch = n
	}
}

// WithConsumerFetchMaxWait sets the max wait for each JetStream [jetstream.Consumer.Fetch] in [PullConsumer].
func WithConsumerFetchMaxWait(d time.Duration) Option {
	return func(q *QueueOptions) {
		if q == nil || d <= 0 {
			return
		}
		q.ConsumerFetchMaxWait = d
	}
}

// TemporalRetryPolicy returns [DefaultRetryPolicy] merged with [QueueOptions.MaxRetries].
func (q QueueOptions) TemporalRetryPolicy() temporal.RetryPolicy {
	p := DefaultRetryPolicy()
	if q.MaxRetries > 0 {
		p.MaximumAttempts = q.MaxRetries
	}
	return p
}

// TaskQueue returns a non-empty task queue name, falling back to [DefaultTemporalTaskQueue].
func (q QueueOptions) TaskQueue() string {
	if q.TaskQueueName != "" {
		return q.TaskQueueName
	}
	return DefaultTemporalTaskQueue
}

// Config bundles connection endpoints for main-style initialization of NATS and Temporal.
type Config struct {
	NATSURL           string
	TemporalHostPort  string
	TemporalNamespace string

	// KVBucket is the JetStream KV name for SMITH state ([InitKV]). Empty defaults to [DefaultSmithKVBucket].
	KVBucket string

	// Queue is applied to workers and messaging; use [NewQueueOptions] or set fields directly.
	Queue QueueOptions
}

// NewConfig returns a Config with default [QueueOptions] and the given endpoints.
func NewConfig(natsURL, temporalHostPort, temporalNamespace string, opts ...Option) Config {
	return Config{
		NATSURL:           natsURL,
		TemporalHostPort:  temporalHostPort,
		TemporalNamespace: temporalNamespace,
		Queue:             NewQueueOptions(opts...),
	}
}
