package token

import (
	"context"
	"fmt"
	"log/slog"

	"cosmossdk.io/collections"
	"cosmossdk.io/core/address"
	"cosmossdk.io/core/store"
	"cosmossdk.io/log"
	"cosmossdk.io/math"
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

// Keeper is the x/token controller: collections-backed state, codecs, logging, and governance authority.
// Embed this type in other SMITH modules when SAGE needs typed token access.
//
// Optional fields follow cosmossdk.io/depinject conventions for runtime module providers.
type Keeper struct {
	ManagedState ManagedState

	AddressCodec address.Codec `optional:"true"`
	Logger       log.Logger
	Authority    sdk.AccAddress
	Config       Config

	cdc          codec.BinaryCodec
	storeKey     *storetypes.KVStoreKey
	storeService store.KVStoreService
	Schema       collections.Schema
	external     CrossModuleKeepers
}

// NewKeeper builds a [Keeper] with a single collections schema over [ManagedState].
func NewKeeper(
	cdc codec.BinaryCodec,
	svc store.KVStoreService,
	key *storetypes.KVStoreKey,
	ext CrossModuleKeepers,
	ac address.Codec,
	authority sdk.AccAddress,
	logger log.Logger,
	cfg Config,
) (Keeper, error) {
	if logger == nil {
		logger = log.NewNopLogger()
	}
	moduleLogger := NewRiceTokenLogger(logger)
	if cfg.MintGasLimit == 0 && cfg.BurnGasLimit == 0 && cfg.TransferGasLimit == 0 {
		cfg = DefaultConfig()
	}

	sb := collections.NewSchemaBuilder(svc)
	ms := NewState(sb, cdc)
	schema, err := sb.Build()
	if err != nil {
		return Keeper{}, fmt.Errorf("token keeper schema: %w", err)
	}

	return Keeper{
		ManagedState: ms,
		AddressCodec: ac,
		Logger:       moduleLogger,
		Authority:    authority,
		Config:       cfg,
		cdc:          cdc,
		storeKey:     key,
		storeService: svc,
		Schema:       schema,
		external:     ext,
	}, nil
}

// GetAuthority returns the governance (or module authority) address configured for this keeper.
func (k Keeper) GetAuthority() sdk.AccAddress {
	if k.Authority == nil {
		return nil
	}
	out := make(sdk.AccAddress, len(k.Authority))
	copy(out, k.Authority)
	return out
}

// ContextLogger returns a RICE-token-prefixed logger, preferring the SDK context logger when set.
func (k Keeper) ContextLogger(ctx sdk.Context) log.Logger {
	if ctx.Logger() != nil {
		return NewRiceTokenLogger(ctx.Logger())
	}
	return k.Logger
}

func amountUint64(amt math.Int) (uint64, error) {
	if amt.IsNil() || amt.IsNegative() || !amt.IsUint64() {
		return 0, ErrInvalidAmount
	}
	return amt.Uint64(), nil
}

// Mint credits amt to addr and increases total supply for the primary mint denom.
func (k Keeper) Mint(ctx context.Context, addr sdk.AccAddress, amt math.Int) error {
	if amt.IsNil() || amt.IsZero() {
		return nil
	}
	if amt.IsNegative() {
		return ErrInvalidAmount
	}
	if err := k.CheckCircuitAllowsOps(ctx); err != nil {
		return err
	}
	denom, err := k.PrimaryMintDenom(ctx)
	if err != nil {
		return err
	}

	bal, err := k.GetBalance(ctx, addr)
	if err != nil {
		return err
	}
	newBal, err := Add(bal, amt)
	if err != nil {
		return err
	}

	supply, err := k.GetTotalSupplyForDenom(ctx, denom)
	if err != nil {
		return err
	}
	newSupply, err := Add(supply, amt)
	if err != nil {
		return err
	}

	if err := k.SetBalance(ctx, addr, newBal); err != nil {
		return err
	}
	if err := k.SetTotalSupplyForDenom(ctx, denom, newSupply); err != nil {
		return err
	}

	u, _ := amountUint64(amt)
	k.Logger.Info("token mint",
		slog.String("addr", addr.String()),
		slog.Uint64("amount", u),
		slog.String("balance_after", newBal.String()),
		slog.String("supply_after", newSupply.String()),
		slog.String("denom", denom),
	)
	return nil
}

// Burn debits amt from addr and decreases total supply for the primary mint denom.
func (k Keeper) Burn(ctx context.Context, addr sdk.AccAddress, amt math.Int) error {
	if amt.IsNil() || amt.IsZero() {
		return nil
	}
	if amt.IsNegative() {
		return ErrInvalidAmount
	}
	if err := k.CheckCircuitAllowsOps(ctx); err != nil {
		return err
	}
	denom, err := k.PrimaryMintDenom(ctx)
	if err != nil {
		return err
	}

	bal, err := k.GetBalance(ctx, addr)
	if err != nil {
		return err
	}
	newBal, err := Subtract(bal, amt)
	if err != nil {
		return err
	}

	supply, err := k.GetTotalSupplyForDenom(ctx, denom)
	if err != nil {
		return err
	}
	newSupply, err := Subtract(supply, amt)
	if err != nil {
		return err
	}

	if err := k.SetBalance(ctx, addr, newBal); err != nil {
		return err
	}
	if err := k.SetTotalSupplyForDenom(ctx, denom, newSupply); err != nil {
		return err
	}

	u, _ := amountUint64(amt)
	k.Logger.Info("token burn",
		slog.String("addr", addr.String()),
		slog.Uint64("amount", u),
		slog.String("balance_after", newBal.String()),
		slog.String("supply_after", newSupply.String()),
		slog.String("denom", denom),
	)
	return nil
}

// TotalSupply returns aggregate supply for the chain’s primary mint denom.
func (k Keeper) TotalSupply(ctx context.Context) (math.Int, error) {
	denom, err := k.PrimaryMintDenom(ctx)
	if err != nil {
		return math.Int{}, err
	}
	return k.GetTotalSupplyForDenom(ctx, denom)
}
