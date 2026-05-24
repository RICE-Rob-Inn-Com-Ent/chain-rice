package queue

import (
	"context"
	"log/slog"
	"strings"
	"sync"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"go.temporal.io/sdk/client"
)

// Queue is the SMITH orchestration facade: NATS core, JetStream, KV, Temporal, publish/subscribe helpers, and bridge hooks.
// Embed [Publisher] and [Subscriber] so callers can use [Queue.Publish] and [Queue.Subscribe] on the same value.
//
// Construct with [NewQueue]; shut down with [Queue.Close] (stops the worker if [Queue.StartWorker] was used, then Temporal, then drains and closes NATS).
type Queue struct {
	*Publisher
	*Subscriber

	// Nats is the resilient NATS wrapper from [ConnectNats].
	Nats *Nats
	// Temporal holds the dialled Temporal client and task queue name used by workers and [Queue.StartWorkflow].
	Temporal *Temporal
	// JS is the JetStream v2 API handle from [InitJetStream].
	JS jetstream.JetStream
	// KV is the SMITH state bucket from [InitKV].
	KV jetstream.KeyValue
	// Codec is the SMITH payload stack ([NewCodec]); Temporal uses [Codec.TemporalDataConverter].
	Codec *Codec
	// Options is the config snapshot passed to [NewQueue] (including normalized KV bucket name).
	Options *Config

	workerMu     sync.Mutex
	workerCancel context.CancelFunc
	workerDone   chan struct{}
	closed       bool
}

// NewQueue connects NATS, JetStream, the SMITH KV bucket, and Temporal using [Config], wiring the SMITH [Codec] into Temporal.
// ctx carries trace and metadata for downstream operations; it may be nil.
func NewQueue(ctx *kit.Context, cfg Config) (*Queue, error) {
	cfgCopy := cfg
	if strings.TrimSpace(cfgCopy.NATSURL) == "" {
		return nil, kit.BadRequest("queue: empty NATSURL")
	}
	if strings.TrimSpace(cfgCopy.TemporalHostPort) == "" {
		return nil, kit.BadRequest("queue: empty TemporalHostPort")
	}
	if strings.TrimSpace(cfgCopy.TemporalNamespace) == "" {
		return nil, kit.BadRequest("queue: empty TemporalNamespace")
	}
	if strings.TrimSpace(cfgCopy.KVBucket) == "" {
		cfgCopy.KVBucket = DefaultSmithKVBucket
	}

	codec := NewCodec()

	n, err := ConnectNats(cfgCopy.NATSURL)
	if err != nil {
		return nil, err
	}
	nc := n.Conn()
	if nc == nil {
		n.Close()
		return nil, kit.BadRequest("queue: NATS connection nil")
	}

	js, err := InitJetStream(nc)
	if err != nil {
		n.Close()
		return nil, err
	}

	kv, err := InitKV(js, cfgCopy.KVBucket)
	if err != nil {
		n.Close()
		return nil, err
	}

	tmp, err := ConnectTemporalWithDataConverter(cfgCopy.TemporalHostPort, cfgCopy.TemporalNamespace, codec.TemporalDataConverter())
	if err != nil {
		n.Close()
		return nil, err
	}
	tmp.TaskQueue = cfgCopy.Queue.TaskQueue()

	if ctx != nil && ctx.TraceID.IsValid() {
		kit.Logger().Info("queue.new",
			slog.String("trace_id", ctx.TraceID.String()),
			slog.String("task_queue", tmp.TaskQueue),
		)
	}

	q := &Queue{
		Publisher:  NewPublisher(nc, js),
		Subscriber: NewSubscriber(nc),
		Nats:       n,
		Temporal:   tmp,
		JS:         js,
		KV:         kv,
		Codec:      codec,
		Options:    &cfgCopy,
	}
	return q, nil
}

// StartWorker runs the Temporal worker in the background until [Queue.Close] cancels it.
// It registers bundled workflows, the provided activities, and uses [Config.Queue] for concurrency defaults.
func (q *Queue) StartWorker(ctx *kit.Context, activities *Activities) error {
	if q == nil {
		return kit.BadRequest("queue: nil")
	}
	q.workerMu.Lock()
	defer q.workerMu.Unlock()
	if q.closed {
		return kit.BadRequest("queue: closed")
	}
	if q.workerCancel != nil {
		return kit.Conflict("queue: worker already running")
	}
	if q.Temporal == nil || q.Temporal.Client == nil {
		return kit.BadRequest("queue: nil temporal client")
	}

	parentStd := context.Background()
	if ctx != nil {
		parentStd = ctx.ToContext()
	}
	wCtx, cancel := context.WithCancel(parentStd)
	q.workerCancel = cancel
	q.workerDone = make(chan struct{})

	var meta *kit.Metadata
	if ctx != nil && ctx.Meta != nil {
		meta = ctx.Meta.Clone()
	}
	kWorker := kit.NewContext(wCtx, meta)

	tq := q.Temporal.TaskQueue
	if q.Options != nil {
		tq = q.Options.Queue.TaskQueue()
	}

	go func() {
		defer close(q.workerDone)
		_ = RunWorker(kWorker, tq, WorkerDeps{
			Client:     q.Temporal.Client,
			Activities: activities,
			Queue:      queueOptsFromPtr(q.Options),
		})
	}()
	return nil
}

func queueOptsFromPtr(cfg *Config) QueueOptions {
	if cfg == nil {
		return NewQueueOptions()
	}
	return cfg.Queue
}

// StartWorkflow executes a workflow using the queue's Temporal client. If opts.TaskQueue is empty, [Temporal.TaskQueue] is filled in.
// ctx propagates SMITH trace headers via the Temporal client interceptors.
func (q *Queue) StartWorkflow(ctx *kit.Context, opts client.StartWorkflowOptions, workflow interface{}, args ...interface{}) (client.WorkflowRun, error) {
	if q == nil || q.Temporal == nil || q.Temporal.Client == nil {
		return nil, kit.BadRequest("queue: nil temporal client")
	}
	if workflow == nil {
		return nil, kit.BadRequest("queue: nil workflow")
	}
	std := context.Background()
	if ctx != nil {
		std = ctx.ToContext()
	}
	if strings.TrimSpace(opts.TaskQueue) == "" {
		opts.TaskQueue = q.Temporal.TaskQueue
	}
	return q.Temporal.Client.ExecuteWorkflow(std, opts, workflow, args...)
}

// BridgeToTemporal subscribes to a NATS subject and starts a Temporal workflow per message ([NatsToTemporalBridge]).
func (q *Queue) BridgeToTemporal(ctx *kit.Context, subject string, workflowFunc interface{}) (*nats.Subscription, error) {
	if q == nil || q.Nats == nil || q.Temporal == nil {
		return nil, kit.BadRequest("queue: nil bridge dependency")
	}
	return NatsToTemporalBridge(ctx, q.Nats.Conn(), q.Temporal, subject, workflowFunc)
}

// Health returns a coarse status map for NATS connection state, JetStream availability, and Temporal gRPC health.
func (q *Queue) Health(ctx *kit.Context) map[string]string {
	out := map[string]string{
		"nats":       "uninitialized",
		"jetstream":  "uninitialized",
		"temporal":   "uninitialized",
		"kv":         "uninitialized",
		"task_queue": "",
	}
	if q == nil {
		return out
	}
	if q.Nats != nil {
		out["nats"] = q.Nats.Status()
	}
	if q.JS != nil {
		out["jetstream"] = "ok"
	} else {
		out["jetstream"] = "unavailable"
	}
	if q.KV != nil {
		out["kv"] = "ok"
	}
	if q.Temporal != nil {
		out["task_queue"] = q.Temporal.TaskQueue
		if q.Temporal.Client != nil {
			if err := q.Temporal.CheckHealth(ctx); err != nil {
				out["temporal"] = err.Error()
			} else {
				out["temporal"] = "ok"
			}
		}
	}
	return out
}

// Close stops the background worker (if any), closes the Temporal client, drains NATS subscriptions, then closes NATS.
// It is safe to call more than once.
func (q *Queue) Close(ctx *kit.Context) error {
	if q == nil {
		return nil
	}
	if ctx != nil && ctx.TraceID.IsValid() {
		kit.Logger().Info("queue.close",
			slog.String("trace_id", ctx.TraceID.String()),
		)
	}

	q.workerMu.Lock()
	if q.closed {
		q.workerMu.Unlock()
		return nil
	}
	q.closed = true
	cancel := q.workerCancel
	doneCh := q.workerDone
	q.workerCancel = nil
	q.workerMu.Unlock()

	if cancel != nil {
		cancel()
	}
	if doneCh != nil {
		<-doneCh
	}

	if q.Temporal != nil {
		q.Temporal.Close()
	}

	if q.Nats != nil {
		if nc := q.Nats.Conn(); nc != nil {
			_ = Drain(nc)
		}
		q.Nats.Close()
	}

	return nil
}
