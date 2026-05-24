package token

import (
	"fmt"

	"cosmossdk.io/math"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// SMITH modules allowed to inflate supply (must match [module.Module.Name] / router keys).
const (
	AuthorizedMinterSAGE = "sage"
	AuthorizedMinterKING = "king"
)

// EventTypeTokenMinted is the event type for indexers and the BARD UI.
const EventTypeTokenMinted = "TokenMinted"

// Attribute keys for TokenMinted events.
const (
	AttributeKeyMintRecipient   = "recipient"
	AttributeKeyMintAmount      = "amount"
	AttributeKeyMinterModule    = "minter_module"
	AttributeKeySupplyAfterMint = "supply_after"
	AttributeKeyMintDenom       = "denom"
	AttributeKeyAuthzGrantee    = "grantee"
	AttributeKeyAuthzGranter    = "granter"
)

var authorizedMinterModules = map[string]struct{}{
	AuthorizedMinterSAGE: {},
	AuthorizedMinterKING: {},
}

// RegisterAuthorizedMinter registers an additional module name allowed to call [Keeper.MintTokens].
func RegisterAuthorizedMinter(moduleName string) {
	if moduleName == "" {
		return
	}
	authorizedMinterModules[moduleName] = struct{}{}
}

// IsAuthorizedMinter reports whether callerModule may mint via the SMITH module path.
func IsAuthorizedMinter(callerModule string) bool {
	_, ok := authorizedMinterModules[callerModule]
	return ok
}

// MintTokens performs an authorized mint using on-chain [Params], updates [ManagedState] supply and balances, and emits TokenMinted.
func (k Keeper) MintTokens(ctx sdk.Context, callerModule string, recipient sdk.AccAddress, amount math.Int) error {
	goCtx := ctx.Context()
	if err := k.CheckCircuitAllowsOps(goCtx); err != nil {
		return err
	}
	if recipient.Empty() {
		return ErrInvalidAmount
	}
	if amount.IsNil() || amount.IsNegative() {
		return ErrInvalidAmount
	}
	if amount.IsZero() {
		return nil
	}
	if !IsAuthorizedMinter(callerModule) {
		return ErrUnauthorized
	}
	params, err := k.GetParams(goCtx)
	if err != nil {
		return err
	}
	if err := params.Validate(); err != nil {
		return fmt.Errorf("token mint: params: %w", err)
	}
	if !params.MintingEnabled {
		return ErrTokenLocked
	}
	if !amount.IsUint64() {
		return ErrInvalidAmount
	}

	sup, err := k.TotalSupply(goCtx)
	if err != nil {
		return err
	}
	next, err := Add(sup, amount)
	if err != nil {
		return err
	}
	if next.GT(params.MaxSupply) {
		return ErrInvalidAmount
	}

	if err := k.Mint(goCtx, recipient, amount); err != nil {
		return err
	}

	after, err := k.TotalSupply(goCtx)
	if err != nil {
		return err
	}
	denom, err := k.PrimaryMintDenom(goCtx)
	if err != nil {
		return err
	}

	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeTokenMinted,
			sdk.NewAttribute(AttributeKeyMintRecipient, recipient.String()),
			sdk.NewAttribute(AttributeKeyMintAmount, amount.String()),
			sdk.NewAttribute(AttributeKeyMinterModule, callerModule),
			sdk.NewAttribute(AttributeKeySupplyAfterMint, after.String()),
			sdk.NewAttribute(AttributeKeyMintDenom, denom),
		),
	)
	return nil
}

// MintTokensWithAuthzGrant mints to recipient after consuming a [AuthzKindMint] grant from granter to grantee.
func (k Keeper) MintTokensWithAuthzGrant(ctx sdk.Context, grantee, granter, recipient sdk.AccAddress, amount math.Int) error {
	goCtx := ctx.Context()
	if err := k.CheckCircuitAllowsOps(goCtx); err != nil {
		return err
	}
	if grantee.Empty() || granter.Empty() || recipient.Empty() {
		return ErrInvalidAmount
	}
	if amount.IsNil() || amount.IsNegative() || amount.IsZero() {
		return ErrInvalidAmount
	}
	if !amount.IsUint64() {
		return ErrInvalidAmount
	}

	params, err := k.GetParams(goCtx)
	if err != nil {
		return err
	}
	if err := params.Validate(); err != nil {
		return fmt.Errorf("token mint: params: %w", err)
	}
	if !params.MintingEnabled {
		return ErrTokenLocked
	}

	sup, err := k.TotalSupply(goCtx)
	if err != nil {
		return err
	}
	next, err := Add(sup, amount)
	if err != nil {
		return err
	}
	if next.GT(params.MaxSupply) {
		return ErrInvalidAmount
	}

	if err := k.ConsumeActionAuthz(goCtx, grantee, granter, AuthzKindMint, ctx.BlockHeight(), amount); err != nil {
		return err
	}

	if err := k.Mint(goCtx, recipient, amount); err != nil {
		return err
	}

	after, err := k.TotalSupply(goCtx)
	if err != nil {
		return err
	}
	denom, err := k.PrimaryMintDenom(goCtx)
	if err != nil {
		return err
	}

	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeTokenMinted,
			sdk.NewAttribute(AttributeKeyMintRecipient, recipient.String()),
			sdk.NewAttribute(AttributeKeyMintAmount, amount.String()),
			sdk.NewAttribute(AttributeKeyMinterModule, "authz_grant"),
			sdk.NewAttribute(AttributeKeySupplyAfterMint, after.String()),
			sdk.NewAttribute(AttributeKeyMintDenom, denom),
			sdk.NewAttribute(AttributeKeyAuthzGrantee, grantee.String()),
			sdk.NewAttribute(AttributeKeyAuthzGranter, granter.String()),
		),
	)
	return nil
}

// MintTokens is a package-level helper that delegates to [Keeper.MintTokens].
func MintTokens(ctx sdk.Context, k Keeper, callerModule string, recipient sdk.AccAddress, amount math.Int) error {
	return k.MintTokens(ctx, callerModule, recipient, amount)
}
