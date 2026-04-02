package queue

// TODO:
// [ ] implement Temporal worker:
//     NewWorker(client, taskQueue string) worker.Worker
//     task queue from RICE_TEMPORAL_TASK_QUEUE env var
// [ ] implement worker registration:
//     worker.RegisterWorkflow() for all workflows
//     worker.RegisterActivity() for all activities
// [ ] implement worker options:
//     MaxConcurrentWorkflows from RICE_TEMPORAL_MAX_WORKFLOWS
//     MaxConcurrentActivities from RICE_TEMPORAL_MAX_ACTIVITIES
//     both from env vars — never hardcoded

import (
	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"
)

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
