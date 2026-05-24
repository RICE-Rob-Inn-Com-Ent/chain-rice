package web

// Connect interceptors: logging/auth stubs plus Anti-Manifesto policy (quantum-consensus gate)
// and optional kit gRPC-style hooks.

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"

	"connectrpc.com/connect"
	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
)

// HeaderRiceEntityID is the canonical HTTP header carrying the logical entity / node id
// for Anti-Manifesto and consensus accounting.
const HeaderRiceEntityID = "Rice-Entity-Id"

type riceEntityKey struct{}

// WithRiceEntityID attaches an entity id to ctx for outgoing Connect calls when headers are not pre-set.
func WithRiceEntityID(ctx context.Context, entityID string) context.Context {
	return context.WithValue(ctx, riceEntityKey{}, strings.TrimSpace(entityID))
}

// RiceEntityIDFromContext returns the entity id from ctx, if any.
func RiceEntityIDFromContext(ctx context.Context) string {
	s, _ := ctx.Value(riceEntityKey{}).(string)
	return strings.TrimSpace(s)
}

// AntiManifestoMode is the global enforcement posture for rogue or low-consensus entities.
type AntiManifestoMode uint32

const (
	// AntiManifestoOff disables Anti-Manifesto checks (default until configured).
	AntiManifestoOff AntiManifestoMode = iota
	// AntiManifestoIsolate rejects traffic with UNAVAILABLE (soft eject / network isolation).
	AntiManifestoIsolate
	// AntiManifestoEject rejects traffic with PERMISSION_DENIED (hard eject).
	AntiManifestoEject
)

// ParseAntiManifestoMode maps env-style strings: off, isolate, eject (case-insensitive).
func ParseAntiManifestoMode(s string) AntiManifestoMode {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "isolate":
		return AntiManifestoIsolate
	case "eject":
		return AntiManifestoEject
	default:
		return AntiManifestoOff
	}
}

// AntiManifesto tracks quantum-consensus scores and an explicit rogue set; [ConnectAntiManifesto]
// consults it on every unary and streaming RPC.
type AntiManifesto struct {
	mu sync.RWMutex

	mode         atomic.Uint32
	minConsensus float64
	rogue        map[string]struct{}
	consensus    map[string]float64
}

// AntiManifestoGlobal is the process-wide switch and consensus ledger used by [ConnectAntiManifesto]
// when no instance is passed. Call [InitAntiManifestoFromEnv] during startup to load mode/threshold.
var AntiManifestoGlobal = NewAntiManifesto(0)

// NewAntiManifesto builds a ledger with the given minimum consensus in (0,1]; invalid values default to 0.51.
func NewAntiManifesto(minConsensus float64) *AntiManifesto {
	if minConsensus <= 0 || minConsensus > 1 {
		minConsensus = 0.51
	}
	return &AntiManifesto{
		minConsensus: minConsensus,
		rogue:        make(map[string]struct{}),
		consensus:    make(map[string]float64),
	}
}

// InitAntiManifestoFromEnv configures [AntiManifestoGlobal] from RICE_WEB_ANTIMANIFESTO (off|isolate|eject)
// and RICE_WEB_ANTIMANIFESTO_MIN_CONSENSUS (float, default 0.51).
func InitAntiManifestoFromEnv() {
	if v := strings.TrimSpace(os.Getenv("RICE_WEB_ANTIMANIFESTO_MIN_CONSENSUS")); v != "" {
		if f, err := strconv.ParseFloat(v, 64); err == nil && f > 0 && f <= 1 {
			AntiManifestoGlobal.SetMinConsensus(f)
		}
	}
	if v := strings.TrimSpace(os.Getenv("RICE_WEB_ANTIMANIFESTO")); v != "" {
		AntiManifestoGlobal.SetMode(ParseAntiManifestoMode(v))
	}
}

func (a *AntiManifesto) SetMode(m AntiManifestoMode) {
	if a == nil {
		return
	}
	a.mode.Store(uint32(m))
}

func (a *AntiManifesto) Mode() AntiManifestoMode {
	if a == nil {
		return AntiManifestoOff
	}
	return AntiManifestoMode(a.mode.Load())
}

func (a *AntiManifesto) SetMinConsensus(v float64) {
	if a == nil || v <= 0 || v > 1 {
		return
	}
	a.mu.Lock()
	a.minConsensus = v
	a.mu.Unlock()
}

// FlagRogue marks an entity for isolation/ejection regardless of consensus score.
func (a *AntiManifesto) FlagRogue(entityID string) {
	if a == nil || entityID == "" {
		return
	}
	a.mu.Lock()
	a.rogue[entityID] = struct{}{}
	a.mu.Unlock()
}

// ClearRogue removes an explicit rogue flag.
func (a *AntiManifesto) ClearRogue(entityID string) {
	if a == nil || entityID == "" {
		return
	}
	a.mu.Lock()
	delete(a.rogue, entityID)
	a.mu.Unlock()
}

// RecordQuantumVote updates a running consensus score in [0,1] (approve nudges up, disapprove nudges down).
func (a *AntiManifesto) RecordQuantumVote(entityID string, approve bool) {
	if a == nil || entityID == "" {
		return
	}
	const alpha = 0.15
	a.mu.Lock()
	defer a.mu.Unlock()
	cur, ok := a.consensus[entityID]
	if !ok {
		cur = 1
	}
	if approve {
		cur += alpha * (1 - cur)
	} else {
		cur -= alpha * cur
	}
	if cur < 0 {
		cur = 0
	}
	if cur > 1 {
		cur = 1
	}
	a.consensus[entityID] = cur
}

func (a *AntiManifesto) entityError(mode AntiManifestoMode, entityID string) error {
	if mode == AntiManifestoIsolate {
		return connect.NewError(connect.CodeUnavailable, fmtErrAntiManifestoIsolate(entityID))
	}
	return connect.NewError(connect.CodePermissionDenied, fmtErrAntiManifestoEject(entityID))
}

func (a *AntiManifesto) checkEntity(entityID string) error {
	if a == nil {
		return nil
	}
	mode := AntiManifestoMode(a.mode.Load())
	if mode == AntiManifestoOff {
		return nil
	}
	if entityID == "" {
		return nil
	}
	a.mu.RLock()
	defer a.mu.RUnlock()
	if _, bad := a.rogue[entityID]; bad {
		return a.entityError(mode, entityID)
	}
	score, ok := a.consensus[entityID]
	if !ok {
		return nil
	}
	if score < a.minConsensus {
		return a.entityError(mode, entityID)
	}
	return nil
}

func resolveAntiManifesto(am *AntiManifesto) *AntiManifesto {
	if am != nil {
		return am
	}
	return AntiManifestoGlobal
}

// ConnectAntiManifesto returns a [connect.Interceptor] that enforces the Anti-Manifesto policy.
// If am is nil, [AntiManifestoGlobal] is used.
func ConnectAntiManifesto(am *AntiManifesto) connect.Interceptor {
	return antiManifestoInterceptor{m: resolveAntiManifesto(am)}
}

type antiManifestoInterceptor struct {
	m *AntiManifesto
}

func (i antiManifestoInterceptor) entityFromUnary(ctx context.Context, req connect.AnyRequest) string {
	if req != nil {
		if v := req.Header().Get(HeaderRiceEntityID); v != "" {
			return strings.TrimSpace(v)
		}
	}
	return RiceEntityIDFromContext(ctx)
}

func (i antiManifestoInterceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		if err := i.m.checkEntity(i.entityFromUnary(ctx, req)); err != nil {
			return nil, err
		}
		return next(ctx, req)
	}
}

func (i antiManifestoInterceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return func(ctx context.Context, conn connect.StreamingHandlerConn) error {
		entity := RiceEntityIDFromContext(ctx)
		if conn != nil {
			if v := conn.RequestHeader().Get(HeaderRiceEntityID); v != "" {
				entity = strings.TrimSpace(v)
			}
		}
		if err := i.m.checkEntity(entity); err != nil {
			return err
		}
		return next(ctx, conn)
	}
}

func (i antiManifestoInterceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return func(ctx context.Context, spec connect.Spec) connect.StreamingClientConn {
		if err := i.m.checkEntity(RiceEntityIDFromContext(ctx)); err != nil {
			return &blockedStreamingClientConn{spec: spec, err: err}
		}
		return next(ctx, spec)
	}
}

// blockedStreamingClientConn fails all I/O with a pre-baked policy error (client-side eject/isolate).
type blockedStreamingClientConn struct {
	spec connect.Spec
	err  error
}

func (b *blockedStreamingClientConn) Spec() connect.Spec           { return b.spec }
func (b *blockedStreamingClientConn) Peer() connect.Peer           { return connect.Peer{} }
func (b *blockedStreamingClientConn) Send(any) error               { return b.err }
func (b *blockedStreamingClientConn) RequestHeader() http.Header   { return http.Header{} }
func (b *blockedStreamingClientConn) CloseRequest() error          { return nil }
func (b *blockedStreamingClientConn) Receive(any) error            { return b.err }
func (b *blockedStreamingClientConn) ResponseHeader() http.Header  { return http.Header{} }
func (b *blockedStreamingClientConn) ResponseTrailer() http.Header { return http.Header{} }
func (b *blockedStreamingClientConn) CloseResponse() error         { return nil }

// UnaryLoggingInterceptor is a gRPC unary interceptor stub (attach OTel / zap here).
func UnaryLoggingInterceptor(ctx context.Context, req any, info *kit.UnaryServerInfo, h kit.UnaryHandler) (any, error) {
	return h(ctx, req)
}

// StreamLoggingInterceptor is a gRPC stream interceptor stub.
func StreamLoggingInterceptor(srv any, ss kit.ServerStream, info *kit.StreamServerInfo, h kit.StreamHandler) error {
	return h(srv, ss)
}

// UnaryAuthInterceptor reads gRPC metadata (e.g. authorization) before invoking the handler.
func UnaryAuthInterceptor(ctx context.Context, req any, info *kit.UnaryServerInfo, h kit.UnaryHandler) (any, error) {
	_, _ = kit.FromIncomingContext(ctx)
	return h(ctx, req)
}

// ConnectUnaryLogging is a Connect interceptor for unary RPCs (metrics/tracing hooks).
func ConnectUnaryLogging() connect.Interceptor {
	return connect.UnaryInterceptorFunc(func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			return next(ctx, req)
		}
	})
}

func fmtErrAntiManifestoIsolate(entity string) error {
	if entity == "" {
		return ErrAntiManifestoIsolate
	}
	return fmt.Errorf("%w (entity %q)", ErrAntiManifestoIsolate, entity)
}

func fmtErrAntiManifestoEject(entity string) error {
	if entity == "" {
		return ErrAntiManifestoEject
	}
	return fmt.Errorf("%w (entity %q)", ErrAntiManifestoEject, entity)
}
