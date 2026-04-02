package kit

// TODO:
// [ ] implement UUID v4 generation via google/uuid:
//     NewUUID() uuid.UUID — panic-free generation
//     MustUUID() string — string form for JSON/proto
// [ ] implement UUID validation:
//     ParseUUID(s string) (uuid.UUID, error)
//     IsValidUUID(s string) bool
// [ ] implement UUID v7 (time-ordered) when RICE_UUID_V7=true:
//     NewUUIDv7() uuid.UUID — monotonic, sortable
//     preferred for database primary keys

import (
	"io"

	"github.com/google/uuid"
)

// UUID aliases the standard google/uuid type.
type UUID = uuid.UUID

// Nil is the zero UUID.
var Nil = uuid.Nil

// NewV4 returns a random UUID version 4.
func NewV4() (UUID, error) {
	return uuid.NewRandom()
}

// MustNewV4 returns NewV4 or panics on crypto failure.
func MustNewV4() UUID {
	return uuid.Must(uuid.NewRandom())
}

// NewV7 returns a time-ordered UUID version 7.
func NewV7() (UUID, error) {
	return uuid.NewV7()
}

// MustNewV7 returns NewV7 or panics on failure.
func MustNewV7() UUID {
	return uuid.Must(uuid.NewV7())
}

// Parse parses a UUID from string form.
func Parse(s string) (UUID, error) {
	return uuid.Parse(s)
}

// MustParse parses s or panics.
func MustParse(s string) UUID {
	return uuid.MustParse(s)
}

// Validate returns an error if s is not a valid UUID string.
func Validate(s string) error {
	_, err := uuid.Parse(s)
	return err
}

// IsNil reports whether id is the zero UUID.
func IsNil(id UUID) bool {
	return id == uuid.Nil
}

// NewBatch returns n distinct v4 UUIDs (best-effort; uses crypto/rand per draw).
func NewBatch(n int) []UUID {
	if n <= 0 {
		return nil
	}
	out := make([]UUID, n)
	for i := range out {
		out[i] = MustNewV4()
	}
	return out
}

// NewBatchV7 returns n v7 UUIDs (sequential time ordering per call).
func NewBatchV7(n int) ([]UUID, error) {
	if n <= 0 {
		return nil, nil
	}
	out := make([]UUID, n)
	for i := range out {
		u, err := uuid.NewV7()
		if err != nil {
			return out[:i], err
		}
		out[i] = u
	}
	return out, nil
}

// NewV7FromReader builds a v7 UUID using r for random bits (tests / deterministic seeds).
func NewV7FromReader(r io.Reader) (UUID, error) {
	return uuid.NewV7FromReader(r)
}
