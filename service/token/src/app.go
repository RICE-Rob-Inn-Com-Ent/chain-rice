// Package token implements the Cosmos SDK application shell for the RICE token chain:
// runtime.App (BaseApp), module manager, depinject wiring, and ABCI delegation.
package token

// TODO:
// [ ] implement Cosmos SDK app:
//     App struct embeds runtime.App
//     registers all modules via depinject
// [ ] implement depinject app config:
//     appconfig.Compose() with all module configs
//     reads from token/src/config.go
// [ ] implement app initialization:
//     NewApp(logger, db, config) *App
//     all config from RICE_TOKEN_* env vars

import (
	"github.com/cosmos/cosmos-sdk/runtime"
)

// TokenApp wraps the SDK runtime.App: BaseApp, ModuleManager, MsgServiceRouter, GRPCQueryRouter, ABCI.
// Build the concrete *runtime.App via depinject (see config.go) and assign here.
type TokenApp struct {
	*runtime.App
}
