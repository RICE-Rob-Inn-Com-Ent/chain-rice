package kit

// Offset/limit pagination for SMITH (HTTP, gRPC metadata, SQL).

import (
	"encoding/base64"
	"fmt"
	"strconv"
	"strings"
)

const (
	// DefaultPageLimit is used when clients omit, send 0, or send a negative limit.
	DefaultPageLimit = 20
	// MaxPageLimit caps page size to protect databases and APIs.
	MaxPageLimit = 100
)

// Metadata keys for [FromContext] (set these on [Context.Meta] from gRPC/Fiber).
const (
	MetaPageOffset = "rice.page.offset"
	MetaPageLimit  = "rice.page.limit"
	MetaPageSort   = "rice.page.sort"
)

// Page is offset/limit window plus optional sort clause and total row count (responses).
type Page struct {
	Offset int
	Limit  int
	Sort   string
	Total  int64
}

// Request carries client pagination input (e.g. from query params or proto).
type Request struct {
	Offset int
	Limit  int
	Sort   string
}

// Response is a single page of items with [Page] metadata (total, sort echo, etc.).
type Response[T any] struct {
	Data []T
	Page Page
}

// NewPage builds a normalized [Page]: non-negative offset, limit in (0, Max] with default 20.
func NewPage(offset, limit int) Page {
	if offset < 0 {
		offset = 0
	}
	lim := limit
	if lim <= 0 {
		lim = DefaultPageLimit
	} else if lim > MaxPageLimit {
		lim = MaxPageLimit
	}
	return Page{Offset: offset, Limit: lim}
}

// ToPage applies the same normalization as [NewPage] and copies [Request.Sort].
func (r Request) ToPage() Page {
	p := NewPage(r.Offset, r.Limit)
	p.Sort = strings.TrimSpace(r.Sort)
	return p
}

// ToSQL returns limit and offset for SQL/GORM/Ent (re-clamps if fields were mutated).
func (p Page) ToSQL() (limit int, offset int) {
	off := p.Offset
	if off < 0 {
		off = 0
	}
	lim := NormalizeLimit(p.Limit, MaxPageLimit)
	return lim, off
}

// HasNext reports whether another page exists after this window when [Page.Total] is known (>= 0).
func (p Page) HasNext() bool {
	if p.Total < 0 {
		return false
	}
	end := int64(p.Offset) + int64(p.Limit)
	return end < p.Total
}

// WithTotal returns a copy of p with Total set (typical after COUNT + SELECT).
func (p Page) WithTotal(total int64) Page {
	p.Total = total
	return p
}

// PageFromContext reads pagination from c.Meta ([MetaPageOffset], [MetaPageLimit], [MetaPageSort]).
// Missing or invalid values fall back to [NewPage](0, DefaultPageLimit).
// (Named PageFromContext because [FromContext] in this package unwraps [context.Context] into [*Context].)
func PageFromContext(c *Context) Page {
	if c == nil || c.Meta == nil {
		return NewPage(0, DefaultPageLimit)
	}
	off := parseMetaInt(c.Meta, MetaPageOffset, 0)
	lim := parseMetaInt(c.Meta, MetaPageLimit, DefaultPageLimit)
	p := NewPage(off, lim)
	if s, ok := c.Meta.Get(MetaPageSort); ok {
		p.Sort = strings.TrimSpace(s)
	}
	return p
}

func parseMetaInt(md *Metadata, key string, defaultVal int) int {
	s, ok := md.Get(key)
	if !ok || s == "" {
		return defaultVal
	}
	v, err := strconv.Atoi(strings.TrimSpace(s))
	if err != nil {
		return defaultVal
	}
	return v
}

// NormalizeLimit clamps n: <=0 → [DefaultPageLimit], >max → max.
func NormalizeLimit(n, max int) int {
	if max <= 0 {
		max = MaxPageLimit
	}
	if n <= 0 {
		return DefaultPageLimit
	}
	if n > max {
		return max
	}
	return n
}

// NormalizeOffset returns a non-negative offset.
func NormalizeOffset(n int) int {
	if n < 0 {
		return 0
	}
	return n
}

// EncodeCursor base64-encodes an opaque cursor token (e.g. last sort key).
func EncodeCursor(token string) string {
	if token == "" {
		return ""
	}
	return base64.RawURLEncoding.EncodeToString([]byte(token))
}

// DecodeCursor reverses [EncodeCursor].
func DecodeCursor(encoded string) (string, error) {
	if encoded == "" {
		return "", nil
	}
	b, err := base64.RawURLEncoding.DecodeString(encoded)
	if err != nil {
		return "", fmt.Errorf("kit: invalid cursor: %w", err)
	}
	return string(b), nil
}

// ParseIntQuery parses limit/offset from typical query string values ("", "0", "10").
func ParseIntQuery(s string, defaultVal int) (int, error) {
	if s == "" {
		return defaultVal, nil
	}
	v, err := strconv.Atoi(s)
	if err != nil {
		return defaultVal, fmt.Errorf("kit: parse int: %w", err)
	}
	return v, nil
}
