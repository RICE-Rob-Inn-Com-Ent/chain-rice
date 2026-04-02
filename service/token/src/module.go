package token

// TODO:
// [ ] implement AppModule interface:
//     Name() string — module name from RICE_TOKEN_MODULE_NAME
//     RegisterServices(cfg module.Configurator) — registers msg + query servers
//     ConsensusVersion() uint64 — bumped on breaking changes
// [ ] implement module depinject:
//     ProvideModule() — depinject provider
//     injects: keeper, codec, storeService, logger

import (
	"context"

	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"google.golang.org/grpc"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// ConsensusVersion is the x/token module consensus version.
const ConsensusVersion = 1

// Module is the AppModule / AppModuleBasic wiring for x/token (RegisterServices, genesis).
type Module struct {
	keeper Keeper
}

// NewModule creates the module wrapper.
func NewModule(k Keeper) Module {
	return Module{keeper: k}
}

// Name returns the module name for the module manager.
func (Module) Name() string { return "token" }

// RegisterGRPCGatewayRoutes registers REST/gRPC-gateway routes (stub).
func (Module) RegisterGRPCGatewayRoutes(_ context.Context, _ *runtime.ServeMux, _ string) error {
	return nil
}

// RegisterServices registers Msg and Query gRPC services on the module configurator.
func (m Module) RegisterServices(cfg module.Configurator) {
	// cfg.RegisterService(&MsgServer{keeper: m.keeper})
	// cfg.RegisterService(&QueryServer{keeper: m.keeper})
	_ = cfg
}

// InitGenesis initializes module state from genesis.
func (m Module) InitGenesis(ctx sdk.Context, data []byte) {
	_ = ctx
	_ = data
}

// ExportGenesis exports module state.
func (m Module) ExportGenesis(ctx sdk.Context) []byte {
	_ = ctx
	return nil
}

// RegisterGRPCServices registers gRPC services on the app (alternative path for some SDK versions).
func (m Module) RegisterGRPCServices(reg grpc.ServiceRegistrar) {
	_ = reg
	_ = m
}
