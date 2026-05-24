package token

import (
	"context"
	"encoding/json"
	"strings"

	errorsmod "cosmossdk.io/errors"
	"cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
)

// ICS-20 packet type URL prefix used by ibc-go transfer (reference for app wiring).
const FungibleTokenPacketType = "transfer"

// BARD / indexer: IBC lifecycle events (atomic with keeper mutations).
const (
	EventTypeIBCTokenEscrowed = "IBCTokenEscrowed"
	EventTypeIBCTokenRefunded = "IBCTokenRefunded"
	EventTypeIBCTokenReceived = "IBCTokenReceived"
)

// FungibleTokenPacketData is the JSON payload for ICS-20 (app/ibc-go marshals this into the packet).
// See: https://github.com/cosmos/ibc/tree/main/spec/app/ics-020-fungible-token-transfer
type FungibleTokenPacketData struct {
	Denom    string `json:"denom"`
	Amount   string `json:"amount"`
	Sender   string `json:"sender"`
	Receiver string `json:"receiver"`
	Memo     string `json:"memo,omitempty"`
}

// IBCEscrowModuleName is the sub-module account name holding escrowed native tokens for in-flight transfers.
const IBCEscrowModuleName = ModuleName + "_ics20_escrow"

// IBCEscrowAccountAddress returns the deterministic module account that holds escrowed native supply.
func IBCEscrowAccountAddress() sdk.AccAddress {
	return authtypes.NewModuleAddress(IBCEscrowModuleName)
}

// ParseFungibleTokenPacket unmarshals ICS-20 packet bytes (JSON) into [FungibleTokenPacketData].
func ParseFungibleTokenPacket(packetData []byte) (FungibleTokenPacketData, error) {
	var p FungibleTokenPacketData
	if err := json.Unmarshal(packetData, &p); err != nil {
		return FungibleTokenPacketData{}, errorsmod.Wrap(err, "ics20 packet json")
	}
	return p, nil
}

// ValidateIBCPacketData performs stateless checks on ICS-20 fields.
func ValidateIBCPacketData(p FungibleTokenPacketData) error {
	if err := sdk.ValidateDenom(strings.TrimSpace(p.Denom)); err != nil {
		return errorsmod.Wrap(err, "denom")
	}
	if _, err := parsePositiveAmount(p.Amount); err != nil {
		return errorsmod.Wrap(err, "amount")
	}
	if strings.TrimSpace(p.Sender) == "" || strings.TrimSpace(p.Receiver) == "" {
		return errorsmod.Wrap(sdkerrors.ErrInvalidAddress, "sender or receiver empty")
	}
	return nil
}

// IBCTransferOutEscrow escrows native tokens on the source chain: sender → ICS escrow (supply unchanged).
// Call from a transfer stack / relayer after verifying channel capability (ibc-go hooks).
func (k Keeper) IBCTransferOutEscrow(ctx context.Context, sdkCtx sdk.Context, sender sdk.AccAddress, packet FungibleTokenPacketData) error {
	if err := ValidateIBCPacketData(packet); err != nil {
		return err
	}
	denom, err := k.PrimaryMintDenom(ctx)
	if err != nil {
		return err
	}
	if strings.TrimSpace(packet.Denom) != denom {
		return errorsmod.Wrapf(sdkerrors.ErrInvalidRequest, "ics20 denom %q must match native mint denom %q", packet.Denom, denom)
	}
	amt, ok := math.NewIntFromString(strings.TrimSpace(packet.Amount))
	if !ok || amt.IsNil() || !amt.IsPositive() {
		return errorsmod.Wrap(ErrInvalidAmount, "amount")
	}
	escrow := IBCEscrowAccountAddress()
	if err := k.Send(ctx, sender, escrow, amt); err != nil {
		return err
	}
	sdkCtx.EventManager().EmitEvent(sdk.NewEvent(
		EventTypeIBCTokenEscrowed,
		sdk.NewAttribute("sender", sender.String()),
		sdk.NewAttribute("escrow", escrow.String()),
		sdk.NewAttribute("amount", amt.String()),
		sdk.NewAttribute("denom", denom),
		sdk.NewAttribute("ics20_receiver", strings.TrimSpace(packet.Receiver)),
	))
	return nil
}

// IBCTransferTimeoutRefund returns escrowed tokens to the refund address (typically original sender on source).
func (k Keeper) IBCTransferTimeoutRefund(ctx context.Context, sdkCtx sdk.Context, refundTo sdk.AccAddress, packet FungibleTokenPacketData) error {
	if err := ValidateIBCPacketData(packet); err != nil {
		return err
	}
	amt, ok := math.NewIntFromString(strings.TrimSpace(packet.Amount))
	if !ok || amt.IsNil() || !amt.IsPositive() {
		return errorsmod.Wrap(ErrInvalidAmount, "amount")
	}
	escrow := IBCEscrowAccountAddress()
	if err := k.Send(ctx, escrow, refundTo, amt); err != nil {
		return err
	}
	sdkCtx.EventManager().EmitEvent(sdk.NewEvent(
		EventTypeIBCTokenRefunded,
		sdk.NewAttribute("refund_to", refundTo.String()),
		sdk.NewAttribute("amount", amt.String()),
		sdk.NewAttribute("denom", strings.TrimSpace(packet.Denom)),
	))
	return nil
}

// IBCTransferRecvMint mints vouchers to the receiver on the sink chain (denom must match this chain’s native mint denom).
// For full voucher denom hashing (ibc/…), extend state or compose with x/bank + ibc-go transfer keeper.
func (k Keeper) IBCTransferRecvMint(ctx context.Context, sdkCtx sdk.Context, receiver sdk.AccAddress, packet FungibleTokenPacketData) error {
	if err := ValidateIBCPacketData(packet); err != nil {
		return err
	}
	denom, err := k.PrimaryMintDenom(ctx)
	if err != nil {
		return err
	}
	if strings.TrimSpace(packet.Denom) != denom {
		return errorsmod.Wrapf(sdkerrors.ErrInvalidRequest, "recv mint denom %q must match native %q for this helper", packet.Denom, denom)
	}
	amt, ok := math.NewIntFromString(strings.TrimSpace(packet.Amount))
	if !ok || amt.IsNil() || !amt.IsPositive() {
		return errorsmod.Wrap(ErrInvalidAmount, "amount")
	}
	if err := k.Mint(ctx, receiver, amt); err != nil {
		return err
	}
	sdkCtx.EventManager().EmitEvent(sdk.NewEvent(
		EventTypeIBCTokenReceived,
		sdk.NewAttribute("receiver", receiver.String()),
		sdk.NewAttribute("amount", amt.String()),
		sdk.NewAttribute("denom", denom),
		sdk.NewAttribute("ics20_sender", strings.TrimSpace(packet.Sender)),
	))
	return nil
}
