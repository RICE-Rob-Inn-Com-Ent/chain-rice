package token

import (
	"strings"

	errorsmod "cosmossdk.io/errors"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

// Evidence types for x/token misbehavior (indexer / governance review; not a Comet Evidence payload by default).
const (
	EvidenceTypeTokenDoubleSpendAttempt = "token/double_spend_attempt"
	EvidenceTypeTokenAuthzBypass        = "token/authz_bypass_attempt"
)

// TokenMisbehaviorEvidence is a structured report that a sub-service may have violated token rules.
// Full chains should bridge this into cosmossdk.io/x/evidence with a registered concrete type when wired.
type TokenMisbehaviorEvidence struct {
	EvidenceType string `json:"evidence_type"`
	Reporter     string `json:"reporter"`
	Accused      string `json:"accused"`
	TxHash       string `json:"tx_hash,omitempty"`
	Detail       string `json:"detail,omitempty"`
}

// ValidateTokenMisbehavior performs stateless checks on an evidence report.
func ValidateTokenMisbehavior(e TokenMisbehaviorEvidence) error {
	if e.EvidenceType == "" {
		return errorsmod.Wrap(sdkerrors.ErrInvalidRequest, "evidence_type empty")
	}
	if strings.TrimSpace(e.Reporter) == "" || strings.TrimSpace(e.Accused) == "" {
		return errorsmod.Wrap(sdkerrors.ErrInvalidRequest, "reporter or accused empty")
	}
	if _, err := sdk.AccAddressFromBech32(strings.TrimSpace(e.Reporter)); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "reporter address")
	}
	if _, err := sdk.AccAddressFromBech32(strings.TrimSpace(e.Accused)); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "accused address")
	}
	return nil
}

// HandleTokenMisbehavior is a hook for the app to record or slash after review.
// It returns [ErrUnauthorized] when the evidence type implies an authz bypass was proven on-chain.
func (k Keeper) HandleTokenMisbehavior(ctx sdk.Context, e TokenMisbehaviorEvidence) error {
	if err := ValidateTokenMisbehavior(e); err != nil {
		return err
	}
	switch e.EvidenceType {
	case EvidenceTypeTokenDoubleSpendAttempt:
		ctx.EventManager().EmitEvent(
			sdk.NewEvent(
				EvidenceTypeTokenDoubleSpendAttempt,
				sdk.NewAttribute("reporter", strings.TrimSpace(e.Reporter)),
				sdk.NewAttribute("accused", strings.TrimSpace(e.Accused)),
				sdk.NewAttribute("tx_hash", e.TxHash),
				sdk.NewAttribute("detail", e.Detail),
			),
		)
		return nil
	case EvidenceTypeTokenAuthzBypass:
		ctx.EventManager().EmitEvent(
			sdk.NewEvent(
				EvidenceTypeTokenAuthzBypass,
				sdk.NewAttribute("reporter", strings.TrimSpace(e.Reporter)),
				sdk.NewAttribute("accused", strings.TrimSpace(e.Accused)),
				sdk.NewAttribute("detail", e.Detail),
			),
		)
		return ErrUnauthorized
	default:
		return errorsmod.Wrapf(sdkerrors.ErrInvalidRequest, "unknown evidence_type %q", e.EvidenceType)
	}
}
