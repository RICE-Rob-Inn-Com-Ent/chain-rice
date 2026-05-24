package queue

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"strings"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

// Standard NATS headers attached by [Publisher] for cross-service diagnostics.
const (
	HeaderSenderService = "sender_service"
	HeaderTimestamp     = "timestamp"
	HeaderVersion       = "version"
)

const metaRiceService = "rice.service"

// Publisher wraps a core NATS connection and an optional JetStream v2 handle ([InitJetStream]) for durable publishes.
type Publisher struct {
	NC *nats.Conn
	JS jetstream.JetStream
}

// NewPublisher returns a publisher. Pass a non-nil js from [InitJetStream] so [Publisher.Publish] waits for a stream ack;
// js may be nil for fire-and-forget core NATS only.
func NewPublisher(nc *nats.Conn, js jetstream.JetStream) *Publisher {
	return &Publisher{NC: nc, JS: js}
}

// Publish marshals data with [Marshal], adds SMITH metadata and trace headers ([InjectTrace]), then publishes.
// When JS is non-nil, uses [jetstream.JetStream.PublishMsg] (server ack). When opts are non-empty, uses legacy
// [nats.Conn.JetStream] [nats.JetStreamContext.PublishMsg] so [nats.MsgId] and related [nats.PubOpt] values apply.
// With JS nil and empty opts, uses core [nats.Conn.PublishMsg].
func (p *Publisher) Publish(ctx *kit.Context, subject string, data any, opts ...nats.PubOpt) error {
	msg, err := p.prepareMsg(ctx, subject, data)
	if err != nil {
		return err
	}
	return p.publishMsg(ctx, msg, opts)
}

// PublishJS is like [Publisher.Publish] but passes jetstream-specific options (e.g. dedupe id) when using the v2 API.
// Requires a non-nil [Publisher.JS].
func (p *Publisher) PublishJS(ctx *kit.Context, subject string, data any, opts ...jetstream.PublishOpt) error {
	if p.JS == nil {
		return errors.New("queue.publish: JetStream client required for PublishJS")
	}
	msg, err := p.prepareMsg(ctx, subject, data)
	if err != nil {
		return err
	}
	_, err = p.JS.PublishMsg(p.goCtx(ctx), msg, opts...)
	return err
}

// PublishAsync enqueues a publish without blocking the caller. Errors are logged with [kit.Logger].
// When [Publisher.JS] is set, uses JetStream async publish and logs ack failures; otherwise runs [Publisher.Publish] in a goroutine.
func (p *Publisher) PublishAsync(ctx *kit.Context, subject string, data any) {
	msg, err := p.prepareMsg(ctx, subject, data)
	if err != nil {
		kit.Logger().Error("queue.publish.async_prepare_failed",
			slog.String("subject", subject),
			slog.String("err", err.Error()),
		)
		return
	}
	if p.JS != nil {
		fut, err := p.JS.PublishMsgAsync(msg)
		if err != nil {
			kit.Logger().Error("queue.publish.async_enqueue_failed",
				slog.String("subject", subject),
				slog.String("err", err.Error()),
			)
			return
		}
		go p.logJetStreamAsyncAck(subject, fut)
		return
	}
	go func(m *nats.Msg) {
		if err := p.publishMsg(ctx, m, nil); err != nil {
			kit.Logger().Error("queue.publish.async_failed",
				slog.String("subject", m.Subject),
				slog.String("err", err.Error()),
			)
		}
	}(msg)
}

func (p *Publisher) prepareMsg(ctx *kit.Context, subject string, data any) (*nats.Msg, error) {
	if p == nil || p.NC == nil {
		return nil, errors.New("queue.publish: nil publisher or connection")
	}
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return nil, errors.New("queue.publish: empty subject")
	}
	payload, err := Marshal(data)
	if err != nil {
		return nil, err
	}
	msg := nats.NewMsg(subject)
	msg.Data = payload
	p.applyStandardHeaders(ctx, msg)
	InjectTrace(ctx, msg)
	return msg, nil
}

func (p *Publisher) applyStandardHeaders(ctx *kit.Context, msg *nats.Msg) {
	if msg.Header == nil {
		msg.Header = make(nats.Header)
	}
	sender := senderServiceName(ctx)
	msg.Header.Set(HeaderSenderService, sender)
	msg.Header.Set(HeaderTimestamp, time.Now().UTC().Format(time.RFC3339Nano))
	msg.Header.Set(HeaderVersion, kit.Version)
}

func senderServiceName(ctx *kit.Context) string {
	if ctx != nil && ctx.Meta != nil {
		if v, ok := ctx.Meta.Get(metaRiceService); ok && strings.TrimSpace(v) != "" {
			return v
		}
	}
	if v := strings.TrimSpace(os.Getenv("OTEL_SERVICE_NAME")); v != "" {
		return v
	}
	return "smith/unknown"
}

func (p *Publisher) goCtx(k *kit.Context) context.Context {
	if k == nil {
		return context.Background()
	}
	return k.ToContext()
}

func (p *Publisher) publishMsg(ctx *kit.Context, msg *nats.Msg, opts []nats.PubOpt) error {
	if len(opts) > 0 {
		jsLegacy, err := p.NC.JetStream()
		if err != nil {
			return err
		}
		_, err = jsLegacy.PublishMsg(msg, opts...)
		return err
	}
	if p.JS != nil {
		_, err := p.JS.PublishMsg(p.goCtx(ctx), msg)
		return err
	}
	return p.NC.PublishMsg(msg)
}

func (p *Publisher) logJetStreamAsyncAck(subject string, fut jetstream.PubAckFuture) {
	if fut == nil {
		return
	}
	select {
	case err := <-fut.Err():
		if err != nil {
			kit.Logger().Error("queue.publish.async_ack_failed",
				slog.String("subject", subject),
				slog.String("err", err.Error()),
			)
		}
	case <-fut.Ok():
	case <-time.After(30 * time.Second):
		kit.Logger().Warn("queue.publish.async_ack_timeout",
			slog.String("subject", subject),
		)
	}
}

// --- low-level helpers (no codec / headers) ---

// Publish sends a raw payload on subject.
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
