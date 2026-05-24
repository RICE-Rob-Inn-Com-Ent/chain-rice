package queue

import (
	"context"
	"log/slog"

	"go.temporal.io/sdk/activity"
	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/worker"
	"go.temporal.io/sdk/workflow"
)

// ActivityInfo describes the running activity (task queue, attempt, etc.).
type ActivityInfo = activity.Info

// ActivityRegisterOptions configures registration-time metadata.
type ActivityRegisterOptions = activity.RegisterOptions

// RetryPolicy controls exponential retries for activities and workflows.
type RetryPolicy = temporal.RetryPolicy

// ActivityOptions configures timeouts and retry when scheduling an activity from a workflow.
type ActivityOptions = workflow.ActivityOptions

// WithActivityOptions attaches activity invocation options to workflow context.
var WithActivityOptions = workflow.WithActivityOptions

// ExecuteActivity schedules an activity from a workflow.
var ExecuteActivity = workflow.ExecuteActivity

// GetActivityInfo returns info for the current activity invocation.
func GetActivityInfo(ctx context.Context) activity.Info {
	return activity.GetInfo(ctx)
}

// RecordHeartbeat reports progress for long-running activities.
func RecordHeartbeat(ctx context.Context, details ...interface{}) {
	activity.RecordHeartbeat(ctx, details...)
}

// GetHeartbeatDetails restores details from a previous failed attempt.
func GetHeartbeatDetails(ctx context.Context, d ...interface{}) error {
	return activity.GetHeartbeatDetails(ctx, d...)
}

// Activities is the SMITH activity base struct: embed it in your app-specific struct and add methods.
// Dependencies are injected once per worker; each new exported method becomes a Temporal activity when
// you pass the concrete struct to [RegisterActivities].
//
//	DB: your persistence layer (typed in the app; stored as [any] here to keep queue free of database imports).
//	Log: optional; defaults are applied in helpers when nil.
//	Client: optional Temporal client for activities that need to drive other workflows.
type Activities struct {
	DB     any
	Log    *slog.Logger
	Client client.Client
}

func (a *Activities) logger() *slog.Logger {
	if a != nil && a.Log != nil {
		return a.Log
	}
	return slog.Default()
}

// RegisterActivities registers all exported methods on a as Temporal activities.
func RegisterActivities(w worker.Worker, a *Activities) {
	if w == nil || a == nil {
		return
	}
	w.RegisterActivity(a)
}

// Heartbeat records a Temporal activity heartbeat with optional detail payloads (training epoch, loss, etc.).
// Call this periodically in long-running work so the worker is not marked stalled when HeartbeatTimeout is set.
func (a *Activities) Heartbeat(ctx context.Context, details ...interface{}) error {
	activity.RecordHeartbeat(ctx, details...)
	return nil
}

// SagaStepNoop is a template no-op forward step; replace with real business activities on your embedded struct.
func (a *Activities) SagaStepNoop(ctx context.Context, stepName string) error {
	a.logger().InfoContext(ctx, "queue.activity.saga_step", slog.String("step", stepName))
	return nil
}

// SagaRollback is the default compensating activity used by [ManagedTemplateWorkflow]; override or register your own.
func (a *Activities) SagaRollback(ctx context.Context, in RollbackInput) error {
	a.logger().WarnContext(ctx, "queue.activity.saga_rollback",
		slog.String("step", in.Step),
		slog.String("reason", in.Reason),
		slog.String("meta", in.Meta),
	)
	return nil
}
