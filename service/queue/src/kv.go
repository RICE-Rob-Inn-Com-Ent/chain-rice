package queue

import (
	"context"
	"errors"
	"strings"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/nats-io/nats.go/jetstream"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

const (
	// DefaultSmithKVBucket is the JetStream KV bucket used by [NewQueue] when [Config.KVBucket] is empty.
	DefaultSmithKVBucket = "smith-state"

	// DefaultKVHistory is the number of revisions kept per key (max 64 in JetStream).
	DefaultKVHistory uint8 = 5
	// DefaultKVTTL expires keys for ephemeral coordination state (active job status, health flags).
	DefaultKVTTL = 24 * time.Hour
	// DefaultKVLimitMarkerTTL must be set when using bucket TTL so expirations surface to watchers.
	DefaultKVLimitMarkerTTL = 5 * time.Minute
)

var kvTracer = otel.Tracer("rice/queue/kv")

// InitKV binds to an existing JetStream KV bucket or creates it with history, TTL, and marker retention.
// New buckets use in-memory storage for lower latency; existing buckets keep their server configuration.
func InitKV(js jetstream.JetStream, bucket string) (jetstream.KeyValue, error) {
	if js == nil {
		return nil, errors.New("queue.kv: nil JetStream")
	}
	bucket = strings.TrimSpace(bucket)
	if bucket == "" {
		return nil, errors.New("queue.kv: empty bucket name")
	}
	ctx := context.Background()
	kv, err := js.KeyValue(ctx, bucket)
	if err == nil {
		return kv, nil
	}
	if !errors.Is(err, jetstream.ErrBucketNotFound) {
		return nil, err
	}
	return js.CreateKeyValue(ctx, jetstream.KeyValueConfig{
		Bucket:         bucket,
		History:        DefaultKVHistory,
		TTL:            DefaultKVTTL,
		LimitMarkerTTL: DefaultKVLimitMarkerTTL,
		Storage:        jetstream.MemoryStorage,
		Description:    "SMITH cross-runtime KV (Go / Rust / Mojo)",
	})
}

// StateKV wraps a [jetstream.KeyValue] with codec-aware helpers and tracing. Build with [NewStateKV] after [InitKV].
type StateKV struct {
	kv jetstream.KeyValue
}

// NewStateKV returns a wrapper for PutState / GetState / WatchState.
func NewStateKV(kv jetstream.KeyValue) (*StateKV, error) {
	if kv == nil {
		return nil, errors.New("queue.kv: nil KeyValue")
	}
	return &StateKV{kv: kv}, nil
}

// KV returns the underlying JetStream handle (e.g. for direct Put or Status).
func (s *StateKV) KV() jetstream.KeyValue {
	if s == nil {
		return nil
	}
	return s.kv
}

func (s *StateKV) goCtx(ctx *kit.Context) context.Context {
	if ctx == nil {
		return context.Background()
	}
	return ctx.ToContext()
}

// PutState marshals value with [MarshalKV], writes it with Put, and records an OTel span.
func (s *StateKV) PutState(ctx *kit.Context, key string, value any) error {
	if s == nil || s.kv == nil {
		return errors.New("queue.kv: nil StateKV")
	}
	key = strings.TrimSpace(key)
	if key == "" {
		return errors.New("queue.kv: empty key")
	}
	goCtx := s.goCtx(ctx)
	goCtx, span := kvTracer.Start(goCtx, "smith.kv.put",
		trace.WithAttributes(
			attribute.String("smith.kv.bucket", s.kv.Bucket()),
			attribute.String("smith.kv.key", key),
		),
	)
	defer span.End()

	payload, err := MarshalKV(value)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return err
	}
	if _, err := s.kv.Put(goCtx, key, payload); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return err
	}
	span.SetStatus(codes.Ok, "")
	return nil
}

// GetState loads the latest revision and unmarshals with [UnmarshalKV].
func (s *StateKV) GetState(ctx *kit.Context, key string, v any) error {
	if s == nil || s.kv == nil {
		return errors.New("queue.kv: nil StateKV")
	}
	if v == nil {
		return errors.New("queue.kv: nil destination")
	}
	key = strings.TrimSpace(key)
	if key == "" {
		return errors.New("queue.kv: empty key")
	}
	goCtx := s.goCtx(ctx)
	goCtx, span := kvTracer.Start(goCtx, "smith.kv.get",
		trace.WithAttributes(
			attribute.String("smith.kv.bucket", s.kv.Bucket()),
			attribute.String("smith.kv.key", key),
		),
	)
	defer span.End()

	entry, err := s.kv.Get(goCtx, key)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return err
	}
	if err := UnmarshalKV(entry.Value(), v); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return err
	}
	span.SetStatus(codes.Ok, "")
	return nil
}

// WatchState starts a real-time watcher for key (exact subject); handler is invoked from a background goroutine.
// The watch stops when ctx is cancelled or the connection closes. Returns an error if the watcher cannot be started.
func (s *StateKV) WatchState(ctx *kit.Context, key string, handler func(entry jetstream.KeyValueEntry)) error {
	if s == nil || s.kv == nil {
		return errors.New("queue.kv: nil StateKV")
	}
	if handler == nil {
		return errors.New("queue.kv: nil handler")
	}
	key = strings.TrimSpace(key)
	if key == "" {
		return errors.New("queue.kv: empty key")
	}
	parent := s.goCtx(ctx)
	watcher, err := s.kv.Watch(parent, key, jetstream.IgnoreDeletes())
	if err != nil {
		return err
	}
	go func() {
		defer func() { _ = watcher.Stop() }()
		for {
			select {
			case <-parent.Done():
				return
			case e, ok := <-watcher.Updates():
				if !ok {
					return
				}
				if e == nil {
					continue
				}
				handler(e)
			}
		}
	}()
	return nil
}
