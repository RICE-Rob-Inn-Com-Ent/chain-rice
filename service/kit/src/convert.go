package kit

// Generic conversion helpers for SMITH. Map/struct shims use JSON (field names follow json tags).

import (
	"cmp"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"google.golang.org/grpc/codes"
)

// Ptr returns a pointer to v (heap-allocated).
func Ptr[T any](v T) *T {
	return &v
}

// Val returns *p, or the zero value of T if p is nil.
func Val[T any](p *T) T {
	return Deref(p)
}

// Deref returns *p or zero if p is nil.
func Deref[T any](p *T) T {
	if p == nil {
		var z T
		return z
	}
	return *p
}

// DerefOr returns *p or fallback when p is nil.
func DerefOr[T any](p *T, fallback T) T {
	if p == nil {
		return fallback
	}
	return *p
}

// Map returns fn applied to each element of s (pre-sized; one allocation for output).
func Map[T, U any](s []T, fn func(T) U) []U {
	if len(s) == 0 {
		return nil
	}
	out := make([]U, len(s))
	for i := range s {
		out[i] = fn(s[i])
	}
	return out
}

// Filter returns elements of s for which fn returns true (order preserved).
func Filter[T any](s []T, fn func(T) bool) []T {
	if len(s) == 0 {
		return nil
	}
	out := make([]T, 0)
	for i := range s {
		if fn(s[i]) {
			out = append(out, s[i])
		}
	}
	return out
}

// Unique returns s with only the first occurrence of each value (order preserved).
func Unique[T comparable](s []T) []T {
	if len(s) == 0 {
		return nil
	}
	seen := make(map[T]struct{}, len(s))
	out := make([]T, 0, len(s))
	for i := range s {
		v := s[i]
		if _, ok := seen[v]; ok {
			continue
		}
		seen[v] = struct{}{}
		out = append(out, v)
	}
	return out
}

// ToString converts v to a readable string without reflection in common cases.
func ToString(v any) string {
	switch x := v.(type) {
	case nil:
		return ""
	case string:
		return x
	case []byte:
		return string(x)
	case fmt.Stringer:
		return x.String()
	case bool:
		return strconv.FormatBool(x)
	case int:
		return strconv.Itoa(x)
	case int8:
		return strconv.FormatInt(int64(x), 10)
	case int16:
		return strconv.FormatInt(int64(x), 10)
	case int32:
		return strconv.FormatInt(int64(x), 10)
	case int64:
		return strconv.FormatInt(x, 10)
	case uint:
		return strconv.FormatUint(uint64(x), 10)
	case uint8:
		return strconv.FormatUint(uint64(x), 10)
	case uint16:
		return strconv.FormatUint(uint64(x), 10)
	case uint32:
		return strconv.FormatUint(uint64(x), 10)
	case uint64:
		return strconv.FormatUint(x, 10)
	case float32:
		return strconv.FormatFloat(float64(x), 'g', -1, 32)
	case float64:
		return strconv.FormatFloat(x, 'g', -1, 64)
	case json.Number:
		return x.String()
	default:
		return fmt.Sprint(v)
	}
}

// ToInt parses s as base-10 int. On failure returns a [*Error] with code INVALID_INTEGER.
func ToInt(s string) (int, error) {
	i, err := strconv.Atoi(s)
	if err != nil {
		return 0, New("INVALID_INTEGER", "invalid integer string", http.StatusBadRequest, codes.InvalidArgument).
			WithDetails(map[string]any{"input": truncateConvertInput(s)}).
			Wrap(err, "strconv.Atoi")
	}
	return i, nil
}

// ToMap encodes obj as JSON and decodes into map[string]any (keys follow json tags on obj).
func ToMap(obj any) (map[string]any, error) {
	b, err := json.Marshal(obj)
	if err != nil {
		return nil, Internal("convert.ToMap: json.Marshal").Wrap(err, "json.Marshal")
	}
	var out map[string]any
	if err := json.Unmarshal(b, &out); err != nil {
		return nil, Internal("convert.ToMap: json.Unmarshal").Wrap(err, "json.Unmarshal")
	}
	return out, nil
}

// FromMap fills obj (must be a non-nil pointer) from m using JSON encode/decode (json tags apply).
func FromMap(m map[string]any, obj any) error {
	if m == nil {
		return BadRequest("convert.FromMap: nil map")
	}
	if obj == nil {
		return Internal("convert.FromMap: nil destination")
	}
	b, err := json.Marshal(m)
	if err != nil {
		return Internal("convert.FromMap: json.Marshal").Wrap(err, "json.Marshal")
	}
	if err := json.Unmarshal(b, obj); err != nil {
		return New("INVALID_MAP_SHAPE", "cannot decode map into destination type", http.StatusBadRequest, codes.InvalidArgument).
			Wrap(err, "json.Unmarshal")
	}
	return nil
}

// ToBytes marshals v to JSON bytes.
func ToBytes(v any) ([]byte, error) {
	b, err := json.Marshal(v)
	if err != nil {
		return nil, Internal("convert.ToBytes: json.Marshal").Wrap(err, "json.Marshal")
	}
	return b, nil
}

// Zero reports whether v is the zero value (T must be comparable).
func Zero[T comparable](v T) bool {
	var z T
	return v == z
}

// Coalesce returns the first non-zero [cmp.Ordered] value.
func Coalesce[T cmp.Ordered](vals ...T) T {
	var z T
	for _, v := range vals {
		if v != z {
			return v
		}
	}
	return z
}

// Clamp constrains x to [lo, hi] for ordered types (see [cmp.Ordered]).
func Clamp[T cmp.Ordered](x, lo, hi T) T {
	if x < lo {
		return lo
	}
	if x > hi {
		return hi
	}
	return x
}

func truncateConvertInput(s string) string {
	const max = 64
	if len(s) <= max {
		return s
	}
	return s[:max] + "…"
}
