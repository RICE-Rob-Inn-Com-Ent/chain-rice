package types

import (
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/msgservice"
)

func RegisterInterfaces(registrar codectypes.InterfaceRegistry) {
	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&MsgTransfer{},
	)

	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&MsgBurn{},
	)

	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&MsgMint{},
	)

	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&MsgCreateToken{},
	)

	registrar.RegisterImplementations((*sdk.Msg)(nil),
		&MsgUpdateParams{},
	)
	msgservice.RegisterMsgServiceDesc(registrar, &_Msg_serviceDesc)
}
