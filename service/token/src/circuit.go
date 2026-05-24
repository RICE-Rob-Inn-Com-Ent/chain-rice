package token

import (
	"context"
	"errors"

	"cosmossdk.io/collections"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// CheckCircuitAllowsOps returns [ErrTokenLocked] when the global circuit halt is engaged.
func (k Keeper) CheckCircuitAllowsOps(ctx context.Context) error {
	halted, err := k.IsCircuitHaltEngaged(ctx)
	if err != nil {
		return err
	}
	if halted {
		return ErrTokenLocked
	}
	return nil
}

// IsCircuitHaltEngaged reports whether SAGE / governance engaged the emergency halt.
func (k Keeper) IsCircuitHaltEngaged(ctx context.Context) (bool, error) {
	v, err := k.ManagedState.CircuitHalt.Get(ctx)
	if errors.Is(err, collections.ErrNotFound) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return v, nil
}

// SetCircuitHalt persists the global halt flag (used after authority checks).
func (k Keeper) SetCircuitHalt(ctx context.Context, halt bool) error {
	return k.ManagedState.CircuitHalt.Set(ctx, halt)
}

// PanicButton freezes or releases all token operations (mint, burn, transfers at call sites).
// Only [Keeper.Authority] may call this (typically the gov module account).
func (k Keeper) PanicButton(ctx sdk.Context, signer sdk.AccAddress, halt bool) error {
	if signer.Empty() || k.Authority.Empty() || !k.Authority.Equals(signer) {
		return ErrUnauthorized
	}
	return k.SetCircuitHalt(ctx.Context(), halt)
}
