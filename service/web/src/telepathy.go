package web

import (
	"context"
	"crypto/rand"
	"encoding/binary"
	"errors"
	"hash/fnv"
	"iter"
	"sync"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
)

// Kit metadata keys for sub-atomic telepathy routing (propagate on gRPC via [kit.Metadata] / [kit.Context]).
const (
	MetaTelepathyOrigin       = "rice.telepathy.origin"
	MetaTelepathyDest         = "rice.telepathy.dest"
	MetaTelepathyEntanglement = "rice.telepathy.entanglement_id"
)

// EntanglementID identifies a logical Bell pair used for zero-latency correlation (in-process / mesh-local).
type EntanglementID string

// SubPacketRoute pins a logical “sub-atomic” hop between two kit attachment points (SMITH routing plane).
type SubPacketRoute struct {
	Origin kit.Pin
	Dest   kit.Pin
}

// SubPacketEnvelope is a logical frame: route labels + optional kit baggage + payload (hot path stays local; mesh egress may use [kit.NewClient] after collapse).
type SubPacketEnvelope struct {
	Route   SubPacketRoute
	Meta    *kit.Metadata
	Payload []byte
}

// ApplyRouteMetadata writes origin/dest pin strings onto md for cross-service sub-atomic routing.
func ApplyRouteMetadata(md *kit.Metadata, route SubPacketRoute) {
	if md == nil {
		return
	}
	md.Set(MetaTelepathyOrigin, route.Origin.String())
	md.Set(MetaTelepathyDest, route.Dest.String())
}

// ApplyEntanglementMetadata records the active entanglement id on md (e.g. before a kit gRPC hop).
func ApplyEntanglementMetadata(md *kit.Metadata, id EntanglementID) {
	if md == nil {
		return
	}
	md.Set(MetaTelepathyEntanglement, string(id))
}

// Measurement is the classical readout after [TelepathicBridge.CollapseWavefunction].
type Measurement struct {
	Bit       byte
	Route     SubPacketRoute
	Timestamp time.Time
}

// TelepathicBridge abstracts correlated data paths without traversing TCP for the hot path.
// Implementations may use shared memory, mesh fan-out, or other SMITH-local transports.
type TelepathicBridge interface {
	// Link establishes or refreshes entanglement along route (metadata travels on the kit plane).
	Link(ctx context.Context, route SubPacketRoute) (EntanglementID, error)
	// SyncState propagates coherent state between the entangled endpoints (logical no-op for pure classical bridges).
	SyncState(ctx context.Context, id EntanglementID) error
	// CollapseWavefunction performs a readout, destroying superposition for this id until re-linked.
	CollapseWavefunction(ctx context.Context, id EntanglementID) (Measurement, error)
}

// PinLattice holds kit pins used for sub-atomic packet routing labels (observable by BARD/SAGE).
type PinLattice struct {
	mu   sync.RWMutex
	pins []kit.Pin
}

// NewPinLattice returns an empty lattice.
func NewPinLattice() *PinLattice { return &PinLattice{} }

// Register adds a routing pin (deduped by [kit.Pin.String]).
func (pl *PinLattice) Register(p kit.Pin) {
	if pl == nil {
		return
	}
	key := p.String()
	pl.mu.Lock()
	defer pl.mu.Unlock()
	for _, existing := range pl.pins {
		if existing.String() == key {
			return
		}
	}
	pl.pins = append(pl.pins, p)
}

// Pins returns a snapshot copy.
func (pl *PinLattice) Pins() []kit.Pin {
	if pl == nil {
		return nil
	}
	pl.mu.RLock()
	defer pl.mu.RUnlock()
	out := make([]kit.Pin, len(pl.pins))
	copy(out, pl.pins)
	return out
}

// QuantumLinkManager coordinates [TelepathicBridge] sessions and kit [PinLattice] routing.
// It is the façade SAGE/BARD call for “quantum link” style fan-out without TCP on the critical section.
type QuantumLinkManager struct {
	Bridge TelepathicBridge
	Router *PinLattice
}

// QuantumLink is an alias for [QuantumLinkManager] (“QuantumLink” in the .rice topology).
type QuantumLink = QuantumLinkManager

// NewQuantumLinkManager returns a manager with the given bridge and optional lattice (nil → empty lattice).
func NewQuantumLinkManager(bridge TelepathicBridge, lattice *PinLattice) *QuantumLinkManager {
	if lattice == nil {
		lattice = NewPinLattice()
	}
	return &QuantumLinkManager{Bridge: bridge, Router: lattice}
}

// NewQuantumLink is shorthand for [NewQuantumLinkManager].
func NewQuantumLink(bridge TelepathicBridge, lattice *PinLattice) *QuantumLink {
	return NewQuantumLinkManager(bridge, lattice)
}

// EntangledBitSeq yields synthetic entangled bits derived from route + lattice pins.
// Consume with range-over-func: for b := range m.EntangledBitSeq(ctx, route) { ... }
func (m *QuantumLinkManager) EntangledBitSeq(ctx context.Context, route SubPacketRoute) iter.Seq[byte] {
	return func(yield func(byte) bool) {
		if m == nil || m.Router == nil {
			return
		}
		if ctx.Err() != nil {
			return
		}
		h := fnv.New64a()
		_, _ = h.Write([]byte(route.Origin.String()))
		_, _ = h.Write([]byte{0})
		_, _ = h.Write([]byte(route.Dest.String()))
		seed := h.Sum64()

		for i, p := range m.Router.Pins() {
			if ctx.Err() != nil {
				return
			}
			g := fnv.New64a()
			_, _ = g.Write([]byte(p.String()))
			_, _ = g.Write([]byte{byte(i)})
			bit := byte((seed ^ g.Sum64()) & 1)
			if !yield(bit) {
				return
			}
		}
	}
}

// EntangledPayloadSeq interleaves one parity bit from [QuantumLinkManager.EntangledBitSeq] with each payload byte,
// then yields any trailing payload. Use for stream processing without exposing raw TCP on the critical path:
//
//	for v := range m.EntangledPayloadSeq(ctx, env.Route, env.Payload) { ... }
func (m *QuantumLinkManager) EntangledPayloadSeq(ctx context.Context, route SubPacketRoute, payload []byte) iter.Seq[byte] {
	return func(yield func(byte) bool) {
		if m == nil {
			return
		}
		bitSeq := m.EntangledBitSeq(ctx, route)
		i := 0
		for parity := range bitSeq {
			if ctx.Err() != nil {
				return
			}
			if !yield(parity) {
				return
			}
			if i < len(payload) {
				if !yield(payload[i]) {
					return
				}
				i++
			}
		}
		for i < len(payload) {
			if ctx.Err() != nil {
				return
			}
			if !yield(payload[i]) {
				return
			}
			i++
		}
	}
}

// RouteSubAtomicPacket applies kit route metadata to env and returns an entangled byte stream of the envelope payload.
func (m *QuantumLinkManager) RouteSubAtomicPacket(ctx context.Context, env SubPacketEnvelope) iter.Seq[byte] {
	ApplyRouteMetadata(env.Meta, env.Route)
	return m.EntangledPayloadSeq(ctx, env.Route, env.Payload)
}

// Link delegates to the bridge and registers both pins on the lattice.
func (m *QuantumLinkManager) Link(ctx context.Context, route SubPacketRoute) (EntanglementID, error) {
	if m == nil || m.Bridge == nil {
		return "", errors.New("web.telepathy: nil manager or bridge")
	}
	if m.Router == nil {
		return "", errors.New("web.telepathy: nil router lattice")
	}
	m.Router.Register(route.Origin)
	m.Router.Register(route.Dest)
	return m.Bridge.Link(ctx, route)
}

// SyncState delegates to the bridge.
func (m *QuantumLinkManager) SyncState(ctx context.Context, id EntanglementID) error {
	if m == nil || m.Bridge == nil {
		return errors.New("web.telepathy: nil manager or bridge")
	}
	return m.Bridge.SyncState(ctx, id)
}

// CollapseWavefunction delegates to the bridge.
func (m *QuantumLinkManager) CollapseWavefunction(ctx context.Context, id EntanglementID) (Measurement, error) {
	if m == nil || m.Bridge == nil {
		return Measurement{}, errors.New("web.telepathy: nil manager or bridge")
	}
	return m.Bridge.CollapseWavefunction(ctx, id)
}

// RegisterTelepathySidecar registers an auxiliary gRPC service on the kit plane (e.g. health/reflection peers).
// Pass the same [kit.ServiceRegistrar] used by [NewGRPCServer]. fn should call the generated Register*Server(reg, impl).
func RegisterTelepathySidecar(reg kit.ServiceRegistrar, fn func(kit.ServiceRegistrar)) {
	if reg == nil || fn == nil {
		return
	}
	fn(reg)
}

// --- Local in-memory bridge (zero TCP hops; suitable for same-process “telepathy”). ---

type localBridge struct {
	mu    sync.Mutex
	pairs map[EntanglementID]*bellState
}

type bellState struct {
	route     SubPacketRoute
	phase     float64
	linkedAt  time.Time
	syncCount int
	collapsed bool
	bit       byte
}

// NewLocalTelepathicBridge builds a [TelepathicBridge] backed by memory (instantaneous correlation).
func NewLocalTelepathicBridge() TelepathicBridge {
	return &localBridge{pairs: make(map[EntanglementID]*bellState)}
}

func (b *localBridge) Link(ctx context.Context, route SubPacketRoute) (EntanglementID, error) {
	if err := ctx.Err(); err != nil {
		return "", err
	}
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "", err
	}
	id := EntanglementID(route.Origin.String() + "↔" + route.Dest.String() + ":" + binaryId(raw[:8]))

	b.mu.Lock()
	defer b.mu.Unlock()
	b.pairs[id] = &bellState{
		route:    route,
		phase:    float64(binary.BigEndian.Uint64(raw[8:])) / (1 << 63),
		linkedAt: time.Now(),
	}
	return id, nil
}

func (b *localBridge) SyncState(ctx context.Context, id EntanglementID) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	b.mu.Lock()
	defer b.mu.Unlock()
	st, ok := b.pairs[id]
	if !ok {
		return errors.New("web.telepathy: unknown entanglement id")
	}
	if st.collapsed {
		return errors.New("web.telepathy: pair already collapsed")
	}
	st.syncCount++
	st.phase = 1 - st.phase
	return nil
}

func (b *localBridge) CollapseWavefunction(ctx context.Context, id EntanglementID) (Measurement, error) {
	if err := ctx.Err(); err != nil {
		return Measurement{}, err
	}
	b.mu.Lock()
	defer b.mu.Unlock()
	st, ok := b.pairs[id]
	if !ok {
		return Measurement{}, errors.New("web.telepathy: unknown entanglement id")
	}
	if st.collapsed {
		return Measurement{Bit: st.bit, Route: st.route, Timestamp: time.Now()}, nil
	}
	h := fnv.New32a()
	_, _ = h.Write([]byte(id))
	_, _ = h.Write([]byte{byte(st.syncCount)})
	st.bit = byte(h.Sum32() & 1)
	st.collapsed = true
	return Measurement{Bit: st.bit, Route: st.route, Timestamp: time.Now()}, nil
}

func binaryId(b []byte) string {
	const hexd = "0123456789abcdef"
	out := make([]byte, len(b)*2)
	for i, v := range b {
		out[i*2] = hexd[v>>4]
		out[i*2+1] = hexd[v&0xf]
	}
	return string(out)
}
