package kit

// TODO:
// [ ] implement pagination:
//     Page struct: Number, Size, Total, HasNext
//     default page size from RICE_PAGE_SIZE env var (default: 30)
//     max page size from RICE_PAGE_SIZE_MAX env var (default: 100)
// [ ] implement cursor-based pagination:
//     Cursor string — base64-encoded offset
//     encode/decode cursor for pgx queries
// [ ] implement pagination for sqlc queries:
//     PageQuery(page Page) (limit, offset int)

import (
	"encoding/base64"
	"fmt"
	"strconv"
)

const (
	// DefaultPageLimit is used when clients omit or send 0.
	DefaultPageLimit = 20
	// MaxPageLimit caps page size to protect YugabyteDB / APIs.
	MaxPageLimit = 200
)

// Page describes offset/limit pagination plus optional opaque cursor and total rows.
type Page struct {
	Limit  int
	Offset int
	Total  int64
	Cursor string
}

// NormalizeLimit clamps n to [1, max]. Zero becomes DefaultPageLimit; negatives become 1.
func NormalizeLimit(n, max int) int {
	if max <= 0 {
		max = MaxPageLimit
	}
	if n <= 0 {
		n = DefaultPageLimit
	}
	if n > max {
		return max
	}
	return n
}

// NormalizeOffset returns non-negative offset.
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
