package queue

// TODO:
// [ ] implement NATS subscribe:
//     Subscribe(ctx, subject string, handler MsgHandler) error
//     extracts OTel context from NATS headers
//     starts OTel span per message
// [ ] implement JetStream subscribe:
//     PullSubscribe(ctx, js, subject, durable string) (*nats.Subscription, error)
//     push-based: Subscribe(ctx, js, subject string) (*nats.Subscription, error)
// [ ] implement queue subscribe:
//     QueueSubscribe(ctx, subject, queue string, handler MsgHandler) error
//     load-balanced message delivery across queue group

import (
	"github.com/nats-io/nats.go"
)

// Subscribe is async pub/sub with a callback.
func Subscribe(nc *nats.Conn, subj string, cb nats.MsgHandler) (*nats.Subscription, error) {
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
