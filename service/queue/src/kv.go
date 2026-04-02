package queue

// TODO:
// [ ] implement NATS KV store:
//     NewKV(js, bucket string) (nats.KeyValue, error)
//     bucket names from RICE_NATS_KV_* env vars
// [ ] implement KV operations:
//     Put(ctx, kv, key string, value []byte) error
//     Get(ctx, kv, key string) ([]byte, error)
//     Delete(ctx, kv, key string) error
//     Watch(ctx, kv, key string) (nats.KeyWatcher, error)
// [ ] implement KV TTL:
//     PutWithTTL(ctx, kv, key string, value []byte, ttl time.Duration) error

import (
	"github.com/nats-io/nats.go"
)

// CreateKeyValue creates a JetStream KV bucket.
func CreateKeyValue(js nats.JetStreamContext, cfg *nats.KeyValueConfig) (nats.KeyValue, error) {
	return js.CreateKeyValue(cfg)
}

// OpenKV opens an existing KV bucket by name.
func OpenKV(js nats.JetStreamContext, bucket string) (nats.KeyValue, error) {
	return js.KeyValue(bucket)
}

// DeleteKeyValue removes a KV bucket.
func DeleteKeyValue(js nats.JetStreamContext, bucket string) error {
	return js.DeleteKeyValue(bucket)
}

// KVGet returns the latest value for a key.
func KVGet(kv nats.KeyValue, key string) (nats.KeyValueEntry, error) {
	return kv.Get(key)
}

// KVGetRevision returns a specific revision.
func KVGetRevision(kv nats.KeyValue, key string, revision uint64) (nats.KeyValueEntry, error) {
	return kv.GetRevision(key, revision)
}

// KVPut stores a value and returns the new revision.
func KVPut(kv nats.KeyValue, key string, value []byte) (uint64, error) {
	return kv.Put(key, value)
}

// KVDelete deletes a key (tombstone / history per bucket config).
func KVDelete(kv nats.KeyValue, key string, opts ...nats.DeleteOpt) error {
	return kv.Delete(key, opts...)
}

// KVWatch watches keys (pattern supported).
func KVWatch(kv nats.KeyValue, keys string, opts ...nats.WatchOpt) (nats.KeyWatcher, error) {
	return kv.Watch(keys, opts...)
}

// Re-export KV-related types.
type (
	KeyValueConfig = nats.KeyValueConfig
	KeyValueEntry  = nats.KeyValueEntry
	KeyWatcher     = nats.KeyWatcher
)
