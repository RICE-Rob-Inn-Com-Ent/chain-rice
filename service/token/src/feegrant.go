package token

import (
	"strings"
	"time"

	errorsmod "cosmossdk.io/errors"
	"cosmossdk.io/math"
	feegrant "cosmossdk.io/x/feegrant"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

// FeegrantIntegration documents app wiring: register x/feegrant in the module manager and ante handler
// so [feegrant.Keeper] can pay fees from granter when grantee signs (standard Cosmos SDK v0.53).
type FeegrantIntegration struct{}

// NewMasterPaysAgentFeeGrant builds a [feegrant.BasicAllowance] where the master (granter) caps fee spend for the agent (grantee).
// Submit with [feegrant.MsgGrantAllowance] via the feegrant module; the agent broadcasts txs with fee payer = granter using feegrant ante wiring.
func NewMasterPaysAgentFeeGrant(feeDenom string, spendCap math.Int, expiration *time.Time) (*feegrant.BasicAllowance, error) {
	feeDenom = strings.TrimSpace(feeDenom)
	if err := sdk.ValidateDenom(feeDenom); err != nil {
		return nil, errorsmod.Wrap(err, "fee denom")
	}
	if spendCap.IsNil() || spendCap.IsNegative() || spendCap.IsZero() {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "spend_cap")
	}
	coins := sdk.NewCoins(sdk.NewCoin(feeDenom, spendCap))
	allow := &feegrant.BasicAllowance{
		SpendLimit: coins,
		Expiration: expiration,
	}
	if err := allow.ValidateBasic(); err != nil {
		return nil, err
	}
	return allow, nil
}

// NewMsgGrantFeeAllowanceFromMaster wraps [feegrant.NewMsgGrantAllowance] for master → agent fee delegation.
func NewMsgGrantFeeAllowanceFromMaster(master, agent sdk.AccAddress, feeDenom string, spendCap math.Int, expiration *time.Time) (*feegrant.MsgGrantAllowance, error) {
	if master.Empty() || agent.Empty() {
		return nil, errorsmod.Wrap(sdkerrors.ErrInvalidAddress, "master or agent address")
	}
	allow, err := NewMasterPaysAgentFeeGrant(feeDenom, spendCap, expiration)
	if err != nil {
		return nil, err
	}
	return feegrant.NewMsgGrantAllowance(allow, master, agent)
}

// NewUnlimitedMasterPaysAgentFeeGrant is a basic allowance with no spend cap (only optional expiration).
func NewUnlimitedMasterPaysAgentFeeGrant(expiration *time.Time) (*feegrant.BasicAllowance, error) {
	allow := &feegrant.BasicAllowance{SpendLimit: nil, Expiration: expiration}
	if err := allow.ValidateBasic(); err != nil {
		return nil, err
	}
	return allow, nil
}
