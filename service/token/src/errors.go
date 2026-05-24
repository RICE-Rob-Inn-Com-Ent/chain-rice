package token

import (
	"cosmossdk.io/errors"
)

// Sentinel module errors (codespace = [ModuleName] from keys.go).
// Codes 2–4 are stable for prior clients; new sentinels use 5–6.
var (
	ErrInvalidAmount     = errors.Register(ModuleName, 2, "invalid token amount")
	ErrUnauthorized      = errors.Register(ModuleName, 3, "unauthorized")
	ErrNotFound          = errors.Register(ModuleName, 4, "not found")
	ErrInsufficientFunds = errors.Register(ModuleName, 5, "insufficient funds")
	ErrTokenLocked       = errors.Register(ModuleName, 6, "token operation locked or frozen")
)
