package queue

import (
	"context"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"go.temporal.io/sdk/client"
)

// ScheduleClient manages cron/interval schedules in Temporal.
type ScheduleClient = client.ScheduleClient

// ScheduleHandle is a live schedule (pause, trigger, describe, delete).
type ScheduleHandle = client.ScheduleHandle

// ScheduleOptions is passed to CreateSchedule.
type ScheduleOptions = client.ScheduleOptions

// ScheduleSpec combines calendar, intervals, and exclusions.
type ScheduleSpec = client.ScheduleSpec

// ScheduleCalendarSpec describes calendar-based triggers.
type ScheduleCalendarSpec = client.ScheduleCalendarSpec

// ScheduleIntervalSpec describes fixed-interval triggers.
type ScheduleIntervalSpec = client.ScheduleIntervalSpec

// ScheduleWorkflowAction starts a workflow from a schedule.
type ScheduleWorkflowAction = client.ScheduleWorkflowAction

// ScheduleBackfill replays missed windows.
type ScheduleBackfill = client.ScheduleBackfill

// ScheduleBackfillOptions configures backfill execution.
type ScheduleBackfillOptions = client.ScheduleBackfillOptions

// SchedulePauseOptions configures pause (note, reason).
type SchedulePauseOptions = client.SchedulePauseOptions

// ScheduleUnpauseOptions configures unpause.
type ScheduleUnpauseOptions = client.ScheduleUnpauseOptions

// ScheduleListOptions filters schedule listing.
type ScheduleListOptions = client.ScheduleListOptions

// ScheduleTriggerOptions configures a manual trigger (overlap override).
type ScheduleTriggerOptions = client.ScheduleTriggerOptions

// NewScheduleClient returns the schedule sub-client from a Temporal client.
func NewScheduleClient(c client.Client) client.ScheduleClient {
	return c.ScheduleClient()
}

// CreateSchedule registers a new schedule.
func CreateSchedule(ctx context.Context, sc client.ScheduleClient, opts client.ScheduleOptions) (client.ScheduleHandle, error) {
	return sc.Create(ctx, opts)
}

// ListSchedules returns an iterator of schedule entries.
func ListSchedules(ctx context.Context, sc client.ScheduleClient, opts client.ScheduleListOptions) (client.ScheduleListIterator, error) {
	return sc.List(ctx, opts)
}

// GetScheduleHandle returns a handle for an existing schedule ID.
func GetScheduleHandle(ctx context.Context, sc client.ScheduleClient, scheduleID string) client.ScheduleHandle {
	return sc.GetHandle(ctx, scheduleID)
}

// CreateCronJob creates a recurring Temporal schedule from a cron spec (e.g. "@hourly", "0 * * * *", "CRON_TZ=America/New_York 0 3 * * *").
// workflow is the workflow function or registered workflow name. taskQueue must match workers polling that queue.
// wfArgs are optional payloads passed to the workflow on each run (e.g. cache name, sync flags).
// Queue timeouts and workflow retry policy default from q; pass [NewQueueOptions] for custom budgets.
func CreateCronJob(ctx *kit.Context, sc client.ScheduleClient, id, cronSpec, taskQueue string, workflow interface{}, q QueueOptions, wfArgs ...interface{}) (client.ScheduleHandle, error) {
	if sc == nil {
		return nil, kit.BadRequest("queue.schedule: nil ScheduleClient")
	}
	id = strings.TrimSpace(id)
	cronSpec = strings.TrimSpace(cronSpec)
	taskQueue = strings.TrimSpace(taskQueue)
	if id == "" || cronSpec == "" || taskQueue == "" {
		return nil, kit.BadRequest("queue.schedule: id, cron spec, and taskQueue are required")
	}
	if workflow == nil {
		return nil, kit.BadRequest("queue.schedule: workflow is required")
	}

	std := context.Background()
	if ctx != nil {
		std = ctx.ToContext()
	}

	rp := q.TemporalRetryPolicy()
	action := &client.ScheduleWorkflowAction{
		Workflow:                 workflow,
		TaskQueue:                taskQueue,
		Args:                     wfArgs,
		WorkflowExecutionTimeout: q.WorkflowExecutionTimeout,
		RetryPolicy:              &rp,
	}

	opts := client.ScheduleOptions{
		ID:     id,
		Spec:   client.ScheduleSpec{CronExpressions: []string{cronSpec}},
		Action: action,
	}

	return sc.Create(std, opts)
}

// CreateCronJobWithDefaults is [CreateCronJob] with [NewQueueOptions] (default execution timeout and retry policy).
func CreateCronJobWithDefaults(ctx *kit.Context, sc client.ScheduleClient, id, cronSpec, taskQueue string, workflow interface{}, wfArgs ...interface{}) (client.ScheduleHandle, error) {
	return CreateCronJob(ctx, sc, id, cronSpec, taskQueue, workflow, NewQueueOptions(), wfArgs...)
}

// TriggerImmediate runs one schedule action now (testing, catch-up, or emergency runs).
func TriggerImmediate(ctx *kit.Context, sc client.ScheduleClient, scheduleID string) error {
	if sc == nil {
		return kit.BadRequest("queue.schedule: nil ScheduleClient")
	}
	scheduleID = strings.TrimSpace(scheduleID)
	if scheduleID == "" {
		return kit.BadRequest("queue.schedule: empty scheduleID")
	}
	std := context.Background()
	if ctx != nil {
		std = ctx.ToContext()
	}
	h := sc.GetHandle(std, scheduleID)
	return h.Trigger(std, client.ScheduleTriggerOptions{})
}
