package kit

// UUID utilities for SMITH: time-ordered generation (v7), parsing with domain errors,
// and deterministic test identities.

import (
	"errors"
	"net/http"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
)

// UUID is a named type over [github.com/google/uuid.UUID] so callers can attach
// methods without losing interop (convert with [UUID.Std] / [FromStd]).
type UUID uuid.UUID

// Nil is the zero UUID (all bits zero).
var Nil UUID

// mockUUID is a fixed, deterministic id for [Mock] (not a live random id).
var mockUUID = UUID(uuid.MustParse("00000000-0000-0000-0000-000000000001"))

// Std returns the underlying [uuid.UUID] for APIs that require that type.
func (id UUID) Std() uuid.UUID {
	return uuid.UUID(id)
}

// FromStd wraps a [uuid.UUID] as [UUID].
func FromStd(u uuid.UUID) UUID {
	return UUID(u)
}

// String returns the canonical hyphenated string form (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).
func (id UUID) String() string {
	return uuid.UUID(id).String()
}

// Bytes returns a 16-byte view of the UUID (backed by a stack array that escapes once).
func (id UUID) Bytes() []byte {
	var b [16]byte = uuid.UUID(id)
	return b[:]
}

// NewUUID returns a new time-ordered UUID (v7). If v7 generation fails, it falls back to v4.
// If both fail, it returns a [*Error] from the internal error path (crypto source).
// (Named NewUUID because [New] is the [*Error] constructor in this package.)
func NewUUID() (UUID, error) {
	u, err := uuid.NewV7()
	if err == nil {
		return UUID(u), nil
	}
	u4, err2 := uuid.NewRandom()
	if err2 != nil {
		return Nil, Internal("uuid: could not generate v7 or v4").Wrap(errors.Join(err, err2), "uuid")
	}
	return UUID(u4), nil
}

// MustNew returns [NewUUID] or panics on failure (init paths, tests).
func MustNew() UUID {
	u, err := NewUUID()
	if err != nil {
		panic(err)
	}
	return u
}

// Parse parses s into a [UUID]. On failure it returns a [*Error] with HTTP 400,
// gRPC InvalidArgument, and code INVALID_UUID_FORMAT.
func Parse(s string) (UUID, error) {
	u, err := uuid.Parse(s)
	if err != nil {
		return Nil, New("INVALID_UUID_FORMAT", "invalid UUID string", http.StatusBadRequest, codes.InvalidArgument).
			WithDetails(map[string]any{"input": truncateUUIDInput(s)}).
			Wrap(err, "uuid.Parse")
	}
	return UUID(u), nil
}

// MustParse is like [Parse] but panics on failure.
func MustParse(s string) UUID {
	u, err := Parse(s)
	if err != nil {
		panic(err)
	}
	return u
}

// FromBytes builds a [UUID] from exactly 16 bytes. On failure returns the same
// domain error shape as [Parse].
func FromBytes(b []byte) (UUID, error) {
	u, err := uuid.FromBytes(b)
	if err != nil {
		return Nil, New("INVALID_UUID_FORMAT", "invalid UUID bytes", http.StatusBadRequest, codes.InvalidArgument).
			WithDetails(map[string]any{"length": len(b)}).
			Wrap(err, "uuid.FromBytes")
	}
	return UUID(u), nil
}

// Validate reports whether s is a syntactically valid UUID string without allocating
// a [UUID] value (uses [uuid.Validate]).
func Validate(s string) bool {
	return uuid.Validate(s) == nil
}

// MockUUID returns a stable, predefined [UUID] for tests (never use in production for uniqueness).
// (Named MockUUID because [Mock] is the testify mock type alias in this package.)
func MockUUID() UUID {
	return mockUUID
}

// NewString returns [NewUUID] as a string (v7 preferred). If generation errors, falls back to
// [uuid.NewString] (v4) so callers always get an id.
func NewString() string {
	u, err := NewUUID()
	if err != nil {
		return uuid.NewString()
	}
	return u.String()
}

// IsNil reports whether id is the zero UUID.
func IsNil(id UUID) bool {
	return uuid.UUID(id) == uuid.Nil
}

func truncateUUIDInput(s string) string {
	const max = 128
	if len(s) <= max {
		return s
	}
	return s[:max] + "…"
}
