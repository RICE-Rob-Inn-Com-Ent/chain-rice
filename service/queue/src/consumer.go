package queue

// TODO:
// [ ] implement message consumer loop:
//     Consume(ctx, sub *nats.Subscription, handler MsgHandler) error
//     fetch batch: RICE_NATS_FETCH_BATCH env var (default: 10)
//     fetch timeout: RICE_NATS_FETCH_TIMEOUT_S env var
// [ ] implement consumer error handling:
//     on handler error → NAK with delay (exponential backoff)
//     max deliveries from RICE_NATS_MAX_DELIVER env var
//     on max exceeded → publish to dead-letter subject
// [ ] implement dead-letter queue:
//     DLQ subject: {original_subject}.dlq
//     SMITH guard/ subscribes and alerts on DLQ messages

import (
	"github.com/nats-io/nats.go"
)

// Consumer CRUD on JetStream manager facet.

func AddConsumer(js nats.JetStreamContext, stream string, cfg *nats.ConsumerConfig, opts ...nats.JSOpt) (*nats.ConsumerInfo, error) {
	return js.AddConsumer(stream, cfg, opts...)
}

func UpdateConsumer(js nats.JetStreamContext, stream string, cfg *nats.ConsumerConfig, opts ...nats.JSOpt) (*nats.ConsumerInfo, error) {
	return js.UpdateConsumer(stream, cfg, opts...)
}

func DeleteConsumer(js nats.JetStreamContext, stream, consumer string, opts ...nats.JSOpt) error {
	return js.DeleteConsumer(stream, consumer, opts...)
}

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
