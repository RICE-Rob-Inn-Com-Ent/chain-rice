package queue

import (
	"context"
	"errors"
	"math"
	"strings"
	"sync"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
)

const (
	// DefaultJetStreamStreamMaxAge caps message age before eviction (limits + workqueue discard).
	DefaultJetStreamStreamMaxAge = 7 * 24 * time.Hour
	// DefaultJetStreamStreamMaxBytes caps total stream size on disk (1 GiB).
	DefaultJetStreamStreamMaxBytes int64 = 1 << 30
)

// InitJetStream builds a [jetstream.JetStream] handle from an existing core NATS connection.
func InitJetStream(nc *nats.Conn) (jetstream.JetStream, error) {
	if nc == nil {
		return nil, errors.New("queue.jetstream: nil connection")
	}
	return jetstream.New(nc)
}

// EnsureStream creates the stream when it is missing; if it already exists, records metrics and returns nil.
// js must be non-nil ([InitJetStream]).
func EnsureStream(ctx *kit.Context, js jetstream.JetStream, streamName string, subjects []string) error {
	if js == nil {
		return errors.New("queue.jetstream: nil JetStream")
	}
	streamName = strings.TrimSpace(streamName)
	if streamName == "" {
		return errors.New("queue.jetstream: empty stream name")
	}
	if len(subjects) == 0 {
		return errors.New("queue.jetstream: no subjects")
	}
	goCtx := context.Background()
	if ctx != nil {
		goCtx = ctx.ToContext()
	}

	_, err := js.Stream(goCtx, streamName)
	if err == nil {
		return recordJetStreamStreamMetrics(goCtx, js, streamName)
	}
	if !errors.Is(err, jetstream.ErrStreamNotFound) {
		return err
	}

	cfg := jetstream.StreamConfig{
		Name:        streamName,
		Subjects:    append([]string(nil), subjects...),
		Retention:   jetstream.WorkQueuePolicy,
		Storage:     jetstream.FileStorage,
		Discard:     jetstream.DiscardOld,
		MaxAge:      DefaultJetStreamStreamMaxAge,
		MaxBytes:    DefaultJetStreamStreamMaxBytes,
		Description: "SMITH real-time events (work queue)",
	}
	_, err = js.CreateStream(goCtx, cfg)
	if err != nil {
		return err
	}
	return recordJetStreamStreamMetrics(goCtx, js, streamName)
}

// DurableConsumerConfig configures a pull consumer with a durable name so the server tracks delivery state.
type DurableConsumerConfig struct {
	Durable       string
	FilterSubject string
	AckWait       time.Duration
	MaxAckPending int
}

// EnsureDurableConsumer creates or updates a durable pull consumer on stream (explicit ack, suitable for work queues).
func EnsureDurableConsumer(ctx context.Context, stream jetstream.Stream, cfg DurableConsumerConfig) (jetstream.Consumer, error) {
	if stream == nil {
		return nil, errors.New("queue.jetstream: nil stream")
	}
	cfg.Durable = strings.TrimSpace(cfg.Durable)
	if cfg.Durable == "" {
		return nil, errors.New("queue.jetstream: empty durable name")
	}
	ackWait := cfg.AckWait
	if ackWait <= 0 {
		ackWait = 30 * time.Second
	}
	cc := jetstream.ConsumerConfig{
		Durable:       cfg.Durable,
		AckPolicy:     jetstream.AckExplicitPolicy,
		AckWait:       ackWait,
		ReplayPolicy:  jetstream.ReplayInstantPolicy,
		FilterSubject: strings.TrimSpace(cfg.FilterSubject),
	}
	if cfg.MaxAckPending != 0 {
		cc.MaxAckPending = cfg.MaxAckPending
	}
	return stream.CreateOrUpdateConsumer(ctx, cc)
}

var (
	jetStreamMetricsOnce    sync.Once
	jetStreamMsgsGauge      metric.Int64Gauge
	jetStreamBytesGauge     metric.Int64Gauge
	jetStreamMetricsInitErr error
)

func initJetStreamMetrics() {
	jetStreamMetricsOnce.Do(func() {
		m := otel.Meter("rice/queue/jetstream")
		var err error
		jetStreamMsgsGauge, err = m.Int64Gauge(
			"smith.jetstream.stream.messages",
			metric.WithDescription("Current messages stored in a JetStream stream"),
			metric.WithUnit("{message}"),
		)
		if err != nil {
			jetStreamMetricsInitErr = err
			return
		}
		jetStreamBytesGauge, err = m.Int64Gauge(
			"smith.jetstream.stream.bytes",
			metric.WithDescription("Current bytes stored in a JetStream stream"),
			metric.WithUnit("By"),
		)
		if err != nil {
			jetStreamMetricsInitErr = err
		}
	})
}

// RecordJetStreamStreamMetrics refreshes OTel gauges from server stream state (for use after EnsureStream or on a ticker).
func RecordJetStreamStreamMetrics(ctx context.Context, js jetstream.JetStream, streamName string) error {
	if js == nil {
		return errors.New("queue.jetstream: nil JetStream")
	}
	streamName = strings.TrimSpace(streamName)
	if streamName == "" {
		return errors.New("queue.jetstream: empty stream name")
	}
	return recordJetStreamStreamMetrics(ctx, js, streamName)
}

func recordJetStreamStreamMetrics(ctx context.Context, js jetstream.JetStream, streamName string) error {
	st, err := js.Stream(ctx, streamName)
	if err != nil {
		return err
	}
	info, err := st.Info(ctx)
	if err != nil {
		return err
	}
	initJetStreamMetrics()
	if jetStreamMetricsInitErr != nil || jetStreamMsgsGauge == nil || jetStreamBytesGauge == nil {
		return nil
	}
	attrs := metric.WithAttributes(attribute.String("stream", streamName))
	jetStreamMsgsGauge.Record(ctx, uint64ToGaugeInt64(info.State.Msgs), attrs)
	jetStreamBytesGauge.Record(ctx, uint64ToGaugeInt64(info.State.Bytes), attrs)
	return nil
}

func uint64ToGaugeInt64(v uint64) int64 {
	if v > uint64(math.MaxInt64) {
		return math.MaxInt64
	}
	return int64(v)
}
