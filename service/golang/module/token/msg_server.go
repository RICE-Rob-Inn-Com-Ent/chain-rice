package token

import (
	"bytes"
	"context"
	"errors"

	errorsmod "cosmossdk.io/errors"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/msgservice"

	"github.com/chainrice/rice/backend/app/token"
)

// TokenRegisterInterfaces registers interfaces
func TokenRegisterInterfaces(registrar codectypes.InterfaceRegistry) {
	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&token.MsgTransfer{},
	)

	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&token.MsgBurn{},
	)

	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&token.MsgMint{},
	)

	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&token.MsgCreateToken{},
	)

	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&token.MsgUpdateParams{},
	)
	msgservice.RegisterMsgServiceDesc(registrar, &token.Msg_serviceDesc)
}

type tokenMsgServer struct {
	TokenKeeper
}

// TokenNewMsgServerImpl returns an implementation of the MsgServer interface
func TokenNewMsgServerImpl(keeper TokenKeeper) token.MsgServer {
	return &tokenMsgServer{TokenKeeper: keeper}
}

var _ token.MsgServer = tokenMsgServer{}

// CreateToken handles CreateToken message
func (k tokenMsgServer) CreateToken(ctx context.Context, msg *token.MsgCreateToken) (*token.MsgCreateTokenResponse, error) {
	if _, err := k.addressCodec.StringToBytes(msg.Creator); err != nil {
		return nil, errorsmod.Wrap(err, "invalid creator address")
	}

	// Validate required fields
	if msg.Denom == "" {
		return nil, errorsmod.Wrap(errors.New("denom is required"), "invalid denom")
	}
	if msg.Name == "" {
		return nil, errorsmod.Wrap(errors.New("name is required"), "invalid name")
	}
	if msg.Symbol == "" {
		return nil, errorsmod.Wrap(errors.New("symbol is required"), "invalid symbol")
	}

	// Check if token already exists
	_, err := k.Token.Get(ctx, msg.Denom)
	if err == nil {
		return nil, errorsmod.Wrap(errors.New("token already exists"), "duplicate denom")
	}

	// Create new token
	newToken := token.Token{
		Denom:       msg.Denom,
		Name:        msg.Name,
		Symbol:      msg.Symbol,
		Decimals:    msg.Decimals,
		Description: msg.Description,
		Uri:         msg.Uri,
		UriHash:     msg.UriHash,
	}

	if err := k.Token.Set(ctx, msg.Denom, newToken); err != nil {
		return nil, errorsmod.Wrap(err, "failed to create token")
	}

	return &token.MsgCreateTokenResponse{}, nil
}

// Mint handles Mint message
func (k tokenMsgServer) Mint(ctx context.Context, msg *token.MsgMint) (*token.MsgMintResponse, error) {
	if _, err := k.addressCodec.StringToBytes(msg.Creator); err != nil {
		return nil, errorsmod.Wrap(err, "invalid creator address")
	}

	// Validate token exists
	_, err := k.Token.Get(ctx, msg.Denom)
	if err != nil {
		return nil, errorsmod.Wrap(err, "token not found")
	}

	// Validate amount
	if msg.Amount.Amount.IsZero() || msg.Amount.Amount.IsNegative() {
		return nil, errorsmod.Wrap(errors.New("invalid amount"), "amount must be positive")
	}

	// Validate recipient
	if msg.Recipient != "" {
		if _, err := k.addressCodec.StringToBytes(msg.Recipient); err != nil {
			return nil, errorsmod.Wrap(err, "invalid recipient address")
		}
	}

	// Mint operation would typically interact with bank module
	// For now, we just validate and return success
	// In a full implementation, this would:
	// 1. Check permissions (only creator or authorized minter)
	// 2. Mint tokens to recipient via bank module
	// 3. Emit events

	return &token.MsgMintResponse{}, nil
}

// Burn handles Burn message
func (k tokenMsgServer) Burn(ctx context.Context, msg *token.MsgBurn) (*token.MsgBurnResponse, error) {
	if _, err := k.addressCodec.StringToBytes(msg.Creator); err != nil {
		return nil, errorsmod.Wrap(err, "invalid creator address")
	}

	// Validate token exists
	_, err := k.Token.Get(ctx, msg.Denom)
	if err != nil {
		return nil, errorsmod.Wrap(err, "token not found")
	}

	// Validate amount
	if msg.Amount.Amount.IsZero() || msg.Amount.Amount.IsNegative() {
		return nil, errorsmod.Wrap(errors.New("invalid amount"), "amount must be positive")
	}

	// Validate denom matches
	if msg.Amount.Denom != msg.Denom {
		return nil, errorsmod.Wrap(errors.New("denom mismatch"), "amount denom must match token denom")
	}

	// Burn operation would typically interact with bank module
	// For now, we just validate and return success
	// In a full implementation, this would:
	// 1. Check user has sufficient balance
	// 2. Burn tokens via bank module
	// 3. Emit events

	return &token.MsgBurnResponse{}, nil
}

// Transfer handles Transfer message
func (k tokenMsgServer) Transfer(ctx context.Context, msg *token.MsgTransfer) (*token.MsgTransferResponse, error) {
	if _, err := k.addressCodec.StringToBytes(msg.Creator); err != nil {
		return nil, errorsmod.Wrap(err, "invalid creator address")
	}

	// Validate token exists
	_, err := k.Token.Get(ctx, msg.Denom)
	if err != nil {
		return nil, errorsmod.Wrap(err, "token not found")
	}

	// Validate amount
	if msg.Amount.Amount.IsZero() || msg.Amount.Amount.IsNegative() {
		return nil, errorsmod.Wrap(errors.New("invalid amount"), "amount must be positive")
	}

	// Validate denom matches
	if msg.Amount.Denom != msg.Denom {
		return nil, errorsmod.Wrap(errors.New("denom mismatch"), "amount denom must match token denom")
	}

	// Validate addresses
	if msg.From != "" {
		if _, err := k.addressCodec.StringToBytes(msg.From); err != nil {
			return nil, errorsmod.Wrap(err, "invalid from address")
		}
	}
	if msg.To == "" {
		return nil, errorsmod.Wrap(errors.New("to address is required"), "invalid to address")
	}
	if _, err := k.addressCodec.StringToBytes(msg.To); err != nil {
		return nil, errorsmod.Wrap(err, "invalid to address")
	}

	// Transfer operation would typically interact with bank module
	// For now, we just validate and return success
	// In a full implementation, this would:
	// 1. Check sender has sufficient balance
	// 2. Transfer tokens via bank module
	// 3. Emit events

	return &token.MsgTransferResponse{}, nil
}

// UpdateParams handles UpdateParams message
func (k tokenMsgServer) UpdateParams(ctx context.Context, req *token.MsgUpdateParams) (*token.MsgUpdateParamsResponse, error) {
	authority, err := k.addressCodec.StringToBytes(req.Authority)
	if err != nil {
		return nil, errorsmod.Wrap(err, "invalid authority address")
	}

	if !bytes.Equal(k.GetAuthority(), authority) {
		expectedAuthorityStr, _ := k.addressCodec.BytesToString(k.GetAuthority())
		return nil, errorsmod.Wrapf(TokenErrInvalidSigner, "invalid authority; expected %s, got %s", expectedAuthorityStr, req.Authority)
	}

	if err := req.Params.Validate(); err != nil {
		return nil, err
	}

	if err := k.Params.Set(ctx, *req.Params); err != nil {
		return nil, err
	}

	return &token.MsgUpdateParamsResponse{}, nil
}
