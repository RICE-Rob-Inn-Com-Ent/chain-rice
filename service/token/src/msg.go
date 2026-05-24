package token

import (
	"context"
	"strings"

	errorsmod "cosmossdk.io/errors"
	"cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

// BARD / indexer: peer transfer event.
const EventTypeTokenSent = "TokenSent"

// Attribute keys for TokenSent.
const (
	AttributeKeySendFrom   = "from"
	AttributeKeySendTo     = "to"
	AttributeKeySendAmount = "amount"
	AttributeKeySendDenom  = "denom"
)

// --- MsgCreateToken (reserved; not executed on-chain until wired via gov) ---

// MsgCreateToken initializes token metadata and mints an initial supply to the authority account.
//
// proto: smith.token.v1.MsgCreateToken
type MsgCreateToken struct {
	Authority     string `protobuf:"bytes,1,opt,name=authority,proto3" json:"authority,omitempty"`
	Denom         string `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
	InitialSupply string `protobuf:"bytes,3,opt,name=initial_supply,json=initialSupply,proto3" json:"initial_supply,omitempty"`
}

func (m *MsgCreateToken) Reset() { *m = MsgCreateToken{} }
func (m *MsgCreateToken) String() string {
	return "create_token:" + m.Authority
}
func (*MsgCreateToken) ProtoMessage() {}

func (MsgCreateToken) Route() string { return RouterKey }
func (MsgCreateToken) Type() string  { return "create_token" }

func (msg MsgCreateToken) ValidateBasic() error {
	if strings.TrimSpace(msg.Authority) == "" {
		return errorsmod.Wrap(ErrInvalidAmount, "authority empty")
	}
	if _, err := sdk.AccAddressFromBech32(msg.Authority); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "authority address")
	}
	if err := sdk.ValidateDenom(msg.Denom); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "denom")
	}
	if _, err := parseNonNegativeAmount(msg.InitialSupply); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "initial_supply")
	}
	return nil
}

func (msg *MsgCreateToken) GetSigners() []sdk.AccAddress {
	addr, err := sdk.AccAddressFromBech32(msg.Authority)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{addr}
}

// --- MsgSend (grpc-gateway: POST body for MsgSend) ---

// MsgSend moves amount from FromAddress to ToAddress.
//
// proto: smith.token.v1.MsgSend
// grpc-gateway: MsgSend
type MsgSend struct {
	FromAddress string `protobuf:"bytes,1,opt,name=from_address,json=fromAddress,proto3" json:"from_address,omitempty"`
	ToAddress   string `protobuf:"bytes,2,opt,name=to_address,json=toAddress,proto3" json:"to_address,omitempty"`
	Amount      string `protobuf:"bytes,3,opt,name=amount,proto3" json:"amount,omitempty"`
}

func (m *MsgSend) Reset()         { *m = MsgSend{} }
func (m *MsgSend) String() string { return "send:" + m.FromAddress + "->" + m.ToAddress }
func (*MsgSend) ProtoMessage()    {}

func (MsgSend) Route() string { return RouterKey }
func (MsgSend) Type() string  { return "send" }

func (msg MsgSend) ValidateBasic() error {
	if strings.TrimSpace(msg.FromAddress) == "" {
		return errorsmod.Wrap(ErrInvalidAmount, "from_address empty")
	}
	if strings.TrimSpace(msg.ToAddress) == "" {
		return errorsmod.Wrap(ErrInvalidAmount, "to_address empty")
	}
	from, err := sdk.AccAddressFromBech32(msg.FromAddress)
	if err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "from_address")
	}
	to, err := sdk.AccAddressFromBech32(msg.ToAddress)
	if err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "to_address")
	}
	if from.Equals(to) {
		return errorsmod.Wrap(ErrInvalidAmount, "from equals to")
	}
	if _, err := parsePositiveAmount(msg.Amount); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "amount")
	}
	return nil
}

func (msg *MsgSend) GetSigners() []sdk.AccAddress {
	addr, err := sdk.AccAddressFromBech32(msg.FromAddress)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{addr}
}

// MsgSendResponse is returned after a successful [MsgSend] (protobuf-shaped for BARD).
type MsgSendResponse struct {
	Amount string `protobuf:"bytes,1,opt,name=amount,proto3" json:"amount,omitempty"`
	Denom  string `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
}

func (m *MsgSendResponse) Reset()         { *m = MsgSendResponse{} }
func (m *MsgSendResponse) String() string { return m.Amount + "/" + m.Denom }
func (*MsgSendResponse) ProtoMessage()    {}

// --- MsgMint ---

// MsgMint credits recipient from the module supply when signed by [Keeper.Authority] (e.g. gov module account).
//
// proto: smith.token.v1.MsgMint
type MsgMint struct {
	Authority string `protobuf:"bytes,1,opt,name=authority,proto3" json:"authority,omitempty"`
	Recipient string `protobuf:"bytes,2,opt,name=recipient,proto3" json:"recipient,omitempty"`
	Amount    string `protobuf:"bytes,3,opt,name=amount,proto3" json:"amount,omitempty"`
}

func (m *MsgMint) Reset()         { *m = MsgMint{} }
func (m *MsgMint) String() string { return "mint:" + m.Recipient }
func (*MsgMint) ProtoMessage()    {}

func (MsgMint) Route() string { return RouterKey }
func (MsgMint) Type() string  { return "mint" }

func (msg MsgMint) ValidateBasic() error {
	if strings.TrimSpace(msg.Authority) == "" {
		return errorsmod.Wrap(ErrInvalidAmount, "authority empty")
	}
	if strings.TrimSpace(msg.Recipient) == "" {
		return errorsmod.Wrap(ErrInvalidAmount, "recipient empty")
	}
	if _, err := sdk.AccAddressFromBech32(msg.Authority); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "authority")
	}
	if _, err := sdk.AccAddressFromBech32(msg.Recipient); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "recipient")
	}
	if _, err := parsePositiveAmount(msg.Amount); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "amount")
	}
	return nil
}

func (msg *MsgMint) GetSigners() []sdk.AccAddress {
	addr, err := sdk.AccAddressFromBech32(msg.Authority)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{addr}
}

// MsgMintResponse carries post-mint supply for UI/audio feedback.
type MsgMintResponse struct {
	Amount      string `protobuf:"bytes,1,opt,name=amount,proto3" json:"amount,omitempty"`
	SupplyAfter string `protobuf:"bytes,2,opt,name=supply_after,json=supplyAfter,proto3" json:"supply_after,omitempty"`
	Denom       string `protobuf:"bytes,3,opt,name=denom,proto3" json:"denom,omitempty"`
	Recipient   string `protobuf:"bytes,4,opt,name=recipient,proto3" json:"recipient,omitempty"`
}

func (m *MsgMintResponse) Reset()         { *m = MsgMintResponse{} }
func (m *MsgMintResponse) String() string { return m.SupplyAfter }
func (*MsgMintResponse) ProtoMessage()    {}

// --- MsgBurn ---

// MsgBurn burns amount from the signer's balance.
//
// proto: smith.token.v1.MsgBurn
type MsgBurn struct {
	FromAddress string `protobuf:"bytes,1,opt,name=from_address,json=fromAddress,proto3" json:"from_address,omitempty"`
	Amount      string `protobuf:"bytes,2,opt,name=amount,proto3" json:"amount,omitempty"`
}

func (m *MsgBurn) Reset()         { *m = MsgBurn{} }
func (m *MsgBurn) String() string { return "burn:" + m.FromAddress }
func (*MsgBurn) ProtoMessage()    {}

func (MsgBurn) Route() string { return RouterKey }
func (MsgBurn) Type() string  { return "burn" }

func (msg MsgBurn) ValidateBasic() error {
	if strings.TrimSpace(msg.FromAddress) == "" {
		return errorsmod.Wrap(ErrInvalidAmount, "from_address empty")
	}
	if _, err := sdk.AccAddressFromBech32(msg.FromAddress); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "from_address")
	}
	if _, err := parsePositiveAmount(msg.Amount); err != nil {
		return errorsmod.Wrap(ErrInvalidAmount, "amount")
	}
	return nil
}

func (msg *MsgBurn) GetSigners() []sdk.AccAddress {
	addr, err := sdk.AccAddressFromBech32(msg.FromAddress)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{addr}
}

// MsgBurnResponse is returned after [MsgBurn].
type MsgBurnResponse struct {
	Amount      string `protobuf:"bytes,1,opt,name=amount,proto3" json:"amount,omitempty"`
	SupplyAfter string `protobuf:"bytes,2,opt,name=supply_after,json=supplyAfter,proto3" json:"supply_after,omitempty"`
	Denom       string `protobuf:"bytes,3,opt,name=denom,proto3" json:"denom,omitempty"`
}

func (m *MsgBurnResponse) Reset()         { *m = MsgBurnResponse{} }
func (m *MsgBurnResponse) String() string { return m.SupplyAfter }
func (*MsgBurnResponse) ProtoMessage()    {}

func parseNonNegativeAmount(s string) (math.Int, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return math.Int{}, errorsmod.Wrap(ErrInvalidAmount, "empty amount string")
	}
	i, ok := math.NewIntFromString(s)
	if !ok {
		return math.Int{}, errorsmod.Wrap(ErrInvalidAmount, "parse int")
	}
	if i.IsNegative() {
		return math.Int{}, errorsmod.Wrap(ErrInvalidAmount, "negative")
	}
	return i, nil
}

func parsePositiveAmount(s string) (math.Int, error) {
	i, err := parseNonNegativeAmount(s)
	if err != nil {
		return math.Int{}, err
	}
	if !i.IsPositive() {
		return math.Int{}, errorsmod.Wrap(ErrInvalidAmount, "must be positive")
	}
	return i, nil
}

// MsgServer is the x/token transaction gRPC service surface (hand-rolled until protos are generated).
type MsgServer interface {
	Send(context.Context, *MsgSend) (*MsgSendResponse, error)
	Mint(context.Context, *MsgMint) (*MsgMintResponse, error)
	Burn(context.Context, *MsgBurn) (*MsgBurnResponse, error)
}

type msgServer struct {
	keeper Keeper
}

// NewMsgServer constructs the [MsgServer] implementation.
func NewMsgServer(k Keeper) MsgServer {
	return msgServer{keeper: k}
}

func (m msgServer) Send(ctx context.Context, msg *MsgSend) (*MsgSendResponse, error) {
	if msg == nil {
		return nil, errorsmod.Wrap(sdkerrors.ErrInvalidRequest, "nil msg")
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	from, err := sdk.AccAddressFromBech32(strings.TrimSpace(msg.FromAddress))
	if err != nil {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "from_address")
	}
	to, err := sdk.AccAddressFromBech32(strings.TrimSpace(msg.ToAddress))
	if err != nil {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "to_address")
	}
	amt, err := parsePositiveAmount(msg.Amount)
	if err != nil {
		return nil, err
	}
	goCtx := sdkCtx.Context()
	if err := m.keeper.Send(goCtx, from, to, amt); err != nil {
		return nil, err
	}
	denom, err := m.keeper.PrimaryMintDenom(goCtx)
	if err != nil {
		return nil, err
	}
	sdkCtx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeTokenSent,
			sdk.NewAttribute(AttributeKeySendFrom, from.String()),
			sdk.NewAttribute(AttributeKeySendTo, to.String()),
			sdk.NewAttribute(AttributeKeySendAmount, amt.String()),
			sdk.NewAttribute(AttributeKeySendDenom, denom),
		),
	)
	return &MsgSendResponse{Amount: amt.String(), Denom: denom}, nil
}

func (m msgServer) Mint(ctx context.Context, msg *MsgMint) (*MsgMintResponse, error) {
	if msg == nil {
		return nil, errorsmod.Wrap(sdkerrors.ErrInvalidRequest, "nil msg")
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	signers := msg.GetSigners()
	if len(signers) != 1 || m.keeper.Authority.Empty() || !signers[0].Equals(m.keeper.Authority) {
		return nil, ErrUnauthorized
	}
	recipient, err := sdk.AccAddressFromBech32(strings.TrimSpace(msg.Recipient))
	if err != nil {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "recipient")
	}
	amt, err := parsePositiveAmount(msg.Amount)
	if err != nil {
		return nil, err
	}
	if !amt.IsUint64() {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "amount must fit uint64 for event indexing")
	}
	goCtx := sdkCtx.Context()
	params, err := m.keeper.GetParams(goCtx)
	if err != nil {
		return nil, err
	}
	if !params.MintingEnabled {
		return nil, ErrTokenLocked
	}
	sup, err := m.keeper.TotalSupply(goCtx)
	if err != nil {
		return nil, err
	}
	next, err := Add(sup, amt)
	if err != nil {
		return nil, err
	}
	if next.GT(params.MaxSupply) {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "exceeds max_supply")
	}
	if err := m.keeper.Mint(goCtx, recipient, amt); err != nil {
		return nil, err
	}
	after, err := m.keeper.TotalSupply(goCtx)
	if err != nil {
		return nil, err
	}
	denom, err := m.keeper.PrimaryMintDenom(goCtx)
	if err != nil {
		return nil, err
	}
	sdkCtx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeTokenMinted,
			sdk.NewAttribute(AttributeKeyMintRecipient, recipient.String()),
			sdk.NewAttribute(AttributeKeyMintAmount, amt.String()),
			sdk.NewAttribute(AttributeKeyMinterModule, ModuleName),
			sdk.NewAttribute(AttributeKeySupplyAfterMint, after.String()),
			sdk.NewAttribute(AttributeKeyMintDenom, denom),
		),
	)
	return &MsgMintResponse{
		Amount:      amt.String(),
		SupplyAfter: after.String(),
		Denom:       denom,
		Recipient:   recipient.String(),
	}, nil
}

func (m msgServer) Burn(ctx context.Context, msg *MsgBurn) (*MsgBurnResponse, error) {
	if msg == nil {
		return nil, errorsmod.Wrap(sdkerrors.ErrInvalidRequest, "nil msg")
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	sender, err := sdk.AccAddressFromBech32(strings.TrimSpace(msg.FromAddress))
	if err != nil {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "from_address")
	}
	amt, err := parsePositiveAmount(msg.Amount)
	if err != nil {
		return nil, err
	}
	if err := m.keeper.BurnTokens(sdkCtx, sender, amt); err != nil {
		return nil, err
	}
	after, err := m.keeper.TotalSupply(sdkCtx.Context())
	if err != nil {
		return nil, err
	}
	denom, err := m.keeper.PrimaryMintDenom(sdkCtx.Context())
	if err != nil {
		return nil, err
	}
	return &MsgBurnResponse{
		Amount:      amt.String(),
		SupplyAfter: after.String(),
		Denom:       denom,
	}, nil
}

// DispatchTokenMsg routes a legacy [sdk.Msg] to the appropriate [MsgServer] handler.
// Use this until generated gRPC [module.Configurator.RegisterService] wiring is available.
func DispatchTokenMsg(ctx sdk.Context, k Keeper, msg sdk.Msg) error {
	srv := NewMsgServer(k)
	wrapped := sdk.WrapSDKContext(ctx)
	switch t := msg.(type) {
	case *MsgSend:
		_, err := srv.Send(wrapped, t)
		return err
	case *MsgMint:
		_, err := srv.Mint(wrapped, t)
		return err
	case *MsgBurn:
		_, err := srv.Burn(wrapped, t)
		return err
	case *MsgCreateToken:
		return errorsmod.Wrap(sdkerrors.ErrNotFound, "msg_create_token not implemented; use params + MsgMint via gov")
	default:
		return errorsmod.Wrapf(sdkerrors.ErrInvalidType, "%T", msg)
	}
}

var (
	_ sdk.Msg = (*MsgCreateToken)(nil)
	_ sdk.Msg = (*MsgSend)(nil)
	_ sdk.Msg = (*MsgMint)(nil)
	_ sdk.Msg = (*MsgBurn)(nil)

	_ sdk.LegacyMsg = (*MsgCreateToken)(nil)
	_ sdk.LegacyMsg = (*MsgSend)(nil)
	_ sdk.LegacyMsg = (*MsgMint)(nil)
	_ sdk.LegacyMsg = (*MsgBurn)(nil)
)
