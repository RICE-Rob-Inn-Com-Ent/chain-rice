package token

import (
	"context"
	"fmt"

	"cosmossdk.io/collections"
	"cosmossdk.io/core/address"
	corestore "cosmossdk.io/core/store"
	"cosmossdk.io/errors"
	"github.com/cosmos/cosmos-sdk/codec"

	"github.com/chainrice/rice/backend/app/token"
)

// ============================================================================
// Constants and Keys
// ============================================================================

const (
	// TokenModuleName defines the module name
	TokenModuleName = "token"

	// TokenStoreKey defines the primary module store key
	TokenStoreKey = TokenModuleName

	// TokenGovModuleName duplicates the gov module's name to avoid a dependency with x/gov.
	// It should be synced with the gov module's name if it is ever changed.
	// See: https://github.com/cosmos/cosmos-sdk/blob/v0.52.0-beta.2/x/gov/types/keys.go#L9
	TokenGovModuleName = "gov"
)

// TokenParamsKey is the prefix to retrieve all Params
var TokenParamsKey = collections.NewPrefix("p_token")

// TokenKey is the prefix to retrieve all Token
var TokenKey = collections.NewPrefix("token/value/")

// ============================================================================
// Errors
// ============================================================================

// module/token module sentinel errors
var (
	TokenErrInvalidSigner = errors.Register(TokenModuleName, 1100, "expected gov account as only signer for proposal message")
)

// ============================================================================
// Keeper
// ============================================================================

// TokenKeeper manages token state
type TokenKeeper struct {
	storeService corestore.KVStoreService
	cdc          codec.Codec
	addressCodec address.Codec
	// Address capable of executing a MsgUpdateParams message.
	// Typically, this should be the x/gov module account.
	authority []byte

	Schema collections.Schema
	Params collections.Item[token.Params]
	Token  collections.Map[string, token.Token]
}

// TokenNewKeeper creates a new token keeper
func TokenNewKeeper(
	storeService corestore.KVStoreService,
	cdc codec.Codec,
	addressCodec address.Codec,
	authority []byte,
) TokenKeeper {
	if _, err := addressCodec.BytesToString(authority); err != nil {
		panic(fmt.Sprintf("invalid authority address %s: %s", authority, err))
	}

	sb := collections.NewSchemaBuilder(storeService)

	k := TokenKeeper{
		storeService: storeService,
		cdc:          cdc,
		addressCodec: addressCodec,
		authority:    authority,

		Params: collections.NewItem(sb, TokenParamsKey, "params", codec.CollValue[token.Params](cdc)),
		Token:  collections.NewMap(sb, TokenKey, "token", collections.StringKey, codec.CollValue[token.Token](cdc)),
	}

	schema, err := sb.Build()
	if err != nil {
		panic(err)
	}
	k.Schema = schema

	return k
}

// GetAuthority returns the module's authority.
func (k TokenKeeper) GetAuthority() []byte {
	return k.authority
}

// ============================================================================
// Expected Keepers
// ============================================================================

// TokenAuthKeeper defines the expected interface for the Auth module.
type TokenAuthKeeper interface {
	AddressCodec() address.Codec
	GetAccount(context.Context, interface{}) interface{} // only used for simulation
	// Methods imported from account should be defined here
}

// TokenBankKeeper defines the expected interface for the Bank module.
type TokenBankKeeper interface {
	SpendableCoins(context.Context, interface{}) interface{}
	// Methods imported from bank should be defined here
}

// TokenParamSubspace defines the expected Subspace interface for parameters.
type TokenParamSubspace interface {
	Get(context.Context, []byte, interface{})
	Set(context.Context, []byte, interface{})
}

// ============================================================================
// Params
// ============================================================================

// TokenNewParams creates a new Params instance.
func TokenNewParams() token.Params {
	return token.Params{}
}

// TokenDefaultParams returns a default set of parameters.
func TokenDefaultParams() token.Params {
	return TokenNewParams()
}
