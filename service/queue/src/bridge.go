package queue

import (
	"errors"
	"fmt"
	"log/slog"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/google/uuid"
	"github.com/nats-io/nats.go"
	enumspb "go.temporal.io/api/enums/v1"
	"go.temporal.io/api/serviceerror"
	"go.temporal.io/sdk/client"
)

const (
	// SmithEventIDHeader is an optional publisher-defined dedupe key when JetStream Msg-Id is not set.
	SmithEventIDHeader = "Smith-Event-Id"
)

// NatsToTemporalBridge subscribes to subject and starts a Temporal workflow for each message.
// nc and tmp must be non-nil. Trace context and UserID are taken from NATS headers ([ExtractTrace]);
// service metadata from ctx is merged so [SmithKitContextPropagator] can inject trace into workflow headers.
//
// workflowFunc is passed to [client.Client.ExecuteWorkflow] with a single argument: a []byte copy of the message payload.
// Idempotency: WorkflowID is derived from subject + (Nats-Msg-Id, Smith-Event-Id, or a new UUID).
// On successful start (or duplicate start with the same ID), the message is Ack'd. On start failure, Nak triggers redelivery (JetStream).
func NatsToTemporalBridge(ctx *kit.Context, nc *nats.Conn, tmp *Temporal, subject string, workflowFunc any) (*nats.Subscription, error) {
	if nc == nil {
		return nil, errors.New("queue.bridge: nil NATS connection")
	}
	if tmp == nil || tmp.Client == nil {
		return nil, errors.New("queue.bridge: nil Temporal client")
	}
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return nil, errors.New("queue.bridge: empty subject")
	}
	if workflowFunc == nil {
		return nil, errors.New("queue.bridge: nil workflow function")
	}

	return nc.Subscribe(subject, func(msg *nats.Msg) {
		handleNatsBridgeMessage(ctx, tmp, subject, workflowFunc, msg)
	})
}

func handleNatsBridgeMessage(root *kit.Context, tmp *Temporal, subject string, workflowFunc any, msg *nats.Msg) {
	msgKit := bridgeKitContext(root, msg)
	execCtx := msgKit.ToContext()

	eventKey := natsEventDedupeKey(msg)
	wfID := temporalWorkflowID(subject, eventKey)

	lg := kit.Logger().With(
		slog.String("component", "queue.bridge"),
		slog.String("nats.subject", msg.Subject),
		slog.String("temporal.workflow_id", wfID),
		slog.String("smith.event_key", eventKey),
	)
	if msgKit.TraceID.IsValid() {
		lg = lg.With(slog.String("trace_id", msgKit.TraceID.String()))
	}

	opts := client.StartWorkflowOptions{
		ID:                    wfID,
		TaskQueue:             tmp.TaskQueue,
		WorkflowIDReusePolicy: enumspb.WORKFLOW_ID_REUSE_POLICY_REJECT_DUPLICATE,
	}

	payload := append([]byte(nil), msg.Data...)

	lg.InfoContext(execCtx, "queue.bridge.nats_to_temporal.handover",
		slog.Int("payload_bytes", len(payload)),
	)

	_, err := tmp.Client.ExecuteWorkflow(execCtx, opts, workflowFunc, payload)
	switch {
	case err == nil:
		bridgeAckMsg(msg)
	case isWorkflowDuplicateStart(err):
		lg.InfoContext(execCtx, "queue.bridge.nats_to_temporal.duplicate_workflow_id",
			slog.String("err", err.Error()),
		)
		bridgeAckMsg(msg)
	default:
		lg.WarnContext(execCtx, "queue.bridge.nats_to_temporal.start_failed",
			slog.String("err", err.Error()),
		)
		bridgeNakMsg(msg)
	}
}

func bridgeKitContext(root *kit.Context, msg *nats.Msg) *kit.Context {
	traceParent := ExtractTrace(msg)
	var meta *kit.Metadata
	if root != nil && root.Meta != nil {
		meta = root.Meta.Clone()
	}
	return kit.NewContext(traceParent, meta)
}

func natsEventDedupeKey(msg *nats.Msg) string {
	if msg == nil {
		return uuid.NewString()
	}
	if msg.Header != nil {
		if v := strings.TrimSpace(msg.Header.Get(nats.MsgIdHdr)); v != "" {
			return v
		}
		if v := strings.TrimSpace(msg.Header.Get(SmithEventIDHeader)); v != "" {
			return v
		}
	}
	return uuid.NewString()
}

func temporalWorkflowID(subject, eventKey string) string {
	base := fmt.Sprintf("%s:%s", strings.TrimSpace(subject), strings.TrimSpace(eventKey))
	return sanitizeTemporalWorkflowID(base)
}

func sanitizeTemporalWorkflowID(s string) string {
	if s == "" {
		return "smith-bridge-anon"
	}
	var b strings.Builder
	b.Grow(len(s))
	for _, r := range s {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '-', r == '_', r == '.':
			b.WriteRune(r)
		default:
			b.WriteByte('_')
		}
	}
	out := b.String()
	const maxWFID = 900
	if len(out) > maxWFID {
		out = out[:maxWFID]
	}
	return out
}

func isWorkflowDuplicateStart(err error) bool {
	var execStarted *serviceerror.WorkflowExecutionAlreadyStarted
	return errors.As(err, &execStarted)
}

func bridgeAckMsg(msg *nats.Msg) {
	if msg == nil {
		return
	}
	if err := msg.Ack(); err != nil {
		kit.Logger().Debug("queue.bridge: ack not sent (non-JetStream or no reply)",
			slog.String("err", err.Error()),
		)
	}
}

func bridgeNakMsg(msg *nats.Msg) {
	if msg == nil {
		return
	}
	if err := msg.Nak(); err != nil {
		kit.Logger().Warn("queue.bridge: nak failed",
			slog.String("err", err.Error()),
		)
	}
}
