package token

// TODO:
// [ ] implement module state via collections:
//     Params: collections.Item[types.Params]
//     Balances: collections.Map[sdk.AccAddress, math.Int]
//     TotalSupply: collections.Item[math.Int]
//     Allowances: collections.Map[Pair[addr,addr], math.Int]

import (
	"cosmossdk.io/collections"
	"cosmossdk.io/core/store"

	"github.com/cosmos/cosmos-sdk/codec"
)

// State holds cosmossdk.io/collections schema for typed on-chain state (Map, Sequence, IndexedMap).
type State struct {
	Schema collections.Schema
	// Example: Balances collections.Map[sdk.AccAddress, collections.Uint64]
	Seq collections.Sequence
}

// NewState builds collections from KVStoreService + codec (depinject-friendly).
func NewState(storeService store.KVStoreService, cdc codec.BinaryCodec) (State, error) {
	_ = cdc
	sb := collections.NewSchemaBuilder(storeService)
	seq := collections.NewSequence(sb, collections.NewPrefix(0), "token_seq")
	schema, err := sb.Build()
	if err != nil {
		return State{}, err
	}
	return State{Schema: schema, Seq: seq}, nil
}
