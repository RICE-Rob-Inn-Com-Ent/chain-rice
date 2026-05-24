package queue

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"sync"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

const (
	defaultConsumerFetchBatch   = 10
	defaultConsumerFetchMaxWait = 5 * time.Second
	defaultPullWorkers          = 4
)

// JSMsgHandler processes a JetStream pull message. Return nil to Ack; any error triggers NakWithDelay backoff.
type JSMsgHandler func(*kit.Context, jetstream.Msg) error

// PullConsumer runs a durable JetStream pull consumer ([jetstream.JetStream.Consumer]) until goCtx is cancelled.
// It batches via [jetstream.Consumer.Fetch], processes messages with a bounded worker pool ([QueueOptions.MaxConcurrentActivities],
// default 4), Ack on success, and [jetstream.Msg.NakWithDelay] with exponential backoff on handler error so slow
// downstreams do not tight-loop redelivery.
//
// The durable consumer must already exist (for example via [EnsureDurableConsumer]). [QueueOptions.ConsumerFetchBatch]
// and [QueueOptions.ConsumerFetchMaxWait] tune pull flow; zero values use package defaults.
func PullConsumer(root *kit.Context, js jetstream.JetStream, stream, durableName string, handler JSMsgHandler, q QueueOptions) error {
	if js == nil {
		return errors.New("queue.consumer: nil JetStream")
	}
	stream = strings.TrimSpace(stream)
	durableName = strings.TrimSpace(durableName)
	if stream == "" || durableName == "" {
		return errors.New("queue.consumer: empty stream or durable name")
	}
	if handler == nil {
		return errors.New("queue.consumer: nil handler")
	}

	goCtx := context.Background()
	if root != nil {
		goCtx = root.ToContext()
	}

	cons, err := js.Consumer(goCtx, stream, durableName)
	if err != nil {
		return err
	}

	batchSize := consumerFetchBatch(q)
	maxWait := consumerFetchMaxWait(q)
	workers := q.MaxConcurrentActivities
	if workers <= 0 {
		workers = defaultPullWorkers
	}
	sem := make(chan struct{}, workers)

	for {
		if err := goCtx.Err(); err != nil {
			return err
		}

		batch, err := cons.Fetch(batchSize, jetstream.FetchMaxWait(maxWait))
		if err != nil {
			if errors.Is(err, context.Canceled) || errors.Is(err, goCtx.Err()) {
				return err
			}
			kit.Logger().Warn("queue.consumer.pull_fetch_failed",
				slog.String("stream", stream),
				slog.String("durable", durableName),
				slog.String("err", err.Error()),
			)
			time.Sleep(200 * time.Millisecond)
			continue
		}

		var wg sync.WaitGroup
		for msg := range batch.Messages() {
			m := msg
			select {
			case <-goCtx.Done():
				wg.Wait()
				return goCtx.Err()
			case sem <- struct{}{}:
			}
			wg.Add(1)
			go func() {
				defer func() { <-sem; wg.Done() }()
				handlePullMessage(root, m, handler)
			}()
		}
		wg.Wait()

		if err := batch.Error(); err != nil {
			kit.Logger().Warn("queue.consumer.batch_error",
				slog.String("stream", stream),
				slog.String("durable", durableName),
				slog.String("err", err.Error()),
			)
		}
	}
}

func consumerFetchBatch(q QueueOptions) int {
	if q.ConsumerFetchBatch > 0 {
		return q.ConsumerFetchBatch
	}
	return defaultConsumerFetchBatch
}

func consumerFetchMaxWait(q QueueOptions) time.Duration {
	if q.ConsumerFetchMaxWait > 0 {
		return q.ConsumerFetchMaxWait
	}
	return defaultConsumerFetchMaxWait
}

func handlePullMessage(root *kit.Context, m jetstream.Msg, handler JSMsgHandler) {
	if m == nil {
		return
	}
	nm := natsMsgFromJetStream(m)
	traceCtx := ExtractTrace(nm)
	var meta *kit.Metadata
	if root != nil && root.Meta != nil {
		meta = root.Meta.Clone()
	}
	kctx := kit.NewContext(traceCtx, meta)

	if err := handler(kctx, m); err != nil {
		delay := nakBackoffDelay(m)
		if nakErr := m.NakWithDelay(delay); nakErr != nil {
			kit.Logger().Warn("queue.consumer.nak_failed",
				slog.String("subject", m.Subject()),
				slog.String("err", nakErr.Error()),
			)
		}
		return
	}
	if ackErr := m.Ack(); ackErr != nil {
		kit.Logger().Warn("queue.consumer.ack_failed",
			slog.String("subject", m.Subject()),
			slog.String("err", ackErr.Error()),
		)
	}
}

func natsMsgFromJetStream(m jetstream.Msg) *nats.Msg {
	nm := nats.NewMsg(m.Subject())
	nm.Data = m.Data()
	if h := m.Headers(); h != nil {
		nm.Header = cloneNATSHeader(h)
	}
	nm.Reply = m.Reply()
	return nm
}

func cloneNATSHeader(h nats.Header) nats.Header {
	if h == nil {
		return nil
	}
	out := make(nats.Header, len(h))
	for k, v := range h {
		cp := make([]string, len(v))
		copy(cp, v)
		out[k] = cp
	}
	return out
}

// nakBackoffDelay returns 2^(delivery-1) seconds capped at 60s (minimum 1s) using [jetstream.MsgMetadata.NumDelivered].
func nakBackoffDelay(m jetstream.Msg) time.Duration {
	meta, err := m.Metadata()
	if err != nil || meta == nil {
		return time.Second
	}
	n := meta.NumDelivered
	if n < 1 {
		n = 1
	}
	shift := n - 1
	if shift > 6 {
		shift = 6
	}
	d := time.Duration(uint64(1)<<uint(shift)) * time.Second
	if d > 60*time.Second {
		d = 60 * time.Second
	}
	if d < time.Second {
		d = time.Second
	}
	return d
}

// --- legacy JetStream manager (nats.JetStreamContext) ---

// AddConsumer creates or updates a consumer on JetStream (legacy API).
func AddConsumer(js nats.JetStreamContext, stream string, cfg *nats.ConsumerConfig, opts ...nats.JSOpt) (*nats.ConsumerInfo, error) {
	return js.AddConsumer(stream, cfg, opts...)
}

// UpdateConsumer updates an existing consumer (legacy API).
func UpdateConsumer(js nats.JetStreamContext, stream string, cfg *nats.ConsumerConfig, opts ...nats.JSOpt) (*nats.ConsumerInfo, error) {
	return js.UpdateConsumer(stream, cfg, opts...)
}

// DeleteConsumer removes a consumer (legacy API).
func DeleteConsumer(js nats.JetStreamContext, stream, consumer string, opts ...nats.JSOpt) error {
	return js.DeleteConsumer(stream, consumer, opts...)
}

// GetConsumerInfo returns consumer info (legacy API).
func GetConsumerInfo(js nats.JetStreamContext, stream, name string, opts ...nats.JSOpt) (*nats.ConsumerInfo, error) {
	return js.ConsumerInfo(stream, name, opts...)
}

// JSSubscribe creates a push consumer subscription (see nats.SubOpt for Durable, Bind, etc.).
func JSSubscribe(js nats.JetStreamContext, subj string, cb nats.MsgHandler, opts ...nats.SubOpt) (*nats.Subscription, error) {
	return js.Subscribe(subj, cb, opts...)
}

// JSPullSubscribe creates a pull consumer; use [PullFetch] to read messages.
func JSPullSubscribe(js nats.JetStreamContext, subj, durable string, opts ...nats.SubOpt) (*nats.Subscription, error) {
	return js.PullSubscribe(subj, durable, opts...)
}

// PullFetch requests up to batch messages from a pull subscription.
func PullFetch(sub *nats.Subscription, batch int, opts ...nats.PullOpt) ([]*nats.Msg, error) {
	return sub.Fetch(batch, opts...)
}

// Ack acknowledges a JetStream message.
func Ack(m *nats.Msg, opts ...nats.AckOpt) error {
	return m.Ack(opts...)
}

// Nak negatively acknowledges (redelivery).
func Nak(m *nats.Msg, opts ...nats.AckOpt) error {
	return m.Nak(opts...)
}

// InProgress marks a message as work-in-progress (extends ack wait).
func InProgress(m *nats.Msg, opts ...nats.AckOpt) error {
	return m.InProgress(opts...)
}

// Term terminates delivery (no redelivery).
func Term(m *nats.Msg, opts ...nats.AckOpt) error {
	return m.Term(opts...)
}

// Re-export consumer config types.
type (
	ConsumerConfig = nats.ConsumerConfig
	AckPolicy      = nats.AckPolicy
	DeliverPolicy  = nats.DeliverPolicy
)
