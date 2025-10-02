package types

import "context"

// MsgServer defines the server API for the tokens module
type MsgServer interface {
	CreateToken(context.Context, *MsgCreateToken) (*MsgCreateTokenResponse, error)
	UpdateToken(context.Context, *MsgUpdateToken) (*MsgUpdateTokenResponse, error)
	DeleteToken(context.Context, *MsgDeleteToken) (*MsgDeleteTokenResponse, error)
	TransferToken(context.Context, *MsgTransferToken) (*MsgTransferTokenResponse, error)
	ApproveToken(context.Context, *MsgApproveToken) (*MsgApproveTokenResponse, error)
	MintToken(context.Context, *MsgMintToken) (*MsgMintTokenResponse, error)
	BurnToken(context.Context, *MsgBurnToken) (*MsgBurnTokenResponse, error)
	TransferFromToken(context.Context, *MsgTransferFromToken) (*MsgTransferFromTokenResponse, error)
}
