package token

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"cosmossdk.io/collections"
	"cosmossdk.io/math"
	storetypes "cosmossdk.io/store/types"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// KV store keys for the token module and related persistence (IAVL commit multistore keys).
var (
	StoreKeyToken = storetypes.NewKVStoreKey(StoreKey)
	// MemStoreKeyToken optional in-memory store for transient state (e.g. iterators).
	MemStoreKeyToken = storetypes.NewMemoryStoreKey("mem_token")
)

// StoreKeys returns all KV keys registered with BaseApp for the token app slice.
func StoreKeys() map[string]*storetypes.KVStoreKey {
	return map[string]*storetypes.KVStoreKey{
		StoreKey: StoreKeyToken,
	}
}

// GetParams loads module parameters; if unset, returns [DefaultParams] and no error.
func (k Keeper) GetParams(ctx context.Context) (Params, error) {
	p, err := k.ManagedState.Params.Get(ctx)
	if err == nil {
		return p, nil
	}
	if errors.Is(err, collections.ErrNotFound) {
		return DefaultParams(), nil
	}
	return Params{}, err
}

// SetParams persists parameters after [Params.Validate].
func (k Keeper) SetParams(ctx context.Context, p Params) error {
	if err := p.Validate(); err != nil {
		return err
	}
	return k.ManagedState.Params.Set(ctx, p)
}

// PrimaryMintDenom returns the canonical mint denom from stored params (or default if unset).
func (k Keeper) PrimaryMintDenom(ctx context.Context) (string, error) {
	p, err := k.GetParams(ctx)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(p.MintDenom), nil
}

// GetBalance returns the account balance; missing keys read as zero.
func (k Keeper) GetBalance(ctx context.Context, addr sdk.AccAddress) (math.Int, error) {
	if addr.Empty() {
		return math.Int{}, ErrInvalidAmount
	}
	v, err := k.ManagedState.Balances.Get(ctx, addr)
	if err == nil {
		return v, nil
	}
	if errors.Is(err, collections.ErrNotFound) {
		return math.ZeroInt(), nil
	}
	return math.Int{}, err
}

// SetBalance sets the absolute balance. Negative amounts return [ErrInvalidAmount].
// Zero removes the balance entry.
func (k Keeper) SetBalance(ctx context.Context, addr sdk.AccAddress, amt math.Int) error {
	if addr.Empty() {
		return ErrInvalidAmount
	}
	if amt.IsNil() || amt.IsNegative() {
		return ErrInvalidAmount
	}
	if amt.IsZero() {
		return k.ManagedState.Balances.Remove(ctx, addr)
	}
	return k.ManagedState.Balances.Set(ctx, addr, amt)
}

// IterateBalances walks all non-range-limited balance entries. Return true from cb to stop early.
func (k Keeper) IterateBalances(ctx context.Context, cb func(sdk.AccAddress, math.Int) (stop bool, err error)) error {
	return k.ManagedState.Balances.Walk(ctx, nil, cb)
}

// GetTotalSupplyForDenom returns tracked supply for denom; missing reads as zero.
func (k Keeper) GetTotalSupplyForDenom(ctx context.Context, denom string) (math.Int, error) {
	denom = strings.TrimSpace(denom)
	if denom == "" {
		return math.Int{}, fmt.Errorf("token: empty denom")
	}
	v, err := k.ManagedState.TotalSupply.Get(ctx, denom)
	if err == nil {
		return v, nil
	}
	if errors.Is(err, collections.ErrNotFound) {
		return math.ZeroInt(), nil
	}
	return math.Int{}, err
}

// SetTotalSupplyForDenom sets absolute supply for denom. Negative returns [ErrInvalidAmount].
// Zero removes the denom entry.
func (k Keeper) SetTotalSupplyForDenom(ctx context.Context, denom string, amt math.Int) error {
	denom = strings.TrimSpace(denom)
	if denom == "" {
		return fmt.Errorf("token: empty denom")
	}
	if amt.IsNil() || amt.IsNegative() {
		return ErrInvalidAmount
	}
	if amt.IsZero() {
		return k.ManagedState.TotalSupply.Remove(ctx, denom)
	}
	return k.ManagedState.TotalSupply.Set(ctx, denom, amt)
}

// IterateTotalSupply walks denom → supply. Return true from cb to stop early.
func (k Keeper) IterateTotalSupply(ctx context.Context, cb func(denom string, amt math.Int) (stop bool, err error)) error {
	return k.ManagedState.TotalSupply.Walk(ctx, nil, cb)
}

// Send moves amt from fromAddr to toAddr without changing total supply (peer transfer).
func (k Keeper) Send(ctx context.Context, fromAddr, toAddr sdk.AccAddress, amt math.Int) error {
	if fromAddr.Empty() || toAddr.Empty() {
		return ErrInvalidAmount
	}
	if fromAddr.Equals(toAddr) {
		return ErrInvalidAmount
	}
	if amt.IsNil() || amt.IsNegative() || amt.IsZero() {
		return ErrInvalidAmount
	}
	if err := k.CheckCircuitAllowsOps(ctx); err != nil {
		return err
	}
	fromBal, err := k.GetBalance(ctx, fromAddr)
	if err != nil {
		return err
	}
	newFrom, err := Subtract(fromBal, amt)
	if err != nil {
		return ErrInsufficientFunds
	}
	toBal, err := k.GetBalance(ctx, toAddr)
	if err != nil {
		return err
	}
	newTo, err := Add(toBal, amt)
	if err != nil {
		return err
	}
	if err := k.SetBalance(ctx, fromAddr, newFrom); err != nil {
		return err
	}
	return k.SetBalance(ctx, toAddr, newTo)
}
