package token

import (
	"cosmossdk.io/math"
)

// MustPositiveInt returns [ErrInvalidAmount] if i is nil, zero, or negative.
func MustPositiveInt(i math.Int) error {
	if i.IsNil() || i.IsNegative() || i.IsZero() {
		return ErrInvalidAmount
	}
	return nil
}

// Add returns a + b. Nil inputs or integer overflow yield [ErrInvalidAmount].
func Add(a, b math.Int) (math.Int, error) {
	if a.IsNil() || b.IsNil() {
		return math.Int{}, ErrInvalidAmount
	}
	sum, err := a.SafeAdd(b)
	if err != nil {
		return math.Int{}, ErrInvalidAmount
	}
	return sum, nil
}

// Subtract returns balance - amount. Nil inputs, amount greater than balance, or underflow yield
// [ErrInvalidAmount] or [ErrInsufficientFunds] respectively.
func Subtract(balance, amount math.Int) (math.Int, error) {
	if balance.IsNil() || amount.IsNil() {
		return math.Int{}, ErrInvalidAmount
	}
	if amount.IsNegative() {
		return math.Int{}, ErrInvalidAmount
	}
	if balance.LT(amount) {
		return math.Int{}, ErrInsufficientFunds
	}
	out, err := balance.SafeSub(amount)
	if err != nil {
		return math.Int{}, ErrInsufficientFunds
	}
	return out, nil
}

// SafeAddCoin is a legacy name for [Add].
func SafeAddCoin(a, b math.Int) (math.Int, error) {
	return Add(a, b)
}
