package token

import (
	"context"
	"encoding/json"

	"cosmossdk.io/core/appmodule"
	"github.com/RICE-Rob-Inn-Com-Ent/rice/service/token/internal/riceapp"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	gwruntime "github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/spf13/cobra"
)

// TokenAppModule adapts [Module] + [Keeper] for [runtime.App.RegisterModules].
type TokenAppModule struct {
	keeper Keeper
}

// NewTokenAppModule returns an [module.AppModule] for x/token.
func NewTokenAppModule(k Keeper) TokenAppModule {
	return TokenAppModule{keeper: k}
}

var (
	_ module.AppModule           = TokenAppModule{}
	_ module.AppModuleBasic      = TokenAppModule{}
	_ module.HasConsensusVersion = TokenAppModule{}
	_ module.HasGenesis          = TokenAppModule{}
	_ module.HasServices         = TokenAppModule{}
	_ appmodule.AppModule        = TokenAppModule{}
	_ appmodule.HasBeginBlocker  = TokenAppModule{}
	_ appmodule.HasEndBlocker    = TokenAppModule{}
)

func (TokenAppModule) IsAppModule() {}

func (TokenAppModule) IsOnePerModuleType() {}

func (TokenAppModule) Name() string { return riceapp.TokenModuleName }

// ConsensusVersion implements [module.HasConsensusVersion].
func (TokenAppModule) ConsensusVersion() uint64 { return ConsensusVersion }

// BeginBlock implements [appmodule.HasBeginBlocker].
func (TokenAppModule) BeginBlock(context.Context) error { return nil }

// EndBlock implements [appmodule.HasEndBlocker].
func (TokenAppModule) EndBlock(context.Context) error { return nil }

func (TokenAppModule) RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	RegisterLegacyAminoCodec(cdc)
}

func (TokenAppModule) RegisterInterfaces(registry codectypes.InterfaceRegistry) {
	RegisterInterfaces(registry)
}

func (TokenAppModule) RegisterGRPCGatewayRoutes(client.Context, *gwruntime.ServeMux) {}

func (m TokenAppModule) RegisterServices(cfg module.Configurator) {
	NewModule(m.keeper).RegisterServices(cfg)
}

// GetTxCmd implements the optional CLI extension discovered by [module.BasicManager.AddTxCommands].
func (TokenAppModule) GetTxCmd() *cobra.Command { return GetTxCmd() }

// GetQueryCmd implements the optional CLI extension discovered by [module.BasicManager.AddQueryCommands].
func (TokenAppModule) GetQueryCmd() *cobra.Command { return GetQueryCmd() }

func (TokenAppModule) DefaultGenesis(_ codec.JSONCodec) json.RawMessage {
	b, err := json.Marshal(DefaultGenesis())
	if err != nil {
		panic(err)
	}
	return b
}

func (TokenAppModule) ValidateGenesis(_ codec.JSONCodec, _ client.TxEncodingConfig, data json.RawMessage) error {
	var gs GenesisState
	if err := json.Unmarshal(data, &gs); err != nil {
		return err
	}
	return ValidateGenesis(gs)
}

func (m TokenAppModule) InitGenesis(ctx sdk.Context, _ codec.JSONCodec, data json.RawMessage) {
	NewModule(m.keeper).InitGenesis(ctx, data)
}

func (m TokenAppModule) ExportGenesis(ctx sdk.Context, _ codec.JSONCodec) json.RawMessage {
	return NewModule(m.keeper).ExportGenesis(ctx)
}
