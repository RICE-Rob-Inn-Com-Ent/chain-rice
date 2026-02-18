package token

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"

	cmtconfig "github.com/cometbft/cometbft/config"
	types "github.com/cometbft/cometbft/types"
	tmtime "github.com/cometbft/cometbft/types/time"
	"github.com/cosmos/cosmos-sdk/client"
	cryptotypes "github.com/cosmos/cosmos-sdk/crypto/types"
	"github.com/cosmos/cosmos-sdk/runtime"
	"github.com/cosmos/cosmos-sdk/types/module"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	"github.com/cosmos/cosmos-sdk/x/genutil"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"
)

func initGenFiles(
	clientCtx client.Context, mbm module.BasicManager, chainID string,
	genAccounts []authtypes.GenesisAccount, genBalances []banktypes.Balance,
	genFiles []string, numValidators int,
) error {
	appGenState := mbm.DefaultGenesis(clientCtx.Codec)

	// set the accounts in the genesis state
	var authGenState authtypes.GenesisState
	clientCtx.Codec.MustUnmarshalJSON(appGenState[authtypes.ModuleName], &authGenState)

	accounts, err := authtypes.PackAccounts(genAccounts)
	if err != nil {
		return err
	}

	authGenState.Accounts = accounts
	appGenState[authtypes.ModuleName] = clientCtx.Codec.MustMarshalJSON(&authGenState)

	// set the balances in the genesis state
	var bankGenState banktypes.GenesisState
	clientCtx.Codec.MustUnmarshalJSON(appGenState[banktypes.ModuleName], &bankGenState)

	bankGenState.Balances = banktypes.SanitizeGenesisBalances(genBalances)
	for _, bal := range bankGenState.Balances {
		bankGenState.Supply = bankGenState.Supply.Add(bal.Coins...)
	}
	appGenState[banktypes.ModuleName] = clientCtx.Codec.MustMarshalJSON(&bankGenState)

	appGenStateJSON, err := json.MarshalIndent(appGenState, "", "  ")
	if err != nil {
		return err
	}

	genDoc := types.GenesisDoc{
		ChainID:    chainID,
		AppState:   appGenStateJSON,
		Validators: nil,
	}

	// generate empty genesis files for each validator and save
	for i := 0; i < numValidators; i++ {
		if err := genDoc.SaveAs(genFiles[i]); err != nil {
			return err
		}
	}
	return nil
}

func collectGenFiles(
	clientCtx client.Context, nodeConfig *cmtconfig.Config,
	nodeIDs []string, valPubKeys []cryptotypes.PubKey,
	genBalIterator banktypes.GenesisBalancesIterator,
	valAddrCodec runtime.ValidatorAddressCodec, persistentPeers string,
	args initArgs,
) error {
	chainID := args.chainID
	numValidators := args.numValidators
	outputDir := args.outputDir
	nodeDirPrefix := args.nodeDirPrefix

	var appState json.RawMessage
	genTime := tmtime.Now()

	for i := 0; i < numValidators; i++ {
		nodeDirName := fmt.Sprintf("%s%d", nodeDirPrefix, i)
		nodeDir := filepath.Join(outputDir, nodeDirName)
		gentxsDir := filepath.Join(nodeDir, "config", "gentx")
		nodeConfig.Moniker = nodeDirName

		nodeConfig.SetRoot(nodeDir)

		nodeID, valPubKey := nodeIDs[i], valPubKeys[i]
		initCfg := genutiltypes.NewInitConfig(chainID, gentxsDir, nodeID, valPubKey)

		appGenesis, err := genutiltypes.AppGenesisFromFile(nodeConfig.GenesisFile())
		if err != nil {
			return err
		}

		nodeAppState, err := genutil.GenAppStateFromConfig(clientCtx.Codec, clientCtx.TxConfig, nodeConfig, initCfg, appGenesis, genBalIterator, genutiltypes.DefaultMessageValidator,
			valAddrCodec)
		if err != nil {
			return err
		}

		nodeConfig.P2P.PersistentPeers = persistentPeers
		nodeConfig.P2P.AllowDuplicateIP = true
		nodeConfig.P2P.ListenAddress = "tcp://0.0.0.0:" + strconv.Itoa(26656-3*i)
		nodeConfig.RPC.ListenAddress = "tcp://127.0.0.1:" + args.ports[i]
		nodeConfig.BaseConfig.ProxyApp = "tcp://127.0.0.1:" + strconv.Itoa(26658-3*i)
		nodeConfig.Instrumentation.PrometheusListenAddr = ":" + strconv.Itoa(26660+i)
		nodeConfig.Instrumentation.Prometheus = true
		cmtconfig.WriteConfigFile(filepath.Join(nodeConfig.RootDir, "config", "config.toml"), nodeConfig)
		if appState == nil {
			// set the canonical application state (they should not differ)
			appState = nodeAppState
		}

		genFile := nodeConfig.GenesisFile()
		genDoc := &types.GenesisDoc{}
		if _, err := os.Stat(genFile); err != nil {
			if !os.IsNotExist(err) {
				return err
			}
		} else {
			genDoc, err = types.GenesisDocFromFile(genFile)
			if err != nil {
				return err
			}
		}

		genDoc.ChainID = chainID
		genDoc.Validators = nil
		genDoc.AppState = nodeAppState
		genDoc.GenesisTime = genTime

		if err := genDoc.SaveAs(genFile); err != nil {
			return err
		}
	}

	return nil
}
