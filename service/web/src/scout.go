package web

// Web scout: gocloud blob indexing, semantic quality gating, Truth Filter reputations,
// and optional SAGE (Python/Mojo) HTTP hooks for logic checks before user-facing delivery.

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"hash/fnv"
	"io"
	"net/http"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"gocloud.dev/blob"
)

// Default scout blob layout under bucket prefix.
const (
	ScoutBlobPrefixDocs  = "scout/docs/"
	ScoutBlobPrefixIndex = "scout/index/"
	ScoutIndexManifest   = "scout/index/manifest.json"
)

// EnvSageScoutURL is the optional base URL for SAGE verification (POST /verify or full URL).
const EnvSageScoutURL = "RICE_SAGE_SCOUT_URL"

// ScoutDocument is indexed content plus origin node for reputation tracking.
type ScoutDocument struct {
	ID        string            `json:"id"`
	NodeID    string            `json:"node_id"`
	Title     string            `json:"title"`
	Body      string            `json:"body"`
	IndexedAt time.Time         `json:"indexed_at"`
	Meta      map[string]string `json:"meta,omitempty"`
}

// SemanticQuality is an AI-style quality signal (0 = useless, 1 = excellent).
type SemanticQuality struct {
	Score  float64  `json:"score"`
	Labels []string `json:"labels,omitempty"`
}

// SemanticAnalyzer performs semantic / quality analysis (LLM, embeddings, or heuristics).
type SemanticAnalyzer interface {
	Analyze(ctx context.Context, doc ScoutDocument) (SemanticQuality, error)
}

// HeuristicSemanticAnalyzer is a fast default: length, entropy proxy, spammy token penalty.
type HeuristicSemanticAnalyzer struct {
	MinRunes int
}

// Analyze implements [SemanticAnalyzer] without external AI (SAGE can replace via custom impl).
func (h HeuristicSemanticAnalyzer) Analyze(_ context.Context, doc ScoutDocument) (SemanticQuality, error) {
	min := h.MinRunes
	if min <= 0 {
		min = 64
	}
	body := strings.TrimSpace(doc.Body)
	title := strings.TrimSpace(doc.Title)
	if len([]rune(body)) < min {
		return SemanticQuality{Score: 0.15, Labels: []string{"short_content"}}, nil
	}
	score := 0.55
	if len([]rune(body)) > min*4 {
		score += 0.15
	}
	if title != "" {
		score += 0.1
	}
	low := strings.ToLower(body)
	for _, spam := range []string{"click here", "100% free", "guaranteed cure", "act now!!!"} {
		if strings.Contains(low, spam) {
			score -= 0.25
		}
	}
	if score < 0 {
		score = 0
	}
	if score > 1 {
		score = 1
	}
	return SemanticQuality{Score: score, Labels: []string{"heuristic"}}, nil
}

// SageVerdict is the outcome of a SAGE Python/Mojo logic pass.
type SageVerdict struct {
	OK     bool   `json:"ok"`
	Reason string `json:"reason,omitempty"`
}

// SageLogicVerifier calls SAGE-side validators (Mojo kernels, Python agents) before publish.
type SageLogicVerifier interface {
	Verify(ctx context.Context, doc ScoutDocument) (SageVerdict, error)
}

// NopSageVerifier always approves (use when SAGE is not deployed).
type NopSageVerifier struct{}

// Verify implements [SageLogicVerifier].
func (NopSageVerifier) Verify(context.Context, ScoutDocument) (SageVerdict, error) {
	return SageVerdict{OK: true}, nil
}

// HTTPSageVerifier POSTs JSON to BaseURL/verify (or full URL if BaseURL ends with /verify).
type HTTPSageVerifier struct {
	BaseURL string
	Client  *http.Client
}

// Verify implements [SageLogicVerifier]. Expects JSON response: {"ok":true,"reason":"..."}.
func (v HTTPSageVerifier) Verify(ctx context.Context, doc ScoutDocument) (SageVerdict, error) {
	if strings.TrimSpace(v.BaseURL) == "" {
		return SageVerdict{OK: true}, nil
	}
	u := strings.TrimSuffix(v.BaseURL, "/")
	if !strings.HasSuffix(u, "verify") {
		u += "/verify"
	}
	payload, err := json.Marshal(doc)
	if err != nil {
		return SageVerdict{}, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, u, bytes.NewReader(payload))
	if err != nil {
		return SageVerdict{}, err
	}
	req.Header.Set("Content-Type", "application/json")
	cli := v.Client
	if cli == nil {
		cli = http.DefaultClient
	}
	resp, err := cli.Do(req)
	if err != nil {
		return SageVerdict{}, err
	}
	defer resp.Body.Close()
	b, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return SageVerdict{}, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return SageVerdict{OK: false, Reason: fmt.Sprintf("sage http %d: %s", resp.StatusCode, string(b))}, nil
	}
	var out SageVerdict
	if err := json.Unmarshal(b, &out); err != nil {
		return SageVerdict{OK: false, Reason: "sage: invalid json verdict"}, nil
	}
	return out, nil
}

// TruthFilter penalizes sources that push low-quality or rejected documents (misinformation pressure).
type TruthFilter struct {
	mu sync.RWMutex
	// penalty accumulates per NodeID; trust = 1/(1+penalty) clamped.
	penalty  map[string]float64
	floor    float64 // minimum trust to ingest
	stepBad  float64 // penalty on semantic/sage failure
	stepGood float64 // small reward on success (decay toward neutral)
	maxTrust float64
	minTrust float64
}

// NewTruthFilter returns a filter with defaults suitable for production tuning.
func NewTruthFilter() *TruthFilter {
	return &TruthFilter{
		penalty:  make(map[string]float64),
		floor:    0.22,
		stepBad:  0.18,
		stepGood: 0.02,
		maxTrust: 1.0,
		minTrust: 0.05,
	}
}

// Trust returns a score in [minTrust, maxTrust] derived from accumulated penalties.
func (t *TruthFilter) Trust(nodeID string) float64 {
	if t == nil {
		return 1
	}
	t.mu.RLock()
	p := t.penalty[nodeID]
	t.mu.RUnlock()
	raw := 1.0 / (1.0 + p)
	if raw < t.minTrust {
		return t.minTrust
	}
	if raw > t.maxTrust {
		return t.maxTrust
	}
	return raw
}

// AllowIngest reports whether the node may publish through the scout pipeline.
func (t *TruthFilter) AllowIngest(nodeID string) bool {
	if t == nil {
		return true
	}
	return t.Trust(nodeID) >= t.floor
}

// PenalizeMisinformation increases penalty (call when content is rejected or contradicts verified facts).
func (t *TruthFilter) PenalizeMisinformation(nodeID string, severity float64) {
	if t == nil || nodeID == "" {
		return
	}
	if severity <= 0 {
		severity = t.stepBad
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	t.penalty[nodeID] += severity
}

// RewardQuality lightly reduces penalty on successful high-truth publishes.
func (t *TruthFilter) RewardQuality(nodeID string) {
	if t == nil || nodeID == "" {
		return
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	v := t.penalty[nodeID] - t.stepGood
	if v < 0 {
		v = 0
	}
	t.penalty[nodeID] = v
}

// IndexManifest lists document ids for fast bulk reads (BARD/SAGE consumers).
type IndexManifest struct {
	DocIDs    []string  `json:"doc_ids"`
	UpdatedAt time.Time `json:"updated_at"`
}

// WebScout indexes documents into gocloud blob storage with semantic + SAGE + Truth Filter gates.
type WebScout struct {
	Bucket   *blob.Bucket
	Prefix   string
	Truth    *TruthFilter
	Semantic SemanticAnalyzer
	Sage     SageLogicVerifier
	// MinSemantic is the minimum [SemanticQuality.Score] required to index.
	MinSemantic float64
	HTTP        *http.Client
}

// NewWebScout builds a scout with defaults: heuristic semantic, env-backed SAGE if set, truth filter on.
func NewWebScout(b *blob.Bucket, prefix string) *WebScout {
	if prefix != "" && !strings.HasSuffix(prefix, "/") {
		prefix += "/"
	}
	sage := SageLogicVerifier(NopSageVerifier{})
	if u := strings.TrimSpace(os.Getenv(EnvSageScoutURL)); u != "" {
		sage = HTTPSageVerifier{BaseURL: u, Client: http.DefaultClient}
	}
	return &WebScout{
		Bucket:      b,
		Prefix:      prefix,
		Truth:       NewTruthFilter(),
		Semantic:    HeuristicSemanticAnalyzer{},
		Sage:        sage,
		MinSemantic: 0.35,
		HTTP:        http.DefaultClient,
	}
}

func (s *WebScout) docKey(id string) string {
	return s.Prefix + ScoutBlobPrefixDocs + strings.TrimSpace(id) + ".json"
}

func (s *WebScout) manifestKey() string {
	return s.Prefix + ScoutIndexManifest
}

// Ingest runs semantic analysis → SAGE logic verify → blob write → index manifest update.
// Misinformation attempts (low quality / SAGE reject) penalize the node via [TruthFilter].
func (s *WebScout) Ingest(ctx context.Context, doc ScoutDocument) error {
	if s == nil || s.Bucket == nil {
		return ErrScoutNilBucket
	}
	if strings.TrimSpace(doc.ID) == "" || strings.TrimSpace(doc.NodeID) == "" {
		return fmt.Errorf("web.scout: id and node_id required")
	}
	if s.Truth != nil && !s.Truth.AllowIngest(doc.NodeID) {
		return ErrScoutLowTrust
	}
	doc.IndexedAt = time.Now().UTC()

	q, err := s.analyze(ctx, doc)
	if err != nil {
		return err
	}
	if q.Score < s.MinSemantic {
		if s.Truth != nil {
			s.Truth.PenalizeMisinformation(doc.NodeID, s.Truth.stepBad)
		}
		return ErrScoutLowQuality
	}

	sv, err := s.verifySage(ctx, doc)
	if err != nil {
		return err
	}
	if !sv.OK {
		if s.Truth != nil {
			s.Truth.PenalizeMisinformation(doc.NodeID, s.Truth.stepBad*1.5)
		}
		if strings.TrimSpace(sv.Reason) != "" {
			return fmt.Errorf("%w: %s", ErrScoutSageReject, sv.Reason)
		}
		return ErrScoutSageReject
	}

	raw, err := json.Marshal(doc)
	if err != nil {
		return err
	}
	key := s.docKey(doc.ID)
	if err := Upload(ctx, s.Bucket, key, bytes.NewReader(raw), "application/json"); err != nil {
		return err
	}
	if err := s.mergeManifest(ctx, doc.ID); err != nil {
		return err
	}
	if s.Truth != nil {
		s.Truth.RewardQuality(doc.NodeID)
	}
	return nil
}

func (s *WebScout) analyze(ctx context.Context, doc ScoutDocument) (SemanticQuality, error) {
	sa := s.Semantic
	if sa == nil {
		sa = HeuristicSemanticAnalyzer{}
	}
	return sa.Analyze(ctx, doc)
}

func (s *WebScout) verifySage(ctx context.Context, doc ScoutDocument) (SageVerdict, error) {
	v := s.Sage
	if v == nil {
		v = NopSageVerifier{}
	}
	return v.Verify(ctx, doc)
}

func (s *WebScout) mergeManifest(ctx context.Context, docID string) error {
	m := IndexManifest{DocIDs: nil, UpdatedAt: time.Now().UTC()}
	if r, err := Download(ctx, s.Bucket, s.manifestKey()); err == nil {
		defer r.Close()
		_ = json.NewDecoder(r).Decode(&m)
	}
	seen := map[string]struct{}{}
	for _, id := range m.DocIDs {
		seen[id] = struct{}{}
	}
	seen[docID] = struct{}{}
	m.DocIDs = m.DocIDs[:0]
	for id := range seen {
		m.DocIDs = append(m.DocIDs, id)
	}
	sort.Strings(m.DocIDs)
	m.UpdatedAt = time.Now().UTC()
	b, err := json.Marshal(m)
	if err != nil {
		return err
	}
	return Upload(ctx, s.Bucket, s.manifestKey(), bytes.NewReader(b), "application/json")
}

// ReadDocument loads a single indexed document from blob storage.
func (s *WebScout) ReadDocument(ctx context.Context, id string) (ScoutDocument, error) {
	var z ScoutDocument
	if s == nil || s.Bucket == nil {
		return z, ErrScoutNilBucket
	}
	r, err := Download(ctx, s.Bucket, s.docKey(id))
	if err != nil {
		return z, err
	}
	defer r.Close()
	if err := json.NewDecoder(r).Decode(&z); err != nil {
		return z, err
	}
	return z, nil
}

// ReadManifest returns the index manifest (doc id list).
func (s *WebScout) ReadManifest(ctx context.Context) (IndexManifest, error) {
	var m IndexManifest
	if s == nil || s.Bucket == nil {
		return m, ErrScoutNilBucket
	}
	r, err := Download(ctx, s.Bucket, s.manifestKey())
	if err != nil {
		return m, err
	}
	defer r.Close()
	err = json.NewDecoder(r).Decode(&m)
	return m, err
}

// ScoutPin returns a [kit.Pin] labeling this scout instance for telepathy / mesh routing.
func ScoutPin(component kit.Component, name string) kit.Pin {
	return kit.Pin{Component: component, Name: name}
}

// DedupeKey is a stable short key for idempotency (optional caller use).
func DedupeKey(doc ScoutDocument) string {
	h := fnv.New64a()
	_, _ = h.Write([]byte(doc.NodeID))
	_, _ = h.Write([]byte{0})
	_, _ = h.Write([]byte(doc.Title))
	_, _ = h.Write([]byte{0})
	_, _ = h.Write([]byte(doc.Body))
	return fmt.Sprintf("%x", h.Sum64())
}
