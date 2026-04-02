package queue

// TODO:
// [ ] implement Temporal activities:
//     activities are single units of work within workflows
//     each activity has: retry policy, timeout, heartbeat
// [ ] implement kingdom activities:
//     DBSnapshotActivity — calls database/snapshot.go
//     EmailActivity — calls web/mail.go
//     NATSPublishActivity — calls publish.go
//     InferenceActivity — calls SAGE via ConnectRPC
//     ProofActivity — calls CLERK ZK via ConnectRPC
// [ ] all activity timeouts from env vars:
//     RICE_ACTIVITY_{NAME}_TIMEOUT_S — per activity

import (
	"context"

	"go.temporal.io/sdk/activity"
	"go.temporal.io/sdk/temporal"
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
