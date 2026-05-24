package token

import (
	"encoding/json"
	"fmt"

	"cosmossdk.io/collections"
	collcodec "cosmossdk.io/collections/codec"
	"cosmossdk.io/math"

	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// ManagedState is the typed collections surface for x/token ([State]); alias for SAGE/CLERK embeddings.
type ManagedState = State

// State is the typed collections surface for x/token (params, balances, per-denom supply).
// Wire these on a shared [collections.SchemaBuilder], then call [collections.SchemaBuilder.Build].
type State struct {
	Params      collections.Item[Params]
	Balances    collections.Map[sdk.AccAddress, math.Int]
	TotalSupply collections.Map[string, math.Int]
	CircuitHalt collections.Item[bool]
	AuthzGrants collections.Map[collections.Triple[sdk.AccAddress, sdk.AccAddress, uint64], AuthzGrant]
}

// NewState registers Params, Balances, and TotalSupply on sb and returns typed handles.
// The [codec.BinaryCodec] is reserved for a future proto-backed [Params] codec; today [ParamsValueCodec] uses JSON.
// Caller must invoke [collections.SchemaBuilder.Build] exactly once after all collections for this store are added.
func NewState(sb *collections.SchemaBuilder, cdc codec.BinaryCodec) State {
	_ = cdc
	params := collections.NewItem(
		sb,
		collections.NewPrefix(int(CollectionPrefixParams)),
		CollectionNameParams,
		ParamsValueCodec(),
	)
	balances := collections.NewMap(
		sb,
		collections.NewPrefix(int(CollectionPrefixBalances)),
		CollectionNameBalances,
		sdk.AccAddressKey,
		sdk.IntValue,
	)
	totalSupply := collections.NewMap(
		sb,
		collections.NewPrefix(int(CollectionPrefixSupplyByDenom)),
		CollectionNameTotalSupply,
		collections.StringKey,
		sdk.IntValue,
	)
	circuit := collections.NewItem(
		sb,
		collections.NewPrefix(int(CollectionPrefixCircuitHalt)),
		CollectionNameCircuitHalt,
		collections.BoolValue,
	)
	authz := collections.NewMap(
		sb,
		collections.NewPrefix(int(CollectionPrefixAuthzGrants)),
		CollectionNameAuthzGrants,
		collections.NamedTripleKeyCodec(
			"grantee", sdk.AccAddressKey,
			"granter", sdk.AccAddressKey,
			"kind", collections.Uint64Key,
		),
		AuthzGrantValueCodec(),
	)
	return State{
		Params:      params,
		Balances:    balances,
		TotalSupply: totalSupply,
		CircuitHalt: circuit,
		AuthzGrants: authz,
	}
}

// ParamsValueCodec is a placeholder [collcodec.ValueCodec] for [Params] using JSON.
// Replace with [codec.CollValue] once Params is generated as protobuf and registered on the app codec.
func ParamsValueCodec() collcodec.ValueCodec[Params] {
	return paramsJSONCodec{}
}

type paramsJSONCodec struct{}

func (paramsJSONCodec) Encode(value Params) ([]byte, error) {
	return json.Marshal(value)
}

func (paramsJSONCodec) Decode(b []byte) (Params, error) {
	var p Params
	if err := json.Unmarshal(b, &p); err != nil {
		return Params{}, err
	}
	return p, nil
}

func (c paramsJSONCodec) EncodeJSON(value Params) ([]byte, error) {
	return c.Encode(value)
}

func (c paramsJSONCodec) DecodeJSON(b []byte) (Params, error) {
	return c.Decode(b)
}

func (paramsJSONCodec) Stringify(value Params) string {
	b, err := json.Marshal(value)
	if err != nil {
		return fmt.Sprintf("token.Params{mint_denom:%q,minting_enabled:%v}", value.MintDenom, value.MintingEnabled)
	}
	return string(b)
}

func (paramsJSONCodec) ValueType() string {
	return "token.Params/json"
}
