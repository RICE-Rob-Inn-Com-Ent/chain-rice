package token

import (
	"fmt"

	"cosmossdk.io/math"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// EventTypeTokenBurned is the event type for indexers and the BARD UI.
const EventTypeTokenBurned = "TokenBurned"

// Attribute keys for TokenBurned events.
const (
	AttributeKeyBurnSender      = "sender"
	AttributeKeyBurnAmount      = "amount"
	AttributeKeySupplyAfterBurn = "supply_after"
	AttributeKeyFeeBurnReason   = "reason"
	AttributeKeyBurnDenom       = "denom"
	AttributeKeyBurnGrantee     = "grantee"
	AttributeKeyBurnGranter     = "granter"
)

// FeeBurnReason tags FeeBurn-driven burns for analytics.
const FeeBurnReason = "fee_burn"

// BurnTokens debits amount from sender, decreases total supply, and emits TokenBurned.
func (k Keeper) BurnTokens(ctx sdk.Context, sender sdk.AccAddress, amount math.Int) error {
	goCtx := ctx.Context()
	if err := k.CheckCircuitAllowsOps(goCtx); err != nil {
		return err
	}
	if sender.Empty() {
		return ErrInvalidAmount
	}
	if amount.IsNil() || amount.IsNegative() {
		return ErrInvalidAmount
	}
	if amount.IsZero() {
		return nil
	}

	bal, err := k.GetBalance(goCtx, sender)
	if err != nil {
		return err
	}
	if bal.LT(amount) {
		return ErrInsufficientFunds
	}

	if err := k.Burn(goCtx, sender, amount); err != nil {
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
			EventTypeTokenBurned,
			sdk.NewAttribute(AttributeKeyBurnSender, sender.String()),
			sdk.NewAttribute(AttributeKeyBurnAmount, amount.String()),
			sdk.NewAttribute(AttributeKeySupplyAfterBurn, after.String()),
			sdk.NewAttribute(AttributeKeyBurnDenom, denom),
		),
	)
	return nil
}

// BurnTokensWithAuthzGrant burns from grantee after consuming a [AuthzKindBurn] grant from granter to grantee.
func (k Keeper) BurnTokensWithAuthzGrant(ctx sdk.Context, grantee, granter sdk.AccAddress, amount math.Int) error {
	goCtx := ctx.Context()
	if err := k.CheckCircuitAllowsOps(goCtx); err != nil {
		return err
	}
	if grantee.Empty() || granter.Empty() {
		return ErrInvalidAmount
	}
	if amount.IsNil() || amount.IsNegative() || amount.IsZero() {
		return ErrInvalidAmount
	}

	bal, err := k.GetBalance(goCtx, grantee)
	if err != nil {
		return err
	}
	if bal.LT(amount) {
		return ErrInsufficientFunds
	}

	if err := k.ConsumeActionAuthz(goCtx, grantee, granter, AuthzKindBurn, ctx.BlockHeight(), amount); err != nil {
		return err
	}

	if err := k.Burn(goCtx, grantee, amount); err != nil {
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
			EventTypeTokenBurned,
			sdk.NewAttribute(AttributeKeyBurnSender, grantee.String()),
			sdk.NewAttribute(AttributeKeyBurnAmount, amount.String()),
			sdk.NewAttribute(AttributeKeySupplyAfterBurn, after.String()),
			sdk.NewAttribute(AttributeKeyBurnDenom, denom),
			sdk.NewAttribute(AttributeKeyBurnGrantee, grantee.String()),
			sdk.NewAttribute(AttributeKeyBurnGranter, granter.String()),
		),
	)
	return nil
}

// BurnTokens is a package-level helper that delegates to [Keeper.BurnTokens].
func BurnTokens(ctx sdk.Context, k Keeper, sender sdk.AccAddress, amount math.Int) error {
	return k.BurnTokens(ctx, sender, amount)
}

// FeeBurn burns burnPercent of feeAmount from payer (0 <= burnPercent <= 100), rounded down.
func FeeBurn(ctx sdk.Context, k Keeper, payer sdk.AccAddress, feeAmount math.Int, burnPercent int64) error {
	goCtx := ctx.Context()
	if err := k.CheckCircuitAllowsOps(goCtx); err != nil {
		return err
	}
	if burnPercent < 0 || burnPercent > 100 {
		return ErrInvalidAmount
	}
	if feeAmount.IsNil() || feeAmount.IsNegative() || feeAmount.IsZero() {
		return nil
	}
	if payer.Empty() {
		return ErrInvalidAmount
	}

	burnAmt := feeAmount.MulRaw(burnPercent).QuoRaw(100)
	if burnAmt.IsZero() {
		return nil
	}

	bal, err := k.GetBalance(goCtx, payer)
	if err != nil {
		return err
	}
	if bal.LT(burnAmt) {
		return ErrInsufficientFunds
	}

	if err := k.Burn(goCtx, payer, burnAmt); err != nil {
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
			EventTypeTokenBurned,
			sdk.NewAttribute(AttributeKeyBurnSender, payer.String()),
			sdk.NewAttribute(AttributeKeyBurnAmount, burnAmt.String()),
			sdk.NewAttribute(AttributeKeySupplyAfterBurn, after.String()),
			sdk.NewAttribute(AttributeKeyFeeBurnReason, FeeBurnReason),
			sdk.NewAttribute(AttributeKeyBurnDenom, denom),
			sdk.NewAttribute("burn_percent", fmt.Sprintf("%d", burnPercent)),
		),
	)
	return nil
}
