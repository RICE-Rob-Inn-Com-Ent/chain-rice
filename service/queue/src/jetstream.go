package queue

// TODO:
// [ ] implement stream management:
//     CreateStream(ctx, js, config nats.StreamConfig) error
//     stream names from RICE_NATS_STREAM_* env vars — never hardcoded
// [ ] implement consumer management:
//     CreateConsumer(ctx, js, stream string, config nats.ConsumerConfig) error
//     durable consumer names from RICE_NATS_CONSUMER_* env vars
// [ ] implement stream config:
//     Retention: LimitsPolicy|WorkQueuePolicy|InterestPolicy
//     MaxAge from RICE_NATS_STREAM_MAX_AGE env var
//     Replicas from RICE_NATS_REPLICAS env var (default: 1)

import (
	"github.com/nats-io/nats.go"
)

// JetStream opens a JetStream context on a connection.
func JetStream(nc *nats.Conn, opts ...nats.JSOpt) (nats.JetStreamContext, error) {
	return nc.JetStream(opts...)
}

// JSPublish publishes to JetStream (persistent, with PubAck).
func JSPublish(js nats.JetStreamContext, subj string, data []byte, opts ...nats.PubOpt) (*nats.PubAck, error) {
	return js.Publish(subj, data, opts...)
}

// Stream CRUD and info (legacy JetStream API on [nats.JetStreamContext]).

func AddStream(js nats.JetStreamContext, cfg *nats.StreamConfig, opts ...nats.JSOpt) (*nats.StreamInfo, error) {
	return js.AddStream(cfg, opts...)
}

func UpdateStream(js nats.JetStreamContext, cfg *nats.StreamConfig, opts ...nats.JSOpt) (*nats.StreamInfo, error) {
	return js.UpdateStream(cfg, opts...)
}

func DeleteStream(js nats.JetStreamContext, name string, opts ...nats.JSOpt) error {
	return js.DeleteStream(name, opts...)
}

func GetStreamInfo(js nats.JetStreamContext, name string, opts ...nats.JSOpt) (*nats.StreamInfo, error) {
	return js.StreamInfo(name, opts...)
}

func PurgeStream(js nats.JetStreamContext, name string, opts ...nats.JSOpt) error {
	return js.PurgeStream(name, opts...)
}

// Re-export stream config types for callers.
type (
	StreamConfig    = nats.StreamConfig
	RetentionPolicy = nats.RetentionPolicy
	StorageType     = nats.StorageType
)
