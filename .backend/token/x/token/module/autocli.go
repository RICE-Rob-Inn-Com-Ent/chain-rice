package token

import (
	autocliv1 "cosmossdk.io/api/cosmos/autocli/v1"

	"tokenchain/x/token/types"
)

// AutoCLIOptions implements the autocli.HasAutoCLIConfig interface.
func (am AppModule) AutoCLIOptions() *autocliv1.ModuleOptions {
	return &autocliv1.ModuleOptions{
		Query: &autocliv1.ServiceCommandDescriptor{
			Service: types.Query_serviceDesc.ServiceName,
			RpcCommandOptions: []*autocliv1.RpcCommandOptions{
				{
					RpcMethod: "Params",
					Use:       "params",
					Short:     "Shows the parameters of the module",
				},
				{
					RpcMethod:      "Balance",
					Use:            "balance [address] [denom]",
					Short:          "Query balance",
					PositionalArgs: []*autocliv1.PositionalArgDescriptor{{ProtoField: "address"}, {ProtoField: "denom"}},
				},

				{
					RpcMethod:      "TokenInfo",
					Use:            "token-info [denom]",
					Short:          "Query token-info",
					PositionalArgs: []*autocliv1.PositionalArgDescriptor{{ProtoField: "denom"}},
				},

				{
					RpcMethod:      "ListTokens",
					Use:            "list-tokens ",
					Short:          "Query list-tokens",
					PositionalArgs: []*autocliv1.PositionalArgDescriptor{},
				},

				{
					RpcMethod: "ListToken",
					Use:       "list-token",
					Short:     "List all token",
				},
				{
					RpcMethod:      "GetToken",
					Use:            "get-token [id]",
					Short:          "Gets a token",
					Alias:          []string{"show-token"},
					PositionalArgs: []*autocliv1.PositionalArgDescriptor{{ProtoField: "denom"}},
				},
				// this line is used by ignite scaffolding # autocli/query
			},
		},
		Tx: &autocliv1.ServiceCommandDescriptor{
			Service:              types.Msg_serviceDesc.ServiceName,
			EnhanceCustomCommand: true, // only required if you want to use the custom command
			RpcCommandOptions: []*autocliv1.RpcCommandOptions{
				{
					RpcMethod: "UpdateParams",
					Skip:      true, // skipped because authority gated
				},
				{
					RpcMethod:      "CreateToken",
					Use:            "create-token [name] [symbol] [decimals] [initial-supply] [mintable]",
					Short:          "Send a create-token tx",
					PositionalArgs: []*autocliv1.PositionalArgDescriptor{{ProtoField: "name"}, {ProtoField: "symbol"}, {ProtoField: "decimals"}, {ProtoField: "initial_supply"}, {ProtoField: "mintable"}},
				},
				{
					RpcMethod:      "Mint",
					Use:            "mint [denom] [amount] [recipient]",
					Short:          "Send a mint tx",
					PositionalArgs: []*autocliv1.PositionalArgDescriptor{{ProtoField: "denom"}, {ProtoField: "amount"}, {ProtoField: "recipient"}},
				},
				{
					RpcMethod:      "Burn",
					Use:            "burn [denom] [amount]",
					Short:          "Send a burn tx",
					PositionalArgs: []*autocliv1.PositionalArgDescriptor{{ProtoField: "denom"}, {ProtoField: "amount"}},
				},
				{
					RpcMethod:      "Transfer",
					Use:            "transfer [denom] [amount] [recipient]",
					Short:          "Send a transfer tx",
					PositionalArgs: []*autocliv1.PositionalArgDescriptor{{ProtoField: "denom"}, {ProtoField: "amount"}, {ProtoField: "recipient"}},
				},
				// this line is used by ignite scaffolding # autocli/tx
			},
		},
	}
}
