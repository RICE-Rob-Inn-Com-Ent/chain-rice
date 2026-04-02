package kit

// TODO:
// [ ] implement type conversion helpers:
//     StringToInt64(s string) (int64, error)
//     Int64ToString(i int64) string
//     BytesToString(b []byte) string — zero-copy
//     StringToBytes(s string) []byte — zero-copy
// [ ] implement Cosmos SDK type conversions:
//     ToCosmosAddr(s string) (sdk.AccAddress, error)
//     ToCosmosCoins(amount string, denom string) sdk.Coins
//     denom from RICE_TOKEN_DENOM env var — never hardcoded
// [ ] implement decimal conversions:
//     StringToDecimal(s string) (cosmossdk.io/math.Dec, error)
//     DecimalToString(d math.Dec) string

import "cmp"

// Ptr returns a pointer to v (heap-allocated).
func Ptr[T any](v T) *T {
	return &v
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

// Zero reports whether v is the zero value (generic, comparable).
func Zero[T comparable](v T) bool {
	var z T
	return v == z
}

// Coalesce returns the first non-zero comparable value.
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
