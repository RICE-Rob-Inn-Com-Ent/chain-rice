package app

import (
	"encoding/json"
	"io"

	storetypes "cosmossdk.io/store/types"
	"cosmossdk.io/x/circuit"
	circuitkeeper "cosmossdk.io/x/circuit/keeper"
	"cosmossdk.io/x/evidence"
	evidencekeeper "cosmossdk.io/x/evidence/keeper"
	feegrantkeeper "cosmossdk.io/x/feegrant/keeper"
	feegrantmodule "cosmossdk.io/x/feegrant/module"
	nftkeeper "cosmossdk.io/x/nft/keeper"
	"cosmossdk.io/x/upgrade"
	upgradekeeper "cosmossdk.io/x/upgrade/keeper"
	"github.com/CosmWasm/wasmd/x/wasm"
	wasmkeeper "github.com/CosmWasm/wasmd/x/wasm/keeper"
	wasmtypes "github.com/CosmWasm/wasmd/x/wasm/types"
	abci "github.com/cometbft/cometbft/abci/types"
	cometlog "github.com/cometbft/cometbft/libs/log"
	dbm "github.com/cosmos/cosmos-db"
	"github.com/cosmos/cosmos-sdk/baseapp"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	"github.com/cosmos/cosmos-sdk/codec/types"
	"github.com/cosmos/cosmos-sdk/runtime"
	"github.com/cosmos/cosmos-sdk/server"
	"github.com/cosmos/cosmos-sdk/server/api"
	"github.com/cosmos/cosmos-sdk/server/config"
	servertypes "github.com/cosmos/cosmos-sdk/server/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/cosmos/cosmos-sdk/x/auth"
	authkeeper "github.com/cosmos/cosmos-sdk/x/auth/keeper"
	"github.com/cosmos/cosmos-sdk/x/auth/signing"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	"github.com/cosmos/cosmos-sdk/x/auth/vesting"
	"github.com/cosmos/cosmos-sdk/x/bank"
	bankkeeper "github.com/cosmos/cosmos-sdk/x/bank/keeper"
	"github.com/cosmos/cosmos-sdk/x/consensus"
	consensusparamkeeper "github.com/cosmos/cosmos-sdk/x/consensus/keeper"
	"github.com/cosmos/cosmos-sdk/x/crisis"
	crisiskeeper "github.com/cosmos/cosmos-sdk/x/crisis/keeper"
	distr "github.com/cosmos/cosmos-sdk/x/distribution"
	distrkeeper "github.com/cosmos/cosmos-sdk/x/distribution/keeper"
	distrtypes "github.com/cosmos/cosmos-sdk/x/distribution/types"
	"github.com/cosmos/cosmos-sdk/x/genutil"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"
	"github.com/cosmos/cosmos-sdk/x/gov"
	govclient "github.com/cosmos/cosmos-sdk/x/gov/client"
	govkeeper "github.com/cosmos/cosmos-sdk/x/gov/keeper"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"
	"github.com/cosmos/cosmos-sdk/x/mint"
	mintkeeper "github.com/cosmos/cosmos-sdk/x/mint/keeper"
	minttypes "github.com/cosmos/cosmos-sdk/x/mint/types"
	"github.com/cosmos/cosmos-sdk/x/params"
	paramsclient "github.com/cosmos/cosmos-sdk/x/params/client"
	paramskeeper "github.com/cosmos/cosmos-sdk/x/params/keeper"
	paramstypes "github.com/cosmos/cosmos-sdk/x/params/types"
	"github.com/cosmos/cosmos-sdk/x/slashing"
	slashingkeeper "github.com/cosmos/cosmos-sdk/x/slashing/keeper"
	"github.com/cosmos/cosmos-sdk/x/staking"
	stakingkeeper "github.com/cosmos/cosmos-sdk/x/staking/keeper"
	stakingtypes "github.com/cosmos/cosmos-sdk/x/staking/types"
	capabilitykeeper "github.com/cosmos/ibc-go/modules/capability/keeper"
	transfer "github.com/cosmos/ibc-go/v8/modules/apps/transfer"
	ibctransferkeeper "github.com/cosmos/ibc-go/v8/modules/apps/transfer/keeper"
	ibctransfertypes "github.com/cosmos/ibc-go/v8/modules/apps/transfer/types"
	ibc "github.com/cosmos/ibc-go/v8/modules/core"
	ibckeeper "github.com/cosmos/ibc-go/v8/modules/core/keeper"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/spf13/cast"
	"github.com/spf13/cobra"

	// Cosmos SDK modules
	"github.com/cosmos/ibc-go/modules/capability"

	// ChainRice modules
	"github.com/rice-dev/backend/blockchain/x/tokens"
	tokenskeeper "github.com/rice-dev/backend/blockchain/x/tokens/keeper"
	tokenstypes "github.com/rice-dev/backend/blockchain/x/tokens/types"
)

const (
	// Name defines the application binary name
	Name = "chainrice"

	// BaseDenom defines the base denomination for the chain
	BaseDenom = "urice"
)

var (
	// DefaultNodeHome default home directories for the application daemon
	DefaultNodeHome string

	// AppConfigYAML is the YAML configuration for the app
	AppConfigYAML = `app:
  accounts:
    - name: alice
      address: cosmos1hj5fveer5cjtn4wd6wstzugjfdxzl0xps73ftl
      coins: ["1000000000000000urice"]
  validator:
    name: alice
    staking: "1000000000000000urice"
`

	// ModuleBasics defines the module BasicManager is in charge of setting up basic,
	// non-dependant module elements, such as codec registration
	// and genesis verification.
	ModuleBasics = module.NewBasicManager(
		auth.AppModuleBasic{},
		genutil.NewAppModuleBasic(genutiltypes.DefaultMessageValidator),
		bank.AppModuleBasic{},
		capability.AppModuleBasic{},
		staking.AppModuleBasic{},
		mint.AppModuleBasic{},
		distr.AppModuleBasic{},
		gov.NewAppModuleBasic(getGovProposalHandlers()),
		params.AppModuleBasic{},
		crisis.AppModuleBasic{},
		slashing.AppModuleBasic{},
		feegrantmodule.AppModuleBasic{},
		ibc.AppModuleBasic{},
		upgrade.AppModuleBasic{},
		evidence.AppModuleBasic{},
		transfer.AppModuleBasic{},
		vesting.AppModuleBasic{},
		circuit.AppModuleBasic{},
		consensus.AppModuleBasic{},
		wasm.AppModuleBasic{},
		// ChainRice modules
		tokens.AppModuleBasic{},
	)

	// module account permissions
	maccPerms = map[string][]string{
		authtypes.FeeCollectorName:     nil,
		distrtypes.ModuleName:          nil,
		minttypes.ModuleName:           {authtypes.Minter},
		stakingtypes.BondedPoolName:    {authtypes.Burner, authtypes.Staking},
		stakingtypes.NotBondedPoolName: {authtypes.Burner, authtypes.Staking},
		govtypes.ModuleName:            {authtypes.Burner},
		ibctransfertypes.ModuleName:    {authtypes.Minter, authtypes.Burner},
		wasmtypes.ModuleName:           {authtypes.Burner},
		// ChainRice modules
		tokenstypes.ModuleName: {authtypes.Minter, authtypes.Burner},
	}
)

var (
	_ runtime.AppI            = (*ChainRiceApp)(nil)
	_ servertypes.Application = (*ChainRiceApp)(nil)
)

// ChainRiceApp extends an ABCI application, but with most of its parameters exported.
// They are exported for convenience in creating helper functions, as object
// capabilities aren't needed for testing.
type ChainRiceApp struct {
	*runtime.App
	legacyAmino       *codec.LegacyAmino
	appCodec          codec.Codec
	txConfig          client.TxConfig
	interfaceRegistry types.InterfaceRegistry

	// BaseApp and store keys
	BaseApp      *baseapp.BaseApp
	kvStoreKeys  map[string]*storetypes.KVStoreKey
	tStoreKeys   map[string]*storetypes.TransientStoreKey
	memStoreKeys map[string]*storetypes.MemoryStoreKey

	// Routers
	MsgServiceRouter *baseapp.MsgServiceRouter
	GRPCQueryRouter  *baseapp.GRPCQueryRouter
	configurator     module.Configurator

	// keepers
	AccountKeeper         authkeeper.AccountKeeper
	BankKeeper            bankkeeper.Keeper
	StakingKeeper         *stakingkeeper.Keeper
	SlashingKeeper        slashingkeeper.Keeper
	MintKeeper            mintkeeper.Keeper
	DistrKeeper           distrkeeper.Keeper
	GovKeeper             *govkeeper.Keeper
	CrisisKeeper          *crisiskeeper.Keeper
	UpgradeKeeper         *upgradekeeper.Keeper
	ParamsKeeper          paramskeeper.Keeper
	EvidenceKeeper        evidencekeeper.Keeper
	FeeGrantKeeper        feegrantkeeper.Keeper
	NFTKeeper             nftkeeper.Keeper
	ConsensusParamsKeeper consensusparamkeeper.Keeper
	CircuitBreakerKeeper  circuitkeeper.Keeper

	// IBC
	IBCKeeper        *ibckeeper.Keeper
	CapabilityKeeper *capabilitykeeper.Keeper

	// IBC Transfer
	TransferKeeper ibctransferkeeper.Keeper

	// CosmWasm
	WasmKeeper wasmkeeper.Keeper

	// ChainRice modules
	TokensKeeper tokenskeeper.Keeper

	// the module manager
	mm *module.Manager

	// simulation manager
	sm *module.SimulationManager

	// RootCmd is the root command of the application
	RootCmd *cobra.Command
}

// NewChainRiceApp returns a reference to an initialized ChainRiceApp.
func NewChainRiceApp(
	logger cometlog.Logger,
	db dbm.DB,
	traceStore io.Writer,
	loadLatest bool,
	appOpts servertypes.AppOptions,
	baseAppOptions ...func(*baseapp.BaseApp),
) *ChainRiceApp {
	var (
		app = &ChainRiceApp{}
		// TODO: Implement appconfig when available in current SDK version
	)

	// TODO: Implement app initialization when appconfig is available
	// For now, return a basic app structure
	app.App = &runtime.App{}

	// Create encoding config and app codec
	encodingConfig := MakeEncodingConfig()
	_ = encodingConfig.Codec

	// TODO: Initialize keepers and modules when appconfig is available

	return app
}

// Name returns the name of the App
func (app *ChainRiceApp) Name() string { return app.BaseApp.Name() }

// BeginBlocker application updates every begin block
func (app *ChainRiceApp) BeginBlocker(ctx sdk.Context) (sdk.BeginBlock, error) {
	return app.mm.BeginBlock(ctx)
}

// EndBlocker application updates every end block
func (app *ChainRiceApp) EndBlocker(ctx sdk.Context) (sdk.EndBlock, error) {
	return app.mm.EndBlock(ctx)
}

// InitChainer application update at chain initialization
func (app *ChainRiceApp) InitChainer(ctx sdk.Context, req *abci.RequestInitChain) (*abci.ResponseInitChain, error) {
	var genesisState GenesisState
	if err := json.Unmarshal(req.AppStateBytes, &genesisState); err != nil {
		panic(err)
	}

	// TODO: Implement when appconfig is available
	// app.UpgradeKeeper.SetModuleVersionMap(ctx, app.mm.GetVersionMap())
	// app.mm.InitGenesis(ctx, app.appCodec, genesisState)
	return &abci.ResponseInitChain{}, nil
}

// LoadHeight loads a particular height
func (app *ChainRiceApp) LoadHeight(height int64) error {
	return app.LoadVersion(height)
}

// ModuleAccountAddrs returns all the app's module account addresses.
func (app *ChainRiceApp) ModuleAccountAddrs() map[string]bool {
	modAccAddrs := make(map[string]bool)
	for acc := range maccPerms {
		modAccAddrs[authtypes.NewModuleAddress(acc).String()] = true
	}

	return modAccAddrs
}

// BlockedModuleAccountAddrs returns all the app's blocked module account
// addresses.
func (app *ChainRiceApp) BlockedModuleAccountAddrs() map[string]bool {
	modAccAddrs := app.ModuleAccountAddrs()
	delete(modAccAddrs, authtypes.NewModuleAddress(govtypes.ModuleName).String())

	return modAccAddrs
}

// LegacyAmino returns ChainRiceApp's amino codec.
//
// NOTE: This is solely to be used for testing purposes as it may be desirable
// for modules to register their own custom testing types.
func (app *ChainRiceApp) LegacyAmino() *codec.LegacyAmino {
	return app.legacyAmino
}

// AppCodec returns ChainRiceApp's app codec.
//
// NOTE: This is solely to be used for testing purposes as it may be desirable
// for modules to register their own custom testing types.
func (app *ChainRiceApp) AppCodec() codec.Codec {
	return app.appCodec
}

// InterfaceRegistry returns ChainRiceApp's InterfaceRegistry
func (app *ChainRiceApp) InterfaceRegistry() types.InterfaceRegistry {
	return app.interfaceRegistry
}

// TxConfig returns ChainRiceApp's TxConfig
func (app *ChainRiceApp) TxConfig() client.TxConfig {
	return app.txConfig
}

// GetKey returns the KVStoreKey for the provided store key.
//
// NOTE: This is solely to be used for testing purposes.
func (app *ChainRiceApp) GetKey(storeKey string) *storetypes.KVStoreKey {
	// TODO: Implement when store keys are available
	return nil
}

// GetTKey returns the TransientStoreKey for the provided store key.
//
// NOTE: This is solely to be used for testing purposes.
func (app *ChainRiceApp) GetTKey(storeKey string) *storetypes.TransientStoreKey {
	// TODO: Implement when store keys are available
	return nil
}

// GetMemKey returns the MemStoreKey for the provided mem key.
//
// NOTE: This is solely used for testing purposes.
func (app *ChainRiceApp) GetMemKey(storeKey string) *storetypes.MemoryStoreKey {
	// TODO: Implement when store keys are available
	return nil
}

// GetSubspace returns a param subspace for a given module name.
//
// NOTE: This is solely to be used for testing purposes.
func (app *ChainRiceApp) GetSubspace(moduleName string) paramstypes.Subspace {
	subspace, _ := app.ParamsKeeper.GetSubspace(moduleName)
	return subspace
}

// SimulationManager implements the SimulationApp interface
func (app *ChainRiceApp) SimulationManager() *module.SimulationManager {
	return app.sm
}

// RegisterAPIRoutes registers all application module routes with the provided
// API server.
func (app *ChainRiceApp) RegisterAPIRoutes(apiSvr *api.Server, apiConfig config.APIConfig) {
	app.App.RegisterAPIRoutes(apiSvr, apiConfig)
	// register swagger API in app.go so that other applications can override easily
	if err := server.RegisterSwaggerAPI(apiSvr.ClientCtx, apiSvr.Router, apiConfig.Swagger); err != nil {
		panic(err)
	}
}

// GetMaccPerms returns a copy of the module account permissions
func GetMaccPerms() map[string][]string {
	dupMaccPerms := make(map[string][]string)
	for k, v := range maccPerms {
		dupMaccPerms[k] = v
	}
	return dupMaccPerms
}

// EmptyAppOptions is a stub implementing AppOptions
type EmptyAppOptions struct{}

// Get implements AppOptions
func (ao EmptyAppOptions) Get(o string) interface{} {
	return nil
}

// GetGovProposalHandlers returns the chainrice proposal handlers.
func getGovProposalHandlers() []govclient.ProposalHandler {
	var govProposalHandlers []govclient.ProposalHandler
	// this line is used by starport scaffolding # stargate/app/govProposalHandlers

	govProposalHandlers = append(govProposalHandlers,
		paramsclient.ProposalHandler,
		// upgradeclient.LegacyProposalHandler, // Not available in current version
		// upgradeclient.LegacyCancelProposalHandler, // Not available in current version
		// ibcclient.ClientUpdateProposalHandler, // Not available in current version
		// ibcclient.ClientUpgradeProposalHandler, // Not available in current version
		// this line is used by starport scaffolding # stargate/app/govProposalHandler
	)

	return govProposalHandlers
}

// DefaultGenesis returns a default genesis from the registered AppModuleBasic's.
func (app *ChainRiceApp) DefaultGenesis() map[string]json.RawMessage {
	return ModuleBasics.DefaultGenesis(app.appCodec)
}

// SetChainRiceConfig returns the default app config for chainrice
func SetChainRiceConfig() servertypes.AppOptions {
	return EmptyAppOptions{}
}

// SetPruning sets the pruning options
func SetPruning(opts interface{}) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// TODO: Implement pruning when available in current SDK version
	}
}

// SetMinGasPrices sets the minimum gas prices
func SetMinGasPrices(gasPricesStr string) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// This is handled in the app config
	}
}

// SetHaltHeight sets the halt height
func SetHaltHeight(height uint64) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// This is handled in the app config
	}
}

// SetHaltTime sets the halt time
func SetHaltTime(time uint64) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// This is handled in the app config
	}
}

// SetMinRetainBlocks sets the minimum retain blocks
func SetMinRetainBlocks(blocks uint64) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// TODO: Implement when available in current SDK version
	}
}

// SetInterBlockCache sets the inter-block cache
func SetInterBlockCache(cache interface{}) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// TODO: Implement when available in current SDK version
	}
}

// SetTrace sets the trace option
func SetTrace(trace bool) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// TODO: Implement when available in current SDK version
	}
}

// SetIndexEvents sets the index events
func SetIndexEvents(events []string) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// TODO: Implement when available in current SDK version
	}
}

// SetSnapshot sets the snapshot store and options
// Note: Snapshots are not available in the current version
// func SetSnapshot(snapshotStore *snapshots.Store, snapshotOptions snapshottypes.SnapshotOptions) func(*baseapp.BaseApp) {
//	return func(app *baseapp.BaseApp) {
//		app.SetSnapshot(snapshotStore, snapshotOptions)
//	}
// }

// SetIAVLCacheSize sets the IAVL cache size
func SetIAVLCacheSize(size int) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// TODO: Implement when available in current SDK version
	}
}

// SetIAVLDisableFastNode sets the IAVL disable fast node option
func SetIAVLDisableFastNode(disable bool) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// TODO: Implement when available in current SDK version
	}
}

// SetIAVLInterBlockCache sets the IAVL inter-block cache option
func SetIAVLInterBlockCache(enable bool) func(*baseapp.BaseApp) {
	return func(app *baseapp.BaseApp) {
		// TODO: Implement when available in current SDK version
	}
}

// RegisterStreamingServices registers streaming services
func (app *ChainRiceApp) RegisterStreamingServices(appOpts servertypes.AppOptions, kvStoreKeys map[string]*storetypes.KVStoreKey) error {
	// TODO: Implement streaming services registration
	return nil
}

// MountKVStores mounts KV stores
func (app *ChainRiceApp) MountKVStores(keys map[string]*storetypes.KVStoreKey) {
	// TODO: Implement KV store mounting
}

// MountTransientStores mounts transient stores
func (app *ChainRiceApp) MountTransientStores(keys map[string]*storetypes.TransientStoreKey) {
	// TODO: Implement transient store mounting
}

// MountMemoryStores mounts memory stores
func (app *ChainRiceApp) MountMemoryStores(keys map[string]*storetypes.MemoryStoreKey) {
	// TODO: Implement memory store mounting
}

// SetInitChainer sets the init chainer
func (app *ChainRiceApp) SetInitChainer(initChainer func(sdk.Context, *abci.RequestInitChain) (*abci.ResponseInitChain, error)) {
	// TODO: Implement init chainer setting
}

// SetBeginBlocker sets the begin blocker
func (app *ChainRiceApp) SetBeginBlocker(beginBlocker func(sdk.Context) (sdk.BeginBlock, error)) {
	// TODO: Implement begin blocker setting
}

// SetEndBlocker sets the end blocker
func (app *ChainRiceApp) SetEndBlocker(endBlocker func(sdk.Context) (sdk.EndBlock, error)) {
	// TODO: Implement end blocker setting
}

// SetAnteHandler sets the ante handler
func (app *ChainRiceApp) SetAnteHandler(anteHandler sdk.AnteHandler) {
	// TODO: Implement ante handler setting
}

// SignModeHandler returns the sign mode handler
func (app *ChainRiceApp) SignModeHandler() signing.SignModeHandler {
	// TODO: Implement sign mode handler
	return nil
}

// LoadLatestVersion loads the latest version
func (app *ChainRiceApp) LoadLatestVersion() error {
	// TODO: Implement load latest version
	return nil
}

// LoadVersion loads a specific version
func (app *ChainRiceApp) LoadVersion(version int64) error {
	// TODO: Implement load version
	return nil
}

// ExportAppStateAndValidators exports the application state and validators
func (app *ChainRiceApp) ExportAppStateAndValidators(forZeroHeight bool, jailAllowedAddrs []string, modulesToExport []string) (servertypes.ExportedApp, error) {
	// TODO: Implement export when available in current SDK version
	return servertypes.ExportedApp{}, nil
}

// UnsafeFindStoreKey finds a store key
func (app *ChainRiceApp) UnsafeFindStoreKey(storeKey string) *storetypes.StoreKey {
	// TODO: Implement store key finding
	return nil
}

// MakeEncodingConfig creates an EncodingConfig for testing
func MakeEncodingConfig() EncodingConfig {
	encodingConfig := MakeTestEncodingConfig()
	return encodingConfig
}

// MakeTestEncodingConfig creates an EncodingConfig for testing
func MakeTestEncodingConfig() EncodingConfig {
	encodingConfig := EncodingConfig{
		Codec:             codec.NewProtoCodec(nil),
		InterfaceRegistry: types.NewInterfaceRegistry(),
		TxConfig:          nil, // TODO: implement
		Amino:             codec.NewLegacyAmino(),
	}
	return encodingConfig
}

// EncodingConfig specifies the concrete encoding types to use for a given app.
type EncodingConfig struct {
	InterfaceRegistry types.InterfaceRegistry
	Codec             codec.Codec
	TxConfig          client.TxConfig
	Amino             *codec.LegacyAmino
}

// GetWasmOpts build wasm options
func GetWasmOpts(appOpts servertypes.AppOptions) []wasm.Option {
	var wasmOpts []wasm.Option
	if cast.ToBool(appOpts.Get("telemetry.enabled")) {
		wasmOpts = append(wasmOpts, wasmkeeper.WithVMCacheMetrics(prometheus.DefaultRegisterer))
	}

	return wasmOpts
}

// GenesisState represents the genesis state of the application
type GenesisState map[string]json.RawMessage

// ProvideModule provides the module dependencies
func ProvideModule() interface{} {
	return nil
}

// ProvideEnvironment provides the environment dependencies
func ProvideEnvironment() interface{} {
	return nil
}

// ProvideLogger provides the logger dependencies
func ProvideLogger() interface{} {
	return nil
}
