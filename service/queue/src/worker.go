package queue

import (
	"context"
	"log/slog"
	"os"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/interceptor"
	"go.temporal.io/sdk/worker"
)

// WorkerDeps configures [RunWorker]: Temporal client, activity host, identity, and optional shutdown hooks.
// Set [WorkerDeps.Shutdown] to close NATS, the Temporal wrapper, or other resources after the worker stops.
type WorkerDeps struct {
	Client client.Client

	// Activities is the activity struct passed to [RegisterActivities]. If nil, an empty [Activities] is used
	// and [Client] is wired into it when non-nil.
	Activities *Activities

	// Identity is used for logs and for [worker.Options.Identity] when [WorkerDeps.Options.Identity] is empty.
	// Default when both are empty: Worker-<hostname>-Active.
	Identity string

	// Queue supplies defaults such as [QueueOptions.MaxConcurrentActivities] when [WorkerDeps.Options] leaves them zero.
	Queue QueueOptions

	// Options are merged with SMITH defaults (identity, concurrency from Queue, Smith worker interceptor when no interceptors set).
	Options worker.Options

	// RegisterExtras registers additional workflows or activity structs after bundled registrations.
	RegisterExtras func(w worker.Worker, activities *Activities)

	// Shutdown runs after the worker has fully stopped (e.g. temporal.Close, nats.Close). Errors are logged, not returned.
	Shutdown func()
}

// TemporalWorker hosts registered workflows and activities.
type TemporalWorker = worker.Worker

// WorkerOptions configures pollers, identity, and interceptors for a worker.
type WorkerOptions = worker.Options

// NewTemporalWorker builds a worker for the given task queue.
func NewTemporalWorker(c client.Client, taskQueue string, opts worker.Options) worker.Worker {
	return worker.New(c, taskQueue, opts)
}

// WorkerInterruptCh returns the usual OS signal channel for worker.Run.
func WorkerInterruptCh() <-chan interface{} {
	return worker.InterruptCh()
}

// RegisterBundledWorkflows registers SMITH template workflows shipped with this package (e.g. [ManagedTemplateWorkflow]).
func RegisterBundledWorkflows(w worker.Worker) {
	if w == nil {
		return
	}
	w.RegisterWorkflow(ManagedTemplateWorkflow)
}

// RunWorker starts a Temporal worker on taskQueue until ctx is cancelled or [worker.InterruptCh] fires, then stops gracefully
// and runs [WorkerDeps.Shutdown]. Registers bundled workflows, [RegisterActivities], and optional [WorkerDeps.RegisterExtras].
//
// taskQueue may be empty to use [QueueOptions.TaskQueue] from deps.Queue, then [DefaultTemporalTaskQueue].
func RunWorker(ctx *kit.Context, taskQueue string, deps WorkerDeps) error {
	if deps.Client == nil {
		return kit.BadRequest("queue.worker: nil Client")
	}
	std := context.Background()
	if ctx != nil {
		std = ctx.ToContext()
	}

	tq := strings.TrimSpace(taskQueue)
	if tq == "" {
		tq = deps.Queue.TaskQueue()
	}

	acts := deps.Activities
	if acts == nil {
		acts = &Activities{}
	}
	if acts.Client == nil {
		acts.Client = deps.Client
	}

	opts := mergeWorkerOptions(deps)

	lg := kit.Logger()
	lg.Info("queue.worker.starting",
		slog.String("task_queue", tq),
		slog.String("worker_identity", opts.Identity),
	)

	w := worker.New(deps.Client, tq, opts)
	RegisterBundledWorkflows(w)
	RegisterActivities(w, acts)
	if deps.RegisterExtras != nil {
		deps.RegisterExtras(w, acts)
	}

	runErr := make(chan error, 1)
	go func() {
		runErr <- w.Run(worker.InterruptCh())
	}()

	var err error
	select {
	case <-std.Done():
		lg.Info("queue.worker.shutdown",
			slog.String("reason", "context_done"),
			slog.String("worker_identity", opts.Identity),
		)
		w.Stop()
		err = <-runErr
	case err = <-runErr:
		if err != nil {
			lg.Warn("queue.worker.run_ended",
				slog.String("worker_identity", opts.Identity),
				slog.Any("err", err),
			)
		}
	}

	if deps.Shutdown != nil {
		deps.Shutdown()
	}
	if err != nil {
		return kit.Err.Internal("queue.worker: run error").Wrap(err, "worker.Run")
	}
	return nil
}

func mergeWorkerOptions(deps WorkerDeps) worker.Options {
	opts := deps.Options

	id := strings.TrimSpace(opts.Identity)
	if id == "" {
		id = strings.TrimSpace(deps.Identity)
	}
	if id == "" {
		id = defaultWorkerIdentity()
	}
	opts.Identity = id

	if len(opts.Interceptors) == 0 {
		opts.Interceptors = []interceptor.WorkerInterceptor{NewSmithQueueInterceptor()}
	}

	q := deps.Queue
	if opts.MaxConcurrentActivityExecutionSize == 0 && q.MaxConcurrentActivities > 0 {
		opts.MaxConcurrentActivityExecutionSize = q.MaxConcurrentActivities
	}

	return opts
}

func defaultWorkerIdentity() string {
	h, err := os.Hostname()
	if err != nil || strings.TrimSpace(h) == "" {
		h = "unknown-node"
	}
	return "Worker-" + h + "-Active"
}
