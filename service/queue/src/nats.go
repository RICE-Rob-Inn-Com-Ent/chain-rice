// Package queue provides thin helpers around NATS and Temporal (SMITH queue stack).
package queue

import (
	"context"
	"crypto/tls"
	"log/slog"
	"net/http"
	"sync/atomic"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/nats-io/nats.go"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	"google.golang.org/grpc/codes"
)

const natsMeterName = "rice/queue"

// Nats wraps a resilient [*nats.Conn] with SMITH logging and OTel connection metrics.
type Nats struct {
	inner *nats.Conn
	// connected is 1 when the client has an active server connection, else 0 (including reconnect wait).
	connected atomic.Int32
}

// Conn returns the underlying NATS connection for [JetStream], [Publish], and other package helpers.
func (n *Nats) Conn() *nats.Conn {
	if n == nil {
		return nil
	}
	return n.inner
}

// Status returns a concise connection state for health endpoints (mirrors [nats.Conn.Status]).
func (n *Nats) Status() string {
	if n == nil || n.inner == nil {
		return "CLOSED"
	}
	return n.inner.Status().String()
}

// ConnectNats opens NATS with infinite backoff reconnect, SMITH logging on disconnect/reconnect,
// and an observable gauge `queue.nats.connected` (1 = connected, 0 = not).
// Extra options are applied after defaults; callers may override reconnect policy if needed.
func ConnectNats(url string, options ...nats.Option) (*Nats, error) {
	n := &Nats{}

	base := []nats.Option{
		nats.MaxReconnects(-1),
		nats.ReconnectWait(2 * time.Second),
		nats.DisconnectHandler(func(nc *nats.Conn) {
			n.connected.Store(0)
			lg := kit.Logger()
			lg.Warn("queue.nats: disconnected",
				slog.String("connected_url", nc.ConnectedUrl()),
				slog.String("status", nc.Status().String()),
			)
		}),
		nats.ReconnectHandler(func(nc *nats.Conn) {
			n.connected.Store(1)
			lg := kit.Logger()
			lg.Info("queue.nats: reconnected",
				slog.String("connected_url", nc.ConnectedUrl()),
			)
		}),
		nats.ClosedHandler(func(nc *nats.Conn) {
			n.connected.Store(0)
			kit.Logger().Info("queue.nats: connection closed",
				slog.String("last_url", nc.ConnectedUrl()),
			)
		}),
	}

	opts := append(base, options...)
	nc, err := nats.Connect(url, opts...)
	if err != nil {
		return nil, kit.New("QUEUE_NATS_CONNECTION_FAILED", "nats: initial connect failed", http.StatusServiceUnavailable, codes.Unavailable).
			Wrap(err, "nats.Connect")
	}

	n.inner = nc
	if nc.IsConnected() {
		n.connected.Store(1)
	}

	m := otel.Meter(natsMeterName)
	_, gerr := m.Int64ObservableGauge(
		"queue.nats.connected",
		metric.WithUnit("1"),
		metric.WithDescription("NATS client connected (1) or not (0) for SMITH queue"),
		metric.WithInt64Callback(func(_ context.Context, obs metric.Int64Observer) error {
			v := int64(0)
			if n != nil {
				v = int64(n.connected.Load())
			}
			status := "unknown"
			if n != nil && n.inner != nil {
				status = n.inner.Status().String()
			}
			obs.Observe(v,
				metric.WithAttributes(attribute.String("nats.connection_status", status)),
			)
			return nil
		}),
	)
	if gerr != nil {
		nc.Close()
		return nil, kit.Err.Internal("queue: nats otel gauge").Wrap(gerr, "Int64ObservableGauge")
	}

	return n, nil
}

// Close closes the NATS connection. Safe on nil or already-closed [Nats].
func (n *Nats) Close() {
	if n == nil || n.inner == nil {
		return
	}
	n.inner.Close()
	n.inner = nil
	n.connected.Store(0)
}

// --- thin re-exports and helpers (used by the rest of this package) ---

type (
	Conn        = nats.Conn
	Options     = nats.Options
	Status      = nats.Status
	ConnHandler = nats.ConnHandler
)

// Connect opens a NATS connection with caller-supplied options only (no SMITH defaults).
func Connect(url string, opts ...nats.Option) (*nats.Conn, error) {
	return nats.Connect(url, opts...)
}

// ConnectWithOptions uses a fully populated Options struct (MaxReconnect, ReconnectWait, etc.).
func ConnectWithOptions(opts nats.Options) (*nats.Conn, error) {
	return opts.Connect()
}

// DefaultOptions returns a copy of default [nats.Options] for customization before ConnectWithOptions.
func DefaultOptions() nats.Options {
	o := nats.GetDefaultOptions()
	return o
}

// SecureOpt wraps TLS for nats.Connect / Options.
func SecureOpt(tlsConfig *tls.Config) nats.Option {
	return nats.Secure(tlsConfig)
}

// UserPassword returns a nats.Option for USER/PASS auth.
func UserPassword(user, password string) nats.Option {
	return nats.UserInfo(user, password)
}

// TokenAuth returns a nats.Option for token auth.
func TokenAuth(token string) nats.Option {
	return nats.Token(token)
}

// NKeyFromSeedFile returns a nats.Option for NKEY auth from a seed file path.
func NKeyFromSeedFile(seedFile string) (nats.Option, error) {
	return nats.NkeyOptionFromSeed(seedFile)
}

// UserJWT returns a nats.Option for JWT + NKEY user callback auth.
func UserJWT(jwtCB nats.UserJWTHandler, sigCB nats.SignatureHandler) nats.Option {
	return nats.UserJWT(jwtCB, sigCB)
}

// UserCredentials returns a nats.Option for credentials file path (.creds).
func UserCredentials(path string) nats.Option {
	return nats.UserCredentials(path)
}

// MaxReconnects sets reconnect attempt cap (0 = default). Prefer [ConnectNats] for infinite retries.
func MaxReconnects(n int) nats.Option {
	return nats.MaxReconnects(n)
}

// ReconnectWait sets the pause between reconnect attempts.
func ReconnectWait(d time.Duration) nats.Option {
	return nats.ReconnectWait(d)
}

// ReconnectHandler sets a callback when connection is restored.
func ReconnectHandler(cb nats.ConnHandler) nats.Option {
	return nats.ReconnectHandler(cb)
}

// ClosedHandler sets a callback when the connection is closed.
func ClosedHandler(cb nats.ConnHandler) nats.Option {
	return nats.ClosedHandler(cb)
}

// DisconnectErrHandler sets a callback on disconnect (includes error).
func DisconnectErrHandler(cb nats.ConnErrHandler) nats.Option {
	return nats.DisconnectErrHandler(cb)
}

// Drain closes the connection gracefully after draining subscriptions and publishers.
func Drain(nc *nats.Conn) error {
	if nc == nil {
		return nil
	}
	return nc.Drain()
}

// Close closes the raw [*nats.Conn] immediately (not the wrapped [Nats]; use [*Nats.Close] for that).
func Close(nc *nats.Conn) {
	if nc != nil {
		nc.Close()
	}
}

// Flush pushes pending data to the server (with optional timeout via context in other APIs).
func Flush(nc *nats.Conn) error {
	if nc == nil {
		return nil
	}
	return nc.Flush()
}
