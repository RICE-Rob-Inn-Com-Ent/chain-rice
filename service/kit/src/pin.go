package kit

import (
	"context"
	"sync"

	"go.opentelemetry.io/otel/trace"
)

// Well-known metadata keys for cross-service propagation (use with [Metadata]).
const (
	MetaRequestID = "rice.request_id"
	MetaUserID    = "rice.user_id"
	MetaTraceID   = "rice.trace_id"
	MetaSpanID    = "rice.span_id"
)

// Component names a service or subsystem in the .rice topology.
type Component string

// Pin is a stable identifier for a logical attachment point on a [Component].
type Pin struct {
	Component Component
	Name      string
}

// String returns a compact, human-readable pin label (single allocation).
func (p Pin) String() string {
	if p.Name == "" {
		return string(p.Component)
	}
	return string(p.Component) + "/" + p.Name
}

// Metadata holds string key/value baggage propagated alongside requests.
// The zero value is ready to use: reads miss until the first [Metadata.Set].
type Metadata struct {
	mu sync.RWMutex
	m  map[string]string
}

// Get returns the value for key. The boolean is false if the key is absent.
// Get does not allocate on the hot path when the key exists.
func (md *Metadata) Get(key string) (string, bool) {
	if md == nil {
		return "", false
	}
	md.mu.RLock()
	defer md.mu.RUnlock()
	if md.m == nil {
		return "", false
	}
	v, ok := md.m[key]
	return v, ok
}

// Set stores key=value. It is safe for concurrent use.
func (md *Metadata) Set(key, value string) {
	if md == nil {
		return
	}
	md.mu.Lock()
	defer md.mu.Unlock()
	if md.m == nil {
		md.m = make(map[string]string, 1)
	}
	md.m[key] = value
}

// Len returns the number of entries.
func (md *Metadata) Len() int {
	if md == nil {
		return 0
	}
	md.mu.RLock()
	defer md.mu.RUnlock()
	return len(md.m)
}

// Clone returns a shallow copy suitable for crossing an RPC boundary without
// sharing the live map with another goroutine.
func (md *Metadata) Clone() *Metadata {
	if md == nil {
		return nil
	}
	md.mu.RLock()
	defer md.mu.RUnlock()
	if len(md.m) == 0 {
		return &Metadata{}
	}
	cp := make(map[string]string, len(md.m))
	for k, v := range md.m {
		cp[k] = v
	}
	return &Metadata{m: cp}
}

type riceCtxKey struct{}

// Context extends the standard [context.Context] with OpenTelemetry trace
// identifiers and [Metadata] for SMITH services.
type Context struct {
	context.Context

	TraceID trace.TraceID
	SpanID  trace.SpanID
	Meta    *Metadata
}

// NewContext builds a [Context] from parent using the active span on parent (if any).
// meta may be nil; callers may attach a [*Metadata] on the returned value.
func NewContext(parent context.Context, meta *Metadata) *Context {
	if parent == nil {
		parent = context.Background()
	}
	sc := trace.SpanContextFromContext(parent)
	return &Context{
		Context: parent,
		TraceID: sc.TraceID(),
		SpanID:  sc.SpanID(),
		Meta:    meta,
	}
}

// FromContext returns a [*Context] stored in ctx, or synthesizes one from ctx
// and the current [trace.SpanContext] without allocating a [*Metadata].
func FromContext(ctx context.Context) *Context {
	if ctx == nil {
		return nil
	}
	if c, ok := ctx.Value(riceCtxKey{}).(*Context); ok && c != nil {
		return c
	}
	sc := trace.SpanContextFromContext(ctx)
	return &Context{
		Context: ctx,
		TraceID: sc.TraceID(),
		SpanID:  sc.SpanID(),
	}
}

// ToContext returns a standard [context.Context] that carries this [*Context] for [FromContext].
func (c *Context) ToContext() context.Context {
	if c == nil {
		return context.Background()
	}
	base := c.Context
	if base == nil {
		base = context.Background()
	}
	return context.WithValue(base, riceCtxKey{}, c)
}

// WithSpanContext returns a shallow copy with TraceID and SpanID taken from sc.
func (c *Context) WithSpanContext(sc trace.SpanContext) *Context {
	if c == nil {
		return nil
	}
	cp := *c
	cp.TraceID = sc.TraceID()
	cp.SpanID = sc.SpanID()
	return &cp
}
