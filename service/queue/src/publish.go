package queue

// TODO:
// [ ] implement NATS publish:
//     Publish(ctx, subject string, msg proto.Message) error
//     serializes via prost before publish
//     injects OTel trace context into NATS headers
// [ ] implement JetStream publish:
//     PublishAsync(ctx, js, subject string, msg proto.Message) error
//     returns nats.PubAckFuture — non-blocking
// [ ] implement publish with retry:
//     PublishWithRetry(ctx, subject string, msg proto.Message, maxRetries int) error
//     exponential backoff on NATS timeout

import (
	"time"

	"github.com/nats-io/nats.go"
)

// Publish sends a payload on subject.
func Publish(nc *nats.Conn, subj string, data []byte) error {
	return nc.Publish(subj, data)
}

// PublishMsg sends a composed message (headers, reply subject).
func PublishMsg(nc *nats.Conn, m *nats.Msg) error {
	return nc.PublishMsg(m)
}

// Request performs request-reply and waits for a single response.
func Request(nc *nats.Conn, subj string, data []byte, timeout time.Duration) (*nats.Msg, error) {
	return nc.Request(subj, data, timeout)
}

// RequestMsg is like Request but uses [nats.Msg] for headers and metadata.
func RequestMsg(nc *nats.Conn, msg *nats.Msg, timeout time.Duration) (*nats.Msg, error) {
	return nc.RequestMsg(msg, timeout)
}

// NewMsg allocates a message with headers; set Data on the returned value.
func NewMsg(subj string, data []byte) *nats.Msg {
	m := nats.NewMsg(subj)
	m.Data = data
	return m
}

// Header is a type alias for JetStream / core headers.
type Header = nats.Header
