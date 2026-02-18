package token

import (
	"context"
	"encoding/json"
	"fmt"

	autocliv1 "cosmossdk.io/api/cosmos/autocli/v1"
	"cosmossdk.io/core/address"
	"cosmossdk.io/core/appmodule"
	corestore "cosmossdk.io/core/store"
	"cosmossdk.io/depinject"
	"cosmossdk.io/depinject/appconfig"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	cosmosmodule "github.com/cosmos/cosmos-sdk/types/module"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"google.golang.org/grpc"

	"github.com/chainrice/rice/backend/app/token"
)

var (
	_ cosmosmodule.AppModuleBasic = (*TokenAppModule)(nil)
	_ cosmosmodule.AppModule      = (*TokenAppModule)(nil)
	_ cosmosmodule.HasGenesis     = (*TokenAppModule)(nil)

	_ appmodule.AppModule       = (*TokenAppModule)(nil)
	_ appmodule.HasBeginBlocker = (*TokenAppModule)(nil)
	_ appmodule.HasEndBlocker   = (*TokenAppModule)(nil)
)

// TokenAppModule implements the AppModule interface
type TokenAppModule struct {
	cdc        codec.Codec
	keeper     TokenKeeper
	authKeeper TokenAuthKeeper
	bankKeeper TokenBankKeeper
}

// TokenNewAppModule creates a new token app module
func TokenNewAppModule(
	cdc codec.Codec,
	keeper TokenKeeper,
	authKeeper TokenAuthKeeper,
	bankKeeper TokenBankKeeper,
) TokenAppModule {
	return TokenAppModule{
		cdc:        cdc,
		keeper:     keeper,
		authKeeper: authKeeper,
		bankKeeper: bankKeeper,
	}
}

// IsAppModule implements the appmodule.AppModule interface.
func (TokenAppModule) IsAppModule() {}

// Name returns the name of the module as a string.
func (TokenAppModule) Name() string {
	return TokenModuleName
}

// RegisterLegacyAminoCodec registers the amino codec
func (TokenAppModule) RegisterLegacyAminoCodec(*codec.LegacyAmino) {}

// RegisterGRPCGatewayRoutes registers the gRPC Gateway routes for the module.
func (TokenAppModule) RegisterGRPCGatewayRoutes(clientCtx client.Context, mux *runtime.ServeMux) {
	if err := token.RegisterQueryHandlerClient(clientCtx, mux, token.NewQueryClient(clientCtx)); err != nil {
		panic(err)
	}
}

// RegisterInterfaces registers a module's interface types and their concrete implementations as proto.Message.
func (TokenAppModule) RegisterInterfaces(registrar codectypes.InterfaceRegistry) {
	TokenRegisterInterfaces(registrar)
}

// RegisterServices registers a gRPC query service to respond to the module-specific gRPC queries
func (am TokenAppModule) RegisterServices(registrar grpc.ServiceRegistrar) error {
	token.RegisterMsgServer(registrar, TokenNewMsgServerImpl(am.keeper))
	token.RegisterQueryServer(registrar, TokenNewQueryServerImpl(am.keeper))

	return nil
}

// DefaultGenesis returns a default GenesisState for the module, marshalled to json.RawMessage.
func (am TokenAppModule) DefaultGenesis(codec.JSONCodec) json.RawMessage {
	return am.cdc.MustMarshalJSON(token.DefaultGenesis())
}

// ValidateGenesis used to validate the GenesisState, given in its json.RawMessage form.
func (am TokenAppModule) ValidateGenesis(_ codec.JSONCodec, _ client.TxEncodingConfig, bz json.RawMessage) error {
	var genState token.GenesisState
	if err := am.cdc.UnmarshalJSON(bz, &genState); err != nil {
		return fmt.Errorf("failed to unmarshal %s genesis state: %w", TokenModuleName, err)
	}

	return genState.Validate()
}

// InitGenesis performs the module's genesis initialization. It returns no validator updates.
func (am TokenAppModule) InitGenesis(ctx sdk.Context, _ codec.JSONCodec, gs json.RawMessage) {
	var genState token.GenesisState
	// Initialize global index to index in genesis state
	if err := am.cdc.UnmarshalJSON(gs, &genState); err != nil {
		panic(fmt.Errorf("failed to unmarshal %s genesis state: %w", TokenModuleName, err))
	}

	if err := am.keeper.TokenInitGenesis(ctx, &genState); err != nil {
		panic(fmt.Errorf("failed to initialize %s genesis state: %w", TokenModuleName, err))
	}
}

// ExportGenesis returns the module's exported genesis state as raw JSON bytes.
func (am TokenAppModule) ExportGenesis(ctx sdk.Context, _ codec.JSONCodec) json.RawMessage {
	genState, err := am.keeper.TokenExportGenesis(ctx)
	if err != nil {
		panic(fmt.Errorf("failed to export %s genesis state: %w", TokenModuleName, err))
	}

	bz, err := am.cdc.MarshalJSON(genState)
	if err != nil {
		panic(fmt.Errorf("failed to marshal %s genesis state: %w", TokenModuleName, err))
	}

	return bz
}

// ConsensusVersion is a sequence number for state-breaking change of the module.
func (TokenAppModule) ConsensusVersion() uint64 { return 1 }

// BeginBlock contains the logic that is automatically triggered at the beginning of each block.
func (am TokenAppModule) BeginBlock(_ context.Context) error {
	return nil
}

// EndBlock contains the logic that is automatically triggered at the end of each block.
func (am TokenAppModule) EndBlock(_ context.Context) error {
	return nil
}

// TokenAutoCLIOptions implements the autocli.HasAutoCLIConfig interface.
func (am TokenAppModule) TokenAutoCLIOptions() *autocliv1.ModuleOptions {
	return &autocliv1.ModuleOptions{
		Query: &autocliv1.ServiceCommandDescriptor{
			Service: token.Query_serviceDesc.ServiceName,
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
			},
		},
		Tx: &autocliv1.ServiceCommandDescriptor{
			Service:              token.Msg_serviceDesc.ServiceName,
			EnhanceCustomCommand: true,
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
			},
		},
	}
}

var _ depinject.OnePerModuleType = TokenAppModule{}

// IsOnePerModuleType implements the depinject.OnePerModuleType interface.
func (TokenAppModule) IsOnePerModuleType() {}

func init() {
	appconfig.Register(
		&TokenModule{},
		appconfig.Provide(TokenProvideModule),
	)
}

// TokenModule config
type TokenModule struct {
	Authority string
}

// TokenModuleInputs for dependency injection
type TokenModuleInputs struct {
	depinject.In

	Config       *TokenModule
	StoreService corestore.KVStoreService
	Cdc          codec.Codec
	AddressCodec address.Codec

	AuthKeeper TokenAuthKeeper
	BankKeeper TokenBankKeeper
}

// TokenModuleOutputs for dependency injection
type TokenModuleOutputs struct {
	depinject.Out

	TokenKeeper TokenKeeper
	Module      appmodule.AppModule
}

// TokenProvideModule provides the module
func TokenProvideModule(in TokenModuleInputs) TokenModuleOutputs {
	// default to governance authority if not provided
	authority := authtypes.NewModuleAddress(TokenGovModuleName)
	if in.Config.Authority != "" {
		authority = authtypes.NewModuleAddressOrBech32Address(in.Config.Authority)
	}

	k := TokenNewKeeper(
		in.StoreService,
		in.Cdc,
		in.AddressCodec,
		authority,
	)
	m := TokenNewAppModule(in.Cdc, k, in.AuthKeeper, in.BankKeeper)

	return TokenModuleOutputs{TokenKeeper: k, Module: m}
}
