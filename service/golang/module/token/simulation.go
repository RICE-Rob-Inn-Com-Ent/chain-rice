package token

import (
	"math/rand"

	"github.com/cosmos/cosmos-sdk/baseapp"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/types/module"
	simtypes "github.com/cosmos/cosmos-sdk/types/simulation"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/x/simulation"

	"github.com/chainrice/rice/backend/app/token"
)

// TokenGenerateGenesisState creates a randomized GenState of the module.
func (TokenAppModule) TokenGenerateGenesisState(simState *module.SimulationState) {
	accs := make([]string, len(simState.Accounts))
	for i, acc := range simState.Accounts {
		accs[i] = acc.Address.String()
	}
	tokenGenesis := token.GenesisState{
		Params: TokenDefaultParams(),
	}
	simState.GenState[TokenModuleName] = simState.Cdc.MustMarshalJSON(&tokenGenesis)
}

// TokenRegisterStoreDecoder registers a decoder.
func (am TokenAppModule) TokenRegisterStoreDecoder(_ simtypes.StoreDecoderRegistry) {}

// TokenWeightedOperations returns the all the gov module operations with their respective weights.
func (am TokenAppModule) TokenWeightedOperations(simState module.SimulationState) []simtypes.WeightedOperation {
	operations := make([]simtypes.WeightedOperation, 0)
	const (
		opWeightMsgCreateToken          = "op_weight_msg_token"
		defaultWeightMsgCreateToken int = 100
	)

	var weightMsgCreateToken int
	simState.AppParams.GetOrGenerate(opWeightMsgCreateToken, &weightMsgCreateToken, nil,
		func(_ *rand.Rand) {
			weightMsgCreateToken = defaultWeightMsgCreateToken
		},
	)
	operations = append(operations, simulation.NewWeightedOperation(
		weightMsgCreateToken,
		TokenSimulateMsgCreateToken(am.authKeeper, am.bankKeeper, am.keeper, simState.TxConfig),
	))
	const (
		opWeightMsgMint          = "op_weight_msg_token"
		defaultWeightMsgMint int = 100
	)

	var weightMsgMint int
	simState.AppParams.GetOrGenerate(opWeightMsgMint, &weightMsgMint, nil,
		func(_ *rand.Rand) {
			weightMsgMint = defaultWeightMsgMint
		},
	)
	operations = append(operations, simulation.NewWeightedOperation(
		weightMsgMint,
		TokenSimulateMsgMint(am.authKeeper, am.bankKeeper, am.keeper, simState.TxConfig),
	))
	const (
		opWeightMsgBurn          = "op_weight_msg_token"
		defaultWeightMsgBurn int = 100
	)

	var weightMsgBurn int
	simState.AppParams.GetOrGenerate(opWeightMsgBurn, &weightMsgBurn, nil,
		func(_ *rand.Rand) {
			weightMsgBurn = defaultWeightMsgBurn
		},
	)
	operations = append(operations, simulation.NewWeightedOperation(
		weightMsgBurn,
		TokenSimulateMsgBurn(am.authKeeper, am.bankKeeper, am.keeper, simState.TxConfig),
	))
	const (
		opWeightMsgTransfer          = "op_weight_msg_token"
		defaultWeightMsgTransfer int = 100
	)

	var weightMsgTransfer int
	simState.AppParams.GetOrGenerate(opWeightMsgTransfer, &weightMsgTransfer, nil,
		func(_ *rand.Rand) {
			weightMsgTransfer = defaultWeightMsgTransfer
		},
	)
	operations = append(operations, simulation.NewWeightedOperation(
		weightMsgTransfer,
		TokenSimulateMsgTransfer(am.authKeeper, am.bankKeeper, am.keeper, simState.TxConfig),
	))

	return operations
}

// TokenProposalMsgs returns msgs used for governance proposals for simulations.
func (am TokenAppModule) TokenProposalMsgs(simState module.SimulationState) []simtypes.WeightedProposalMsg {
	return []simtypes.WeightedProposalMsg{}
}

// TokenSimulateMsgCreateToken simulates CreateToken message
func TokenSimulateMsgCreateToken(
	ak TokenAuthKeeper,
	bk TokenBankKeeper,
	k TokenKeeper,
	txGen client.TxConfig,
) simtypes.Operation {
	return func(r *rand.Rand, app *baseapp.BaseApp, ctx sdk.Context, accs []simtypes.Account, chainID string,
	) (simtypes.OperationMsg, []simtypes.FutureOperation, error) {
		simAccount, _ := simtypes.RandomAcc(r, accs)
		msg := &token.MsgCreateToken{
			Creator: simAccount.Address.String(),
		}

		// TODO: Implement CreateToken simulation
		// This requires proper Cosmos SDK simulation infrastructure
		return simtypes.NoOpMsg(TokenModuleName, sdk.MsgTypeURL(msg), "CreateToken simulation not implemented"), nil, nil
	}
}

// TokenSimulateMsgMint simulates Mint message
func TokenSimulateMsgMint(
	ak TokenAuthKeeper,
	bk TokenBankKeeper,
	k TokenKeeper,
	txGen client.TxConfig,
) simtypes.Operation {
	return func(r *rand.Rand, app *baseapp.BaseApp, ctx sdk.Context, accs []simtypes.Account, chainID string,
	) (simtypes.OperationMsg, []simtypes.FutureOperation, error) {
		simAccount, _ := simtypes.RandomAcc(r, accs)
		msg := &token.MsgMint{
			Creator: simAccount.Address.String(),
		}

		// TODO: Implement Mint simulation
		// This requires proper Cosmos SDK simulation infrastructure
		return simtypes.NoOpMsg(TokenModuleName, sdk.MsgTypeURL(msg), "Mint simulation not implemented"), nil, nil
	}
}

// TokenSimulateMsgBurn simulates Burn message
func TokenSimulateMsgBurn(
	ak TokenAuthKeeper,
	bk TokenBankKeeper,
	k TokenKeeper,
	txGen client.TxConfig,
) simtypes.Operation {
	return func(r *rand.Rand, app *baseapp.BaseApp, ctx sdk.Context, accs []simtypes.Account, chainID string,
	) (simtypes.OperationMsg, []simtypes.FutureOperation, error) {
		simAccount, _ := simtypes.RandomAcc(r, accs)
		msg := &token.MsgBurn{
			Creator: simAccount.Address.String(),
		}

		// TODO: Implement Burn simulation
		// This requires proper Cosmos SDK simulation infrastructure
		return simtypes.NoOpMsg(TokenModuleName, sdk.MsgTypeURL(msg), "Burn simulation not implemented"), nil, nil
	}
}

// TokenSimulateMsgTransfer simulates Transfer message
func TokenSimulateMsgTransfer(
	ak TokenAuthKeeper,
	bk TokenBankKeeper,
	k TokenKeeper,
	txGen client.TxConfig,
) simtypes.Operation {
	return func(r *rand.Rand, app *baseapp.BaseApp, ctx sdk.Context, accs []simtypes.Account, chainID string,
	) (simtypes.OperationMsg, []simtypes.FutureOperation, error) {
		simAccount, _ := simtypes.RandomAcc(r, accs)
		msg := &token.MsgTransfer{
			Creator: simAccount.Address.String(),
		}

		// TODO: Implement Transfer simulation
		// This requires proper Cosmos SDK simulation infrastructure
		return simtypes.NoOpMsg(TokenModuleName, sdk.MsgTypeURL(msg), "Transfer simulation not implemented"), nil, nil
	}
}
