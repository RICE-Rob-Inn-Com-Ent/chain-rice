package token

import (
	"github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// RegisterInterfaces registers x/token [sdk.Msg] implementations on the protobuf interface registry.
// Required for correct TypeURL resolution, signing, and inter-module serialization on .rice.
func RegisterInterfaces(registry codectypes.InterfaceRegistry) {
	registry.RegisterImplementations((*sdk.Msg)(nil),
		&MsgSend{},
		&MsgMint{},
		&MsgBurn{},
		&MsgCreateToken{},
	)
}

// RegisterLegacyAminoCodec registers concrete types for amino JSON (legacy wallets / REST).
func RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	cdc.RegisterConcrete(&MsgSend{}, "rice/token/MsgSend", nil)
	cdc.RegisterConcrete(&MsgMint{}, "rice/token/MsgMint", nil)
	cdc.RegisterConcrete(&MsgBurn{}, "rice/token/MsgBurn", nil)
	cdc.RegisterConcrete(&MsgCreateToken{}, "rice/token/MsgCreateToken", nil)
}
