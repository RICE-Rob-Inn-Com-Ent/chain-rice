package token

import (
	"fmt"

	"cosmossdk.io/math"
)

// MustPositiveInt returns an error if i is zero or negative.
func MustPositiveInt(i math.Int) error {
	if i.IsNil() || i.IsNegative() || i.IsZero() {
		return fmt.Errorf("token amount must be positive: %s", i.String())
	}
	return nil
}

// SafeAddCoin returns a new Int with overflow checked semantics (delegates to math.Int.Add).
func SafeAddCoin(a, b math.Int) (math.Int, error) {
	if a.IsNil() || b.IsNil() {
		return math.Int{}, fmt.Errorf("nil amount")
	}
	return a.Add(b), nil
}
