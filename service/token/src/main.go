package token

import (
	"fmt"

	cosmosaddress "cosmossdk.io/core/address"
	corestore "cosmossdk.io/core/store"
	"cosmossdk.io/depinject"
	"cosmossdk.io/log"

	"github.com/cosmos/cosmos-sdk/codec"
	addresscodec "github.com/cosmos/cosmos-sdk/codec/address"
	sdk "github.com/cosmos/cosmos-sdk/types"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"
)

// ModuleSettings is the single exported integration surface for SAGE (AI), BARD (UI), and other .rice roles.
// Construct via [NewModuleSettings] or depinject [ProvideTokenModule].
type ModuleSettings struct {
	Keeper        Keeper
	MsgServer     MsgServer
	QueryServer   QueryServer
	Configuration Config
	AppModule     TokenAppModule
}

// NewModuleSettings bundles keeper-derived handlers and module wiring.
func NewModuleSettings(k Keeper) ModuleSettings {
	return ModuleSettings{
		Keeper:        k,
		MsgServer:     NewMsgServer(k),
		QueryServer:   NewQueryServer(k),
		Configuration: k.Config,
		AppModule:     NewTokenAppModule(k),
	}
}

// TokenModuleInputs are injected dependencies for [ProvideTokenModule].
// Use [depinject.Supply] or runtime wiring to provide [corestore.KVStoreService] scoped to [StoreKeyToken].
type TokenModuleInputs struct {
	depinject.In

	Cdc            codec.Codec
	Logger         log.Logger
	KVStoreService corestore.KVStoreService
	AddressCodec   cosmosaddress.Codec `optional:"true"`
	Authority      sdk.AccAddress      `optional:"true"`
}

// TokenModuleOutputs are produced for composition into the application graph.
type TokenModuleOutputs struct {
	depinject.Out

	ModuleSettings ModuleSettings
}

// ProvideTokenModule is the depinject provider for x/token (Cosmos SDK v0.53 style).
// Optional fields: [address.Codec] defaults to account Bech32 prefix; [Authority] defaults to gov module account.
func ProvideTokenModule(in TokenModuleInputs) (TokenModuleOutputs, error) {
	ac := in.AddressCodec
	if ac == nil {
		ac = addresscodec.NewBech32Codec(sdk.GetConfig().GetBech32AccountAddrPrefix())
	}
	auth := in.Authority
	if auth == nil || auth.Empty() {
		auth = authtypes.NewModuleAddress(govtypes.ModuleName)
	}
	k, err := NewKeeper(
		in.Cdc,
		in.KVStoreService,
		StoreKeyToken,
		CrossModuleKeepers{},
		ac,
		auth,
		in.Logger,
		DefaultConfig(),
	)
	if err != nil {
		return TokenModuleOutputs{}, fmt.Errorf("token ProvideModule: %w", err)
	}
	return TokenModuleOutputs{ModuleSettings: NewModuleSettings(k)}, nil
}

// ProvideModule returns a [depinject.Config] fragment that registers [ProvideTokenModule].
// Compose with app config: depinject.Configs(riceapp.DepinjectConfig(...), token.ProvideModule(), ...).
//
// Note: cosmossdk.io/depinject uses struct tags such as optional:"true" for variant injection; there is no
// depinject.IsOneOf in v1.2.x—optional dependencies are expressed that way on [TokenModuleInputs].
func ProvideModule() depinject.Config {
	return depinject.Configs(
		depinject.Provide(ProvideTokenModule),
	)
}
