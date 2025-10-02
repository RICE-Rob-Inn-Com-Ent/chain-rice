package tokens

import (
	"encoding/json"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/spf13/cobra"

	"github.com/rice-dev/backend/blockchain/x/tokens/keeper"
	"github.com/rice-dev/backend/blockchain/x/tokens/types"
)

// AppModuleBasic defines the basic application module used by the tokens module.
type AppModuleBasic struct {
	cdc codec.Codec
}

// Name returns the tokens module's name.
func (AppModuleBasic) Name() string {
	return types.ModuleName
}

// RegisterLegacyAminoCodec registers the tokens module's types on the given LegacyAmino codec.
func (AppModuleBasic) RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	// TODO: Register types when protobuf is properly set up
}

// RegisterInterfaces registers the module's interface types
func (a AppModuleBasic) RegisterInterfaces(reg codectypes.InterfaceRegistry) {
	// TODO: Register interfaces when protobuf is properly set up
}

// DefaultGenesis returns default genesis state as raw bytes for the tokens
// module.
func (AppModuleBasic) DefaultGenesis(cdc codec.JSONCodec) json.RawMessage {
	genesis := types.DefaultGenesis()
	// Use JSON marshaling instead of protobuf
	data, err := json.Marshal(genesis)
	if err != nil {
		panic(err)
	}
	return data
}

// ValidateGenesis performs genesis state validation for the tokens module.
func (AppModuleBasic) ValidateGenesis(cdc codec.JSONCodec, config client.TxEncodingConfig, bz json.RawMessage) error {
	var genState types.GenesisState
	if err := json.Unmarshal(bz, &genState); err != nil {
		return err
	}
	return genState.Validate()
}

// RegisterGRPCGatewayRoutes registers the gRPC Gateway routes for the tokens module.
func (AppModuleBasic) RegisterGRPCGatewayRoutes(clientCtx client.Context, mux *runtime.ServeMux) {
	// TODO: Register gRPC gateway routes
}

// GetTxCmd returns no root tx command for the tokens module.
func (a AppModuleBasic) GetTxCmd() *cobra.Command {
	// TODO: Return tx command when messages are properly set up
	return nil
}

// GetQueryCmd returns the root query command for the tokens module.
func (AppModuleBasic) GetQueryCmd() *cobra.Command {
	// TODO: Return query command when queries are properly set up
	return nil
}

// AppModule implements an application module for the tokens module.
type AppModule struct {
	AppModuleBasic

	keeper         keeper.Keeper
	legacySubspace types.Params
}

// NewAppModule creates a new AppModule object
func NewAppModule(cdc codec.Codec, keeper keeper.Keeper, legacySubspace types.Params) AppModule {
	return AppModule{
		AppModuleBasic: AppModuleBasic{cdc: cdc},
		keeper:         keeper,
		legacySubspace: legacySubspace,
	}
}

// Name returns the tokens module's name.
func (am AppModule) Name() string {
	return am.AppModuleBasic.Name()
}

// RegisterServices registers a gRPC query service to respond to the
// module-specific gRPC queries.
func (am AppModule) RegisterServices(cfg interface{}) {
	// TODO: Register services when gRPC is properly set up
}

// InitGenesis performs genesis initialization for the tokens module.
func (am AppModule) InitGenesis(ctx sdk.Context, cdc codec.JSONCodec, gs json.RawMessage) []interface{} {
	var genState types.GenesisState
	if err := json.Unmarshal(gs, &genState); err != nil {
		panic(err)
	}

	keeper.InitGenesis(ctx, am.keeper, genState)

	return []interface{}{}
}

// ExportGenesis returns the exported genesis state as raw bytes for the tokens
// module.
func (am AppModule) ExportGenesis(ctx sdk.Context, cdc codec.JSONCodec) json.RawMessage {
	genState := keeper.ExportGenesis(ctx, am.keeper)
	data, err := json.Marshal(genState)
	if err != nil {
		panic(err)
	}
	return data
}

// ConsensusVersion implements AppModule/ConsensusVersion.
func (AppModule) ConsensusVersion() uint64 { return 1 }

// IsAppModule implements AppModule/IsAppModule.
func (AppModule) IsAppModule() {}

// BeginBlock returns the begin blocker for the tokens module.
func (am AppModule) BeginBlock(ctx sdk.Context, _ interface{}) {
	// TODO: Implement begin block logic
}

// EndBlock returns the end blocker for the tokens module.
func (am AppModule) EndBlock(ctx sdk.Context, _ interface{}) []interface{} {
	// TODO: Implement end block logic
	return []interface{}{}
}
