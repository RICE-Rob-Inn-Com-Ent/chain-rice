package web

// TODO:
// [ ] implement async job submission from web layer:
//     SubmitJob(ctx, workflowType string, input any) (workflowID, error)
//     delegates to queue/ Temporal client
//     workflowID = UUID v7 — sortable for tracing
// [ ] implement job status polling:
//     GetJobStatus(ctx, workflowID string) (JobStatus, error)
//     delegates to queue/ Temporal query
// [ ] implement webhook callbacks:
//     RegisterWebhook(ctx, workflowID, callbackURL string) error
//     Temporal signal triggers webhook on completion
//     callbackURL validated against RICE_WEBHOOK_ALLOWLIST env var

import (
	"context"

	"gocloud.dev/pubsub"
	_ "gocloud.dev/pubsub/awssnssqs"
	_ "gocloud.dev/pubsub/azuresb"
	_ "gocloud.dev/pubsub/gcppubsub"
)

// OpenTopic opens a pubsub topic from URL (driver packages must be imported for scheme registration).
func OpenTopic(ctx context.Context, urlstr string) (*pubsub.Topic, error) {
	return pubsub.OpenTopic(ctx, urlstr)
}

// OpenSubscription opens a subscription for receive loops.
func OpenSubscription(ctx context.Context, urlstr string) (*pubsub.Subscription, error) {
	return pubsub.OpenSubscription(ctx, urlstr)
}
