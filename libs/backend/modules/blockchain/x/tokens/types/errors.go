package types

import (
	sdkerrors "cosmossdk.io/errors"
)

// x/tokens module sentinel errors
var (
	ErrTokenNotFound         = sdkerrors.Register(ModuleName, 1100, "token not found")
	ErrTokenAlreadyExists    = sdkerrors.Register(ModuleName, 1101, "token already exists")
	ErrInsufficientBalance   = sdkerrors.Register(ModuleName, 1102, "insufficient balance")
	ErrInsufficientApproval  = sdkerrors.Register(ModuleName, 1103, "insufficient approval")
	ErrInvalidToken          = sdkerrors.Register(ModuleName, 1104, "invalid token")
	ErrInvalidAmount         = sdkerrors.Register(ModuleName, 1105, "invalid amount")
	ErrUnauthorized          = sdkerrors.Register(ModuleName, 1106, "unauthorized")
)

