package database

// TODO:
// [ ] implement Valkey pub/sub:
//     Subscribe(ctx, channels ...string) *redis.PubSub
//     Publish(ctx, channel, payload string) error
// [ ] implement typed pub/sub:
//     PublishProto(ctx, channel string, msg proto.Message) error
//     SubscribeProto(ctx, channel string, msg proto.Message, fn Handler)
//     serializes via prost before publish
// [ ] implement pub/sub channels:
//     all channel names from RICE_PUBSUB_* env vars
//     never hardcode channel names

import (
	"context"
	"errors"

	"github.com/redis/go-redis/v9"
)

// PubSub wraps Redis pub/sub for fan-out and channel routing (Valkey-compatible).
type PubSub struct {
	Client *redis.Client
}

// Publish sends a message to a channel.
func (p *PubSub) Publish(ctx context.Context, channel string, payload string) error {
	if p == nil || p.Client == nil {
		return errors.New("database: nil pubsub")
	}
	return p.Client.Publish(ctx, channel, payload).Err()
}

// Subscribe returns *redis.PubSub; call Receive once if you need subscription ACK, then Channel().
func (p *PubSub) Subscribe(ctx context.Context, channels ...string) (*redis.PubSub, error) {
	if p == nil || p.Client == nil {
		return nil, errors.New("database: nil pubsub")
	}
	return p.Client.Subscribe(ctx, channels...), nil
}

// PSubscribe subscribes to glob-style patterns.
func (p *PubSub) PSubscribe(ctx context.Context, patterns ...string) (*redis.PubSub, error) {
	if p == nil || p.Client == nil {
		return nil, errors.New("database: nil pubsub")
	}
	return p.Client.PSubscribe(ctx, patterns...), nil
}
