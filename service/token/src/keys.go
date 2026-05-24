package token

import (
	"fmt"

	"cosmossdk.io/collections"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	// ModuleName is the canonical x/token module identifier (IBC, queries, router).
	ModuleName = "token"
	// StoreKey is the multistore KV name for this module (argument to NewKVStoreKey).
	StoreKey = ModuleName
	// RouterKey is the legacy SDK message route segment.
	RouterKey = ModuleName
	// QuerierRoute is the legacy querier route prefix for REST/gRPC-gateway wiring.
	QuerierRoute = ModuleName
)

// Collection names for cosmossdk.io/collections (must match [NameRegex]).
const (
	CollectionNameParams      = "Params"
	CollectionNameBalances    = "Balances"
	CollectionNameTotalSupply = "TotalSupply"
	CollectionNameCircuitHalt = "CircuitHalt"
	CollectionNameAuthzGrants = "AuthzGrants"
)

// Collection prefixes for the typed [State] schema (math.Int balances, per-denom supply).
// Chosen 0x10+ so they do not overlap the legacy keeper layout on 0x00 / 0x01 until migration.
const (
	CollectionPrefixParams        byte = 0x10
	CollectionPrefixBalances      byte = 0x11
	CollectionPrefixSupplyByDenom byte = 0x12
	CollectionPrefixCircuitHalt   byte = 0x13
	CollectionPrefixAuthzGrants   byte = 0x14
)

// Legacy KV prefixes used by the current uint64 [Keeper] schema (migrate to [State] over time).
const (
	BalancesPrefix byte = 0x00
	SupplyKey      byte = 0x01
)

// GetBalanceKey returns the legacy byte key for the uint64 balances map (prefix 0x00).
func GetBalanceKey(addr sdk.AccAddress) []byte {
	bz, err := collections.EncodeKeyWithPrefix([]byte{BalancesPrefix}, sdk.AccAddressKey, addr)
	if err != nil {
		panic(fmt.Errorf("token: encode balance key: %w", err))
	}
	return bz
}
