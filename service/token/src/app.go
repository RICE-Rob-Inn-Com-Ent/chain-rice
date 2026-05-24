// Package token implements the Cosmos SDK application shell for the RICE token chain.
package token

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/RICE-Rob-Inn-Com-Ent/rice/service/token/internal/riceapp"
	cmtcfg "github.com/cometbft/cometbft/config"
	"github.com/cometbft/cometbft/node"
	"github.com/cometbft/cometbft/p2p"
	"github.com/cometbft/cometbft/privval"
	"github.com/cometbft/cometbft/proxy"
	cmttypes "github.com/cometbft/cometbft/types"
	dbm "github.com/cosmos/cosmos-db"
	"github.com/cosmos/cosmos-sdk/baseapp"
	"github.com/cosmos/cosmos-sdk/codec"
	addresscodec "github.com/cosmos/cosmos-sdk/codec/address"
	"github.com/cosmos/cosmos-sdk/runtime"
	"github.com/cosmos/cosmos-sdk/server"
	servercmtlog "github.com/cosmos/cosmos-sdk/server/log"
	sdk "github.com/cosmos/cosmos-sdk/types"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"

	"cosmossdk.io/depinject"
	"cosmossdk.io/log"
)

// BankKeeperI is a narrow hook for future x/token ↔ x/bank composition (SAGE/BARD integrations).
type BankKeeperI interface{}

// AuthKeeperI is a narrow hook for future account validation alongside x/token.
type AuthKeeperI interface{}

// StakingKeeperI is a narrow hook for staking-aware token policy (e.g. bonded supply views).
type StakingKeeperI interface{}

// AppModuleRegistry lists Cosmos module names the .rice runtime expects (auth, bank, token, …).
type AppModuleRegistry struct {
	// ModuleNames is the ordered logical registry for docs, CLIs, and BARD module pickers.
	ModuleNames []string
}

// DefaultRiceChainModuleNames returns the default module name list (SDK core + x/token).
func DefaultRiceChainModuleNames() []string {
	return []string{
		"auth",
		"bank",
		"distribution",
		"staking",
		"slashing",
		"gov",
		"mint",
		"genutil",
		"evidence",
		"authz",
		"feegrant",
		"nft",
		"group",
		"params",
		"consensus",
		"upgrade",
		"vesting",
		"circuit",
		"protocolpool",
		ModuleName,
	}
}

// App wraps [runtime.App] with SMITH logging, Pebble-backed state, optional CometBFT node lifecycle,
// and the unified x/token [ModuleSettings] for BARD/SAGE.
type App struct {
	SDKApp *runtime.App
	Logger log.Logger
	DB     dbm.DB

	// ModuleSettings is the integration bundle (keeper, msg/query servers, app module).
	ModuleSettings ModuleSettings
	// Deps holds optional references to other keepers when the app wires them explicitly.
	Deps AppDependencies
	// Registry documents which modules participate in the chain.
	Registry AppModuleRegistry

	node *node.Node
}

// AppDependencies groups peer keepers that a full .rice app may inject next to x/token.
type AppDependencies struct {
	Bank    BankKeeperI
	Auth    AuthKeeperI
	Staking StakingKeeperI
}

// AppOptions configures [NewApp].
type AppOptions struct {
	// Logger defaults to stderr JSON logger when nil.
	Logger log.Logger
	// DB must be non-nil. Use [OpenPebbleDB] for the default SMITH layout.
	DB dbm.DB
	// ChainID is applied as a BaseApp option (e.g. cometbft chain-id).
	ChainID string
}

// OpenPebbleDB opens a Pebble-backed application.db under home/data.
func OpenPebbleDB(homeDir string) (dbm.DB, error) {
	if homeDir == "" {
		return nil, errors.New("token: home directory required for Pebble DB")
	}
	dataDir := filepath.Join(homeDir, "data")
	if err := os.MkdirAll(dataDir, 0o755); err != nil {
		return nil, err
	}
	return dbm.NewDB("application", dbm.PebbleDBBackend, dataDir)
}

// NewApp builds a fully wired Cosmos SDK application via depinject and registers the x/token module.
func NewApp(opts AppOptions) (*App, error) {
	if opts.DB == nil {
		return nil, errors.New("token: AppOptions.DB is required")
	}
	logger := opts.Logger
	if logger == nil {
		logger = log.NewLogger(os.Stderr)
	}

	cfg := depinject.Configs(
		riceapp.DepinjectConfig(riceapp.DefaultModuleOptions()...),
		depinject.Supply(logger),
	)

	var (
		appBuilder *runtime.AppBuilder
		appCodec   codec.Codec
	)
	if err := depinject.Inject(cfg, &appBuilder, &appCodec); err != nil {
		return nil, fmt.Errorf("token: depinject: %w", err)
	}

	var baseOpts []func(*baseapp.BaseApp)
	if opts.ChainID != "" {
		baseOpts = append(baseOpts, baseapp.SetChainID(opts.ChainID))
	}

	sdkApp := appBuilder.Build(opts.DB, nil, baseOpts...)

	storeSvc := runtime.NewKVStoreService(StoreKeyToken)
	ac := addresscodec.NewBech32Codec(sdk.GetConfig().GetBech32AccountAddrPrefix())
	keeper, err := NewKeeper(
		appCodec,
		storeSvc,
		StoreKeyToken,
		CrossModuleKeepers{},
		ac,
		authtypes.NewModuleAddress("gov"),
		logger,
		DefaultConfig(),
	)
	if err != nil {
		return nil, fmt.Errorf("token: keeper: %w", err)
	}
	settings := NewModuleSettings(keeper)

	if err := sdkApp.RegisterStores(StoreKeyToken); err != nil {
		return nil, err
	}
	if err := sdkApp.RegisterModules(settings.AppModule); err != nil {
		return nil, err
	}

	if err := sdkApp.Load(true); err != nil {
		return nil, fmt.Errorf("token: app load: %w", err)
	}

	return &App{
		SDKApp:         sdkApp,
		Logger:         logger,
		DB:             opts.DB,
		ModuleSettings: settings,
		Registry:       AppModuleRegistry{ModuleNames: DefaultRiceChainModuleNames()},
	}, nil
}

// StartCometNode creates and starts a CometBFT node using this app as the ABCI application.
// cfg must point at initialized node home (config, genesis, keys). This mirrors [server.startCmtNode].
func (a *App) StartCometNode(ctx context.Context, cfg *cmtcfg.Config) error {
	if a.node != nil {
		return errors.New("token: comet node already started")
	}
	nodeKey, err := p2p.LoadOrGenNodeKey(cfg.NodeKeyFile())
	if err != nil {
		return err
	}

	genesisProvider := func() (*cmttypes.GenesisDoc, error) {
		appGenesis, err := genutiltypes.AppGenesisFromFile(cfg.GenesisFile())
		if err != nil {
			return nil, err
		}
		return appGenesis.ToGenesisDoc()
	}

	cmtApp := server.NewCometABCIWrapper(a.SDKApp)
	n, err := node.NewNodeWithContext(
		ctx,
		cfg,
		privval.LoadOrGenFilePV(cfg.PrivValidatorKeyFile(), cfg.PrivValidatorStateFile()),
		nodeKey,
		proxy.NewLocalClientCreator(cmtApp),
		genesisProvider,
		cmtcfg.DefaultDBProvider,
		node.DefaultMetricsProvider(cfg.Instrumentation),
		servercmtlog.CometLoggerWrapper{Logger: a.Logger},
	)
	if err != nil {
		return err
	}
	a.node = n
	return n.Start()
}

// StopCometNode stops the CometBFT node if it was started.
func (a *App) StopCometNode() error {
	if a.node == nil {
		return nil
	}
	var err error
	if a.node.IsRunning() {
		err = a.node.Stop()
	}
	a.node = nil
	return err
}

// Close releases the application database handle.
func (a *App) Close() error {
	_ = a.StopCometNode()
	if a.DB == nil {
		return nil
	}
	return a.DB.Close()
}

// Runtime returns the underlying Cosmos [runtime.App] (ABCI host).
func (a *App) Runtime() *runtime.App {
	return a.SDKApp
}
