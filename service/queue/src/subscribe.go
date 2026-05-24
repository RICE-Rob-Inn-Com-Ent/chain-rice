package queue

import (
	"errors"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/nats-io/nats.go"
	"go.opentelemetry.io/otel"
)

// Subscriber is a thin facade over core NATS subscriptions bound to one connection.
type Subscriber struct {
	NC *nats.Conn
}

// NewSubscriber returns a subscriber for the given connection (typically [Nats.Conn]).
func NewSubscriber(nc *nats.Conn) *Subscriber {
	if nc == nil {
		return nil
	}
	return &Subscriber{NC: nc}
}

// Subscribe is [Subscribe] with this subscriber's connection.
func (s *Subscriber) Subscribe(ctx *kit.Context, subject string, handler nats.MsgHandler) (*nats.Subscription, error) {
	if s == nil || s.NC == nil {
		return nil, errors.New("queue.subscribe: nil Subscriber or connection")
	}
	return Subscribe(ctx, s.NC, subject, handler)
}

// SubscribeRaw is [SubscribeRaw] with this subscriber's connection.
func (s *Subscriber) SubscribeRaw(subj string, cb nats.MsgHandler) (*nats.Subscription, error) {
	if s == nil || s.NC == nil {
		return nil, errors.New("queue.subscribe: nil Subscriber or connection")
	}
	return SubscribeRaw(s.NC, subj, cb)
}

// QueueSubscribe is [QueueSubscribe] with this subscriber's connection.
func (s *Subscriber) QueueSubscribe(subj, queue string, cb nats.MsgHandler) (*nats.Subscription, error) {
	if s == nil || s.NC == nil {
		return nil, errors.New("queue.subscribe: nil Subscriber or connection")
	}
	return QueueSubscribe(s.NC, subj, queue, cb)
}

// Subscribe creates a core NATS subscription (non-persistent broadcast). The handler receives the original
// [*nats.Msg]; tracing and service metadata are rebuilt from message headers via [ExtractTrace] and merged
// with root ctx before invoking the handler (handlers can use [kit.FromContext] on a derived context if needed).
//
// For handlers that only need the standard [nats.MsgHandler] signature, use the message as-is; correlation
// IDs and W3C trace context are on msg headers for downstream propagation.
func Subscribe(ctx *kit.Context, nc *nats.Conn, subject string, handler nats.MsgHandler) (*nats.Subscription, error) {
	if nc == nil {
		return nil, errors.New("queue.subscribe: nil connection")
	}
	if handler == nil {
		return nil, errors.New("queue.subscribe: nil handler")
	}
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return nil, errors.New("queue.subscribe: empty subject")
	}
	return nc.Subscribe(subject, wrapSubscribeHandler(ctx, handler))
}

func wrapSubscribeHandler(root *kit.Context, user nats.MsgHandler) nats.MsgHandler {
	tr := otel.Tracer("rice/queue/subscribe")
	return func(msg *nats.Msg) {
		if msg == nil {
			return
		}
		traceCtx := ExtractTrace(msg)
		var meta *kit.Metadata
		if root != nil && root.Meta != nil {
			meta = root.Meta.Clone()
		}
		kctx := kit.NewContext(traceCtx, meta)
		_, span := tr.Start(kctx.ToContext(), "queue.subscribe.message")
		defer span.End()
		user(msg)
	}
}

// SubscribeRaw is [nats.Conn.Subscribe] without SMITH trace wrapping.
func SubscribeRaw(nc *nats.Conn, subj string, cb nats.MsgHandler) (*nats.Subscription, error) {
	return nc.Subscribe(subj, cb)
}

// SubscribeSync receives messages via NextMsg.
func SubscribeSync(nc *nats.Conn, subj string) (*nats.Subscription, error) {
	return nc.SubscribeSync(subj)
}

// QueueSubscribe load-balances deliveries across a queue group.
func QueueSubscribe(nc *nats.Conn, subj, queue string, cb nats.MsgHandler) (*nats.Subscription, error) {
	return nc.QueueSubscribe(subj, queue, cb)
}

// QueueSubscribeSync is synchronous queue subscription.
func QueueSubscribeSync(nc *nats.Conn, subj, queue string) (*nats.Subscription, error) {
	return nc.QueueSubscribeSync(subj, queue)
}

// ChanSubscribe delivers messages on a channel.
func ChanSubscribe(nc *nats.Conn, subj string, ch chan *nats.Msg) (*nats.Subscription, error) {
	return nc.ChanSubscribe(subj, ch)
}

// Unsubscribe removes interest (optionally after max messages).
func Unsubscribe(sub *nats.Subscription) error {
	return sub.Unsubscribe()
}

// Drain unsubscribes and processes pending messages before closing.
func DrainSubscription(sub *nats.Subscription) error {
	return sub.Drain()
}
