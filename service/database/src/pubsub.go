package database

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"sync"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/redis/go-redis/v9"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"
	grpcCodes "google.golang.org/grpc/codes"
)

const (
	pubsubTracerName     = "rice/database/pubsub"
	systemEventsChannel  = "smith:system:events"
	subscribeChannelSize = 256
)

var pubsubTracer = otel.Tracer(pubsubTracerName)

// PubSub is a lightweight Redis-backed event bus sharing the same [redis.Client] as [Cache].
type PubSub struct {
	Client *redis.Client

	wg sync.WaitGroup
}

// NewPubSub wraps an existing Redis client (typically [Cache.Client]).
func NewPubSub(client *redis.Client) *PubSub {
	return &PubSub{Client: client}
}

// NewPubSubFromCache reuses the Redis connection from a [Cache].
func NewPubSubFromCache(c *Cache) *PubSub {
	if c == nil {
		return &PubSub{}
	}
	return &PubSub{Client: c.Client}
}

// Wait blocks until all [PubSub.Subscribe] goroutines started on this instance exit
// (normally after their [kit.Context] is cancelled).
func (p *PubSub) Wait() {
	p.wg.Wait()
}

func (p *PubSub) nilCheck() error {
	if p == nil || p.Client == nil {
		return errors.New("database: nil pubsub")
	}
	return nil
}

func pubCtx(kctx *kit.Context) context.Context {
	if kctx == nil {
		return context.Background()
	}
	return kctx
}

// pubWire is the on-the-wire JSON envelope: W3C trace context + application body.
type pubWire struct {
	Traceparent string          `json:"traceparent,omitempty"`
	Tracestate  string          `json:"tracestate,omitempty"`
	Body        json.RawMessage `json:"body"`
}

func pubWrapWithTrace(ctx context.Context, body []byte) ([]byte, error) {
	carrier := propagation.MapCarrier{}
	otel.GetTextMapPropagator().Inject(ctx, carrier)
	w := pubWire{
		Traceparent: carrier["traceparent"],
		Tracestate:  carrier["tracestate"],
		Body:        body,
	}
	return json.Marshal(w)
}

func pubUnwrap(payload string) (payloadBytes []byte, parentCtx context.Context) {
	parentCtx = context.Background()
	var w pubWire
	if err := json.Unmarshal([]byte(payload), &w); err != nil || len(w.Body) == 0 {
		return []byte(payload), parentCtx
	}
	carrier := propagation.MapCarrier{}
	if w.Traceparent != "" {
		carrier["traceparent"] = w.Traceparent
	}
	if w.Tracestate != "" {
		carrier["tracestate"] = w.Tracestate
	}
	parentCtx = otel.GetTextMapPropagator().Extract(parentCtx, carrier)
	return w.Body, parentCtx
}

// Publish marshals message to JSON, injects trace context for subscribers, and PUBLISHes to channel.
func (p *PubSub) Publish(kctx *kit.Context, channel string, message any) error {
	if err := p.nilCheck(); err != nil {
		return err
	}
	body, err := kit.ToBytes(message)
	if err != nil {
		return err
	}
	ctx := pubCtx(kctx)
	ctx, span := pubsubTracer.Start(ctx, "pubsub.publish",
		trace.WithSpanKind(trace.SpanKindProducer),
		trace.WithAttributes(
			attribute.String("messaging.system", "redis"),
			attribute.String("messaging.destination.name", channel),
			attribute.String("messaging.operation", "publish"),
		),
	)
	defer span.End()

	wire, err := pubWrapWithTrace(ctx, body)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return kit.Internal("pubsub.Publish: envelope").Wrap(err, "json.Marshal")
	}

	if err := p.Client.Publish(ctx, channel, wire).Err(); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return kit.New("DATABASE_PUBSUB_FAILED", err.Error(), http.StatusInternalServerError, grpcCodes.Internal).
			Wrap(err, "redis.PUBLISH")
	}
	return nil
}

// Subscribe listens on channel in a background goroutine until kctx is cancelled.
// Each delivery runs in a consumer span linked to the publisher trace via the wire envelope.
// Connection drops are retried with bounded exponential backoff; handler errors are logged only.
func (p *PubSub) Subscribe(kctx *kit.Context, channel string, handler func(payload []byte) error) error {
	if err := p.nilCheck(); err != nil {
		return err
	}
	if handler == nil {
		return kit.BadRequest("pubsub.Subscribe: nil handler")
	}
	p.wg.Add(1)
	go p.subscribeLoop(kctx, channel, handler)
	return nil
}

func (p *PubSub) subscribeLoop(kctx *kit.Context, channel string, handler func(payload []byte) error) {
	defer p.wg.Done()
	ctx := pubCtx(kctx)
	attempt := 0
	for {
		select {
		case <-ctx.Done():
			return
		default:
		}

		// Subscribe uses a detached context so parent deadlines do not cancel the Redis SUBSCRIBE I/O.
		sub := p.Client.Subscribe(context.Background(), channel)
		msgCh := sub.Channel(redis.WithChannelSize(subscribeChannelSize))

	recv:
		for {
			select {
			case <-ctx.Done():
				_ = sub.Close()
				return
			case msg, ok := <-msgCh:
				if !ok {
					if err := sub.Close(); err != nil {
						kit.Logger().ErrorContext(ctx, "pubsub: channel closed", "channel", channel, "err", err)
					}
					break recv
				}
				if msg == nil {
					continue
				}
				p.handleMessage(channel, msg.Payload, handler)
			}
		}

		attempt++
		select {
		case <-ctx.Done():
			return
		case <-time.After(pubsubBackoff(attempt)):
		}
	}
}

func pubsubBackoff(attempt int) time.Duration {
	const base = 50 * time.Millisecond
	const max = 30 * time.Second
	shift := attempt - 1
	if shift < 0 {
		shift = 0
	}
	if shift > 16 {
		shift = 16
	}
	d := base * time.Duration(1<<shift)
	if d > max {
		d = max
	}
	return d
}

func (p *PubSub) handleMessage(channel, payload string, handler func(payload []byte) error) {
	body, parentCtx := pubUnwrap(payload)
	procCtx, span := pubsubTracer.Start(parentCtx, "pubsub.process",
		trace.WithSpanKind(trace.SpanKindConsumer),
		trace.WithAttributes(
			attribute.String("messaging.system", "redis"),
			attribute.String("messaging.destination.name", channel),
			attribute.String("messaging.operation", "process"),
		),
	)
	defer span.End()

	defer func() {
		if r := recover(); r != nil {
			kit.Logger().ErrorContext(procCtx, "pubsub: handler panic", "channel", channel, "recover", r)
			span.SetStatus(codes.Error, "panic")
		}
	}()

	if err := handler(body); err != nil {
		kit.Logger().ErrorContext(procCtx, "pubsub: handler error", "channel", channel, "err", err)
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
	}
}

// Notify publishes a standardized system event on [SystemEventsChannel].
func (p *PubSub) Notify(kctx *kit.Context, event string, data any) error {
	msg := struct {
		Event string `json:"event"`
		Data  any    `json:"data,omitempty"`
		TS    int64  `json:"ts"`
	}{
		Event: event,
		Data:  data,
		TS:    time.Now().Unix(),
	}
	return p.Publish(kctx, systemEventsChannel, msg)
}

// SystemEventsChannel is the Redis channel used by [PubSub.Notify].
func SystemEventsChannel() string { return systemEventsChannel }

// PublishRaw sends a pre-serialized payload without the trace envelope (interop only; no trace link).
func (p *PubSub) PublishRaw(ctx context.Context, channel, payload string) error {
	if err := p.nilCheck(); err != nil {
		return err
	}
	if err := p.Client.Publish(ctx, channel, payload).Err(); err != nil {
		return kit.New("DATABASE_PUBSUB_FAILED", err.Error(), http.StatusInternalServerError, grpcCodes.Internal).
			Wrap(err, "redis.PUBLISH")
	}
	return nil
}

// SubscribeConn returns a low-level [redis.PubSub] for advanced use.
func (p *PubSub) SubscribeConn(ctx context.Context, channels ...string) (*redis.PubSub, error) {
	if err := p.nilCheck(); err != nil {
		return nil, err
	}
	return p.Client.Subscribe(ctx, channels...), nil
}

// PSubscribeConn subscribes with PSUBSCRIBE for glob patterns.
func (p *PubSub) PSubscribeConn(ctx context.Context, patterns ...string) (*redis.PubSub, error) {
	if err := p.nilCheck(); err != nil {
		return nil, err
	}
	return p.Client.PSubscribe(ctx, patterns...), nil
}
