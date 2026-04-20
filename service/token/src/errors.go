package token

import (
	"cosmossdk.io/errors"
)

const Codespace = "token"

// Typed module errors (codespace + code for ABCI / gRPC).
var (
	ErrInvalidAmount = errors.Register(Codespace, 2, "invalid token amount")
	ErrUnauthorized  = errors.Register(Codespace, 3, "unauthorized")
	ErrNotFound      = errors.Register(Codespace, 4, "not found")
)
