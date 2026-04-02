package queue

// TODO:
// [ ] implement Temporal schedules:
//     CreateSchedule(ctx, client, id string, spec ScheduleSpec) error
//     UpdateSchedule(ctx, client, id string, spec ScheduleSpec) error
//     DeleteSchedule(ctx, client, id string) error
// [ ] implement kingdom schedules:
//     snapshot: cron from RICE_SCHEDULE_SNAPSHOT_CRON env var
//     audit: cron from RICE_SCHEDULE_AUDIT_CRON env var
//     model-sync: cron from RICE_SCHEDULE_MODEL_SYNC_CRON env var

import (
	"context"

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
