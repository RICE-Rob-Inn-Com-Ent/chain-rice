package token

// TODO:
// [ ] implement Keeper struct:
//     storeService store.KVStoreService — from collections
//     Schema collections.Schema
//     Balances collections.Map[sdk.AccAddress, math.Int]
//     Metadata collections.Item[types.Metadata]
// [ ] implement keeper methods:
//     GetBalance(ctx, addr) (math.Int, error)
//     SetBalance(ctx, addr, amount math.Int) error
//     Transfer(ctx, from, to sdk.AccAddress, amount math.Int) error
//     all amounts via cosmossdk.io/math — never float64

import (
	"cosmossdk.io/core/store"
	"cosmossdk.io/log"
	storetypes "cosmossdk.io/store/types"

	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// CrossModuleKeepers groups interfaces this module needs from other modules (bank, auth, etc.).
// Define narrow interfaces here to keep the token keeper testable.
type CrossModuleKeepers struct {
	// Bank BankKeeper
	// Account AccountKeeper
}

// Keeper is the token module keeper: typed store access and cross-module calls.
type Keeper struct {
	cdc          codec.BinaryCodec
	storeService store.KVStoreService
	storeKey     storetypes.StoreKey
	external     CrossModuleKeepers
}

// NewKeeper constructs Keeper (invoked from depinject / module.go).
func NewKeeper(cdc codec.BinaryCodec, svc store.KVStoreService, key storetypes.StoreKey, ext CrossModuleKeepers) Keeper {
	return Keeper{cdc: cdc, storeService: svc, storeKey: key, external: ext}
}

// Logger returns the module-scoped logger (see log.go).
func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", "x/token")
}
