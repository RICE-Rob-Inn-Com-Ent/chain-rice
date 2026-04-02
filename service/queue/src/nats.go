// Package queue provides thin helpers around NATS and Temporal (SMITH queue stack).
package queue

// TODO:
// [ ] implement NATS connection:
//     Connect(ctx) (*nats.Conn, error)
//     reads NATS_URL from env
//     options: MaxReconnects, ReconnectWait, Timeout
//     all from RICE_NATS_* env vars
// [ ] implement JetStream context:
//     JetStream(conn *nats.Conn) (nats.JetStreamContext, error)
//     enables persistent message streams
// [ ] implement connection health:
//     IsConnected(conn *nats.Conn) bool
//     called by bench/health.go

import (
	"crypto/tls"
	"time"

	"github.com/nats-io/nats.go"
)

// Re-export core connection types used by the rest of this package.
type (
	Conn        = nats.Conn
	Options     = nats.Options
	Status      = nats.Status
	ConnHandler = nats.ConnHandler
)

// Connect opens a NATS connection with optional TLS, credentials, and reconnect tuning.
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

// MaxReconnects sets reconnect attempt cap (0 = default).
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

// Close closes the connection immediately.
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
