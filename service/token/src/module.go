package token

import (
	"context"
	"encoding/json"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/cosmos/cosmos-sdk/types/module"
	gwruntime "github.com/grpc-ecosystem/grpc-gateway/runtime"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

var (
	_ module.HasServices = Module{}
)

// Module is the internal engine for [TokenAppModule] (RegisterServices, genesis helpers).
type Module struct {
	keeper Keeper
}

// NewModule creates the module wrapper.
func NewModule(k Keeper) Module {
	return Module{keeper: k}
}

// Name returns the module name for the module manager.
func (Module) Name() string { return ModuleName }

// RegisterGRPCGatewayRoutes registers REST/gRPC-gateway routes once proto + RegisterQueryHandlerClient are generated.
func (Module) RegisterGRPCGatewayRoutes(_ context.Context, _ *gwruntime.ServeMux, _ string) error {
	return nil
}

// RegisterServices registers store migrations and prepares gRPC registration.
// Full [module.Configurator.RegisterService] paths require protobuf FileDescriptors in the interface registry;
// query/msg services can also be registered via [module.Configurator.QueryServer]/MsgServer().RegisterService
// once codegen is available. Until then use [DispatchTokenMsg] for txs.
func (m Module) RegisterServices(cfg module.Configurator) {
	if err := RegisterTokenStoreMigrations(cfg); err != nil {
		panic(err)
	}
	_ = m.keeper
}

// InitGenesis initializes module state from genesis.
func (m Module) InitGenesis(ctx sdk.Context, data []byte) {
	if err := InitGenesis(ctx, m.keeper, json.RawMessage(data)); err != nil {
		panic(err)
	}
}

// ExportGenesis exports module state.
func (m Module) ExportGenesis(ctx sdk.Context) []byte {
	raw, err := ExportGenesis(ctx, m.keeper)
	if err != nil {
		panic(err)
	}
	return raw
}

// RegisterGRPCServices registers gRPC services on the app (alternative path for some SDK versions).
func (m Module) RegisterGRPCServices(reg kit.ServiceRegistrar) {
	_ = reg
	_ = m
}
