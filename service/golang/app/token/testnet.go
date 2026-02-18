package token

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/rand"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	cmtconfig "github.com/cometbft/cometbft/config"
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"

	"cosmossdk.io/log"
	"cosmossdk.io/math"
	storetypes "cosmossdk.io/store/types"
	"github.com/cometbft/cometbft/crypto"
	"github.com/cometbft/cometbft/libs/bytes"
	cmtproto "github.com/cometbft/cometbft/proto/tendermint/types"
	dbm "github.com/cosmos/cosmos-db"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/crypto/hd"
	"github.com/cosmos/cosmos-sdk/crypto/keyring"
	"github.com/cosmos/cosmos-sdk/crypto/keys/ed25519"
	cryptotypes "github.com/cosmos/cosmos-sdk/crypto/types"
	"github.com/cosmos/cosmos-sdk/server"
	serverconfig "github.com/cosmos/cosmos-sdk/server/config"
	servertypes "github.com/cosmos/cosmos-sdk/server/types"
	"github.com/cosmos/cosmos-sdk/testutil"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/cosmos/cosmos-sdk/client/tx"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	"github.com/cosmos/cosmos-sdk/x/genutil"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	distrtypes "github.com/cosmos/cosmos-sdk/x/distribution/types"
	minttypes "github.com/cosmos/cosmos-sdk/x/mint/types"
	slashingtypes "github.com/cosmos/cosmos-sdk/x/slashing/types"
	stakingtypes "github.com/cosmos/cosmos-sdk/x/staking/types"
)

const valVotingPower int64 = 900000000000000

var flagAccountsToFund = "accounts-to-fund"

type valArgs struct {
	newValAddr         bytes.HexBytes
	newOperatorAddress string
	newValPubKey       crypto.PubKey
	accountsToFund     []string
	upgradeToTrigger   string
	homeDir            string
}

func newInPlaceTestnetCmd() *cobra.Command {
	cmd := server.InPlaceTestnetCreator(newTestnetApp)
	cmd.Short = "Updates chain's application and consensus state with provided validator info and starts the node"
	cmd.Long = `The test command modifies both application and consensus stores within a local mainnet node and starts the node,
with the aim of facilitating testing procedures. This command replaces existing validator data with updated information,
thereby removing the old validator set and introducing a new set suitable for local testing purposes. By altering the state extracted from the mainnet node,
it enables developers to configure their local environments to reflect mainnet conditions more accurately.`

	cmd.Example = fmt.Sprintf(`%sd in-place-testnet testing-1 cosmosvaloper1w7f3xx7e75p4l7qdym5msqem9rd4dyc4mq79dm --home $HOME/.%sd/validator1 --validator-privkey=6dq+/KHNvyiw2TToCgOpUpQKIzrLs69Rb8Az39xvmxPHNoPxY1Cil8FY+4DhT9YwD6s0tFABMlLcpaylzKKBOg== --accounts-to-fund="cosmos1f7twgcq4ypzg7y24wuywy06xmdet8pc4473tnq,cosmos1qvuhm5m644660nd8377d6l7yz9e9hhm9evmx3x"`, Name, Name)

	cmd.Flags().String(flagAccountsToFund, "", "Comma-separated list of account addresses that will be funded for testing purposes")
	return cmd
}

// newTestnetApp starts by running the normal newApp method. From there, the app interface returned is modified in order
// for a testnet to be created from the provided app.
func newTestnetApp(logger log.Logger, db dbm.DB, traceStore io.Writer, appOpts servertypes.AppOptions) servertypes.Application {
	// Create an app
	bApp := New(logger, db, traceStore, true, appOpts)
	testApp := bApp // bApp is already *App, no need for type assertion

	// Get command args
	args, err := getCommandArgs(appOpts)
	if err != nil {
		panic(err)
	}

	return initAppForTestnet(testApp, args)
}

func initAppForTestnet(app *App, args valArgs) *App {
	// Required Changes:
	//
	ctx := app.App.NewUncachedContext(true, cmtproto.Header{})

	pubkey := &ed25519.PubKey{Key: args.newValPubKey.Bytes()}
	pubkeyAny, err := codectypes.NewAnyWithValue(pubkey)
	handleErr(err)

	// STAKING
	//

	// Create Validator struct for our new validator.
	newVal := stakingtypes.Validator{
		OperatorAddress: args.newOperatorAddress,
		ConsensusPubkey: pubkeyAny,
		Jailed:          false,
		Status:          stakingtypes.Bonded,
		Tokens:          math.NewInt(valVotingPower),
		DelegatorShares: math.LegacyMustNewDecFromStr("10000000"),
		Description: stakingtypes.Description{
			Moniker: "Testnet Validator",
		},
		Commission: stakingtypes.Commission{
			CommissionRates: stakingtypes.CommissionRates{
				Rate:          math.LegacyMustNewDecFromStr("0.05"),
				MaxRate:       math.LegacyMustNewDecFromStr("0.1"),
				MaxChangeRate: math.LegacyMustNewDecFromStr("0.05"),
			},
		},
		MinSelfDelegation: math.OneInt(),
	}

	validator, err := app.StakingKeeper.ValidatorAddressCodec().StringToBytes(newVal.GetOperator())
	handleErr(err)

	// Remove all validators from power store
	stakingKey := app.GetKey(stakingtypes.ModuleName)
	stakingStore := ctx.KVStore(stakingKey)
	iterator, err := app.StakingKeeper.ValidatorsPowerStoreIterator(ctx)
	handleErr(err)

	for ; iterator.Valid(); iterator.Next() {
		stakingStore.Delete(iterator.Key())
	}
	iterator.Close()

	// Remove all validators from last validators store
	iterator, err = app.StakingKeeper.LastValidatorsIterator(ctx)
	handleErr(err)

	for ; iterator.Valid(); iterator.Next() {
		stakingStore.Delete(iterator.Key())
	}
	iterator.Close()

	// Remove all validators from validators store
	iterator = stakingStore.Iterator(stakingtypes.ValidatorsKey, storetypes.PrefixEndBytes(stakingtypes.ValidatorsKey))
	for ; iterator.Valid(); iterator.Next() {
		stakingStore.Delete(iterator.Key())
	}
	iterator.Close()

	// Remove all validators from unbonding queue
	iterator = stakingStore.Iterator(stakingtypes.ValidatorQueueKey, storetypes.PrefixEndBytes(stakingtypes.ValidatorQueueKey))
	for ; iterator.Valid(); iterator.Next() {
		stakingStore.Delete(iterator.Key())
	}
	iterator.Close()

	// Add our validator to power and last validators store
	handleErr(app.StakingKeeper.SetValidator(ctx, newVal))
	handleErr(app.StakingKeeper.SetValidatorByConsAddr(ctx, newVal))
	handleErr(app.StakingKeeper.SetValidatorByPowerIndex(ctx, newVal))
	handleErr(app.StakingKeeper.SetLastValidatorPower(ctx, validator, 0))
	handleErr(app.StakingKeeper.Hooks().AfterValidatorCreated(ctx, validator))

	// DISTRIBUTION
	//

	// Initialize records for this validator across all distribution stores
	handleErr(app.DistrKeeper.SetValidatorHistoricalRewards(ctx, validator, 0, distrtypes.NewValidatorHistoricalRewards(sdk.DecCoins{}, 1)))
	handleErr(app.DistrKeeper.SetValidatorCurrentRewards(ctx, validator, distrtypes.NewValidatorCurrentRewards(sdk.DecCoins{}, 1)))
	handleErr(app.DistrKeeper.SetValidatorAccumulatedCommission(ctx, validator, distrtypes.InitialValidatorAccumulatedCommission()))
	handleErr(app.DistrKeeper.SetValidatorOutstandingRewards(ctx, validator, distrtypes.ValidatorOutstandingRewards{Rewards: sdk.DecCoins{}}))

	// SLASHING
	//

	// Set validator signing info for our new validator.
	newConsAddr := sdk.ConsAddress(args.newValAddr.Bytes())
	newValidatorSigningInfo := slashingtypes.ValidatorSigningInfo{
		Address:     newConsAddr.String(),
		StartHeight: app.App.LastBlockHeight() - 1,
		Tombstoned:  false,
	}
	_ = app.SlashingKeeper.SetValidatorSigningInfo(ctx, newConsAddr, newValidatorSigningInfo)

	// BANK
	//
	bondDenom, err := app.StakingKeeper.BondDenom(ctx)
	handleErr(err)

	defaultCoins := sdk.NewCoins(sdk.NewInt64Coin(bondDenom, 1000000000))

	// Fund local accounts
	for _, accountStr := range args.accountsToFund {
		handleErr(app.BankKeeper.MintCoins(ctx, minttypes.ModuleName, defaultCoins))

		account, err := app.AuthKeeper.AddressCodec().StringToBytes(accountStr)
		handleErr(err)

		handleErr(app.BankKeeper.SendCoinsFromModuleToAccount(ctx, minttypes.ModuleName, account, defaultCoins))
	}

	return app
}

// parse the input flags and returns valArgs
func getCommandArgs(appOpts servertypes.AppOptions) (valArgs, error) {
	args := valArgs{}

	newValAddr, ok := appOpts.Get(server.KeyNewValAddr).(bytes.HexBytes)
	if !ok {
		return args, errors.New("newValAddr is not of type bytes.HexBytes")
	}
	args.newValAddr = newValAddr
	newValPubKey, ok := appOpts.Get(server.KeyUserPubKey).(crypto.PubKey)
	if !ok {
		return args, errors.New("newValPubKey is not of type crypto.PubKey")
	}
	args.newValPubKey = newValPubKey
	newOperatorAddress, ok := appOpts.Get(server.KeyNewOpAddr).(string)
	if !ok {
		return args, errors.New("newOperatorAddress is not of type string")
	}
	args.newOperatorAddress = newOperatorAddress
	upgradeToTrigger, ok := appOpts.Get(server.KeyTriggerTestnetUpgrade).(string)
	if !ok {
		return args, errors.New("upgradeToTrigger is not of type string")
	}
	args.upgradeToTrigger = upgradeToTrigger

	// parsing  and set accounts to fund
	accountsString := fmt.Sprintf("%v", appOpts.Get(flagAccountsToFund))
	if accountsString != "" && accountsString != "<nil>" {
		args.accountsToFund = strings.Split(accountsString, ",")
	}

	// home dir
	homeDir, ok := appOpts.Get(flags.FlagHome).(string)
	if !ok || homeDir == "" {
		return args, errors.New("invalid home dir")
	}
	args.homeDir = homeDir

	return args, nil
}

// handleErr prints the error and exits the program if the error is not nil
func handleErr(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}

// ============================================================================
// Multi-Node Testnet
// ============================================================================

var (
	flagNodeDirPrefix         = "node-dir-prefix"
	flagPorts                 = "list-ports"
	flagNumValidators         = "v"
	flagOutputDir             = "output-dir"
	flagValidatorsStakeAmount = "validators-stake-amount"
	flagStartingIPAddress     = "starting-ip-address"
)

const nodeDirPerm = 0o755

type initArgs struct {
	algo                   string
	chainID                string
	keyringBackend         string
	minGasPrices           string
	nodeDirPrefix          string
	numValidators          int
	outputDir              string
	startingIPAddress      string
	validatorsStakesAmount map[int]sdk.Coin
	ports                  map[int]string
}

// newTestnetMultiNodeCmd returns a cmd to initialize all files for tendermint testnet and application
func newTestnetMultiNodeCmd(mbm module.BasicManager, genBalIterator banktypes.GenesisBalancesIterator) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "multi-node",
		Short: "Initialize config directories & files for a multi-validator testnet running locally via separate processes (e.g. Docker Compose or similar)",
		Long: `multi-node will setup "v" number of directories and populate each with
necessary files (private validator, genesis, config, etc.) for running "v" validator nodes.

Booting up a network with these validator folders is intended to be used with Docker Compose,
or a similar setup where each node has a manually configurable IP address.

Note, strict routability for addresses is turned off in the config file.

Example:
	tokenchaind multi-node --v 4 --output-dir ./.testnets --validators-stake-amount 1000000,200000,300000,400000 --list-ports 47222,50434,52851,44210
	`,
		RunE: func(cmd *cobra.Command, _ []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}

			serverCtx := server.GetServerContextFromCmd(cmd)
			config := serverCtx.Config

			args := initArgs{}
			args.outputDir, _ = cmd.Flags().GetString(flagOutputDir)
			args.keyringBackend, _ = cmd.Flags().GetString(flags.FlagKeyringBackend)
			args.chainID, _ = cmd.Flags().GetString(flags.FlagChainID)
			args.minGasPrices, _ = cmd.Flags().GetString(server.FlagMinGasPrices)
			args.nodeDirPrefix, _ = cmd.Flags().GetString(flagNodeDirPrefix)
			args.startingIPAddress, _ = cmd.Flags().GetString(flagStartingIPAddress)
			args.numValidators, _ = cmd.Flags().GetInt(flagNumValidators)
			args.algo, _ = cmd.Flags().GetString(flags.FlagKeyType)

			args.ports = map[int]string{}
			args.validatorsStakesAmount = make(map[int]sdk.Coin)
			top := 0
			// If the flag string is invalid, the amount will default to 100000000.
			if s, err := cmd.Flags().GetString(flagValidatorsStakeAmount); err == nil {
				for _, amount := range strings.Split(s, ",") {
					a, ok := math.NewIntFromString(amount)
					if !ok {
						continue
					}
					args.validatorsStakesAmount[top] = sdk.NewCoin(sdk.DefaultBondDenom, a)
					top += 1
				}

			}
			top = 0
			if s, err := cmd.Flags().GetString(flagPorts); err == nil {
				if s == "" {
					for i := 0; i < args.numValidators; i++ {
						args.ports[top] = strconv.Itoa(26657 - 3*i)
						top += 1
					}
				} else {
					for _, port := range strings.Split(s, ",") {
						args.ports[top] = port
						top += 1
					}
				}
			}

			return initTestnetFiles(clientCtx, cmd, config, mbm, genBalIterator, args)
		},
	}

	addTestnetFlagsToCmd(cmd)
	cmd.Flags().String(flagPorts, "", "Ports of nodes (default 26657,26654,26651,26648.. )")
	cmd.Flags().String(flagNodeDirPrefix, "validator", "Prefix the directory name for each node with (node results in node0, node1, ...)")
	cmd.Flags().String(flagValidatorsStakeAmount, "100000000,100000000,100000000,100000000", "Amount of stake for each validator")
	cmd.Flags().String(flagStartingIPAddress, "localhost", "Starting IP address (192.168.0.1 results in persistent peers list ID0@192.168.0.1:46656, ID1@192.168.0.2:46656, ...)")
	cmd.Flags().String(flags.FlagKeyringBackend, "test", "Select keyring's backend (os|file|test)")

	return cmd
}

func addTestnetFlagsToCmd(cmd *cobra.Command) {
	cmd.Flags().Int(flagNumValidators, 4, "Number of validators to initialize the testnet with")
	cmd.Flags().StringP(flagOutputDir, "o", "./.testnets", "Directory to store initialization data for the testnet")
	cmd.Flags().String(flags.FlagChainID, "", "genesis file chain-id, if left blank will be randomly created")
	cmd.Flags().String(server.FlagMinGasPrices, fmt.Sprintf("0.0001%s", sdk.DefaultBondDenom), "Minimum gas prices to accept for transactions; All fees in a tx must meet this minimum (e.g. 0.01photino,0.001stake)")
	cmd.Flags().String(flags.FlagKeyType, string(hd.Secp256k1Type), "Key signing algorithm to generate keys for")

	// support old flags name for backwards compatibility
	cmd.Flags().SetNormalizeFunc(func(f *pflag.FlagSet, name string) pflag.NormalizedName {
		if name == "algo" {
			name = flags.FlagKeyType
		}

		return pflag.NormalizedName(name)
	})
}

// initTestnetFiles initializes testnet files for a testnet to be run in a separate process
func initTestnetFiles(
	clientCtx client.Context,
	cmd *cobra.Command,
	nodeConfig *cmtconfig.Config,
	mbm module.BasicManager,
	genBalIterator banktypes.GenesisBalancesIterator,
	args initArgs,
) error {
	if args.chainID == "" {
		args.chainID = "chain-" + generateRandomString(6)
	}
	nodeIDs := make([]string, args.numValidators)
	valPubKeys := make([]cryptotypes.PubKey, args.numValidators)

	appConfig := serverconfig.DefaultConfig()
	appConfig.MinGasPrices = args.minGasPrices
	appConfig.API.Enable = false
	appConfig.BaseConfig.MinGasPrices = "0.0001" + sdk.DefaultBondDenom
	appConfig.Telemetry.EnableHostnameLabel = false
	appConfig.Telemetry.Enabled = false
	appConfig.Telemetry.PrometheusRetentionTime = 0

	var (
		genAccounts     []authtypes.GenesisAccount
		genBalances     []banktypes.Balance
		genFiles        []string
		persistentPeers string
		gentxsFiles     []string
	)

	inBuf := bufio.NewReader(cmd.InOrStdin())
	for i := 0; i < args.numValidators; i++ {
		nodeDirName := fmt.Sprintf("%s%d", args.nodeDirPrefix, i)
		nodeDir := filepath.Join(args.outputDir, nodeDirName)
		gentxsDir := filepath.Join(args.outputDir, nodeDirName, "config", "gentx")

		nodeConfig.SetRoot(nodeDir)
		nodeConfig.Moniker = nodeDirName
		nodeConfig.RPC.ListenAddress = "tcp://0.0.0.0:" + args.ports[i]

		var err error
		if err := os.MkdirAll(filepath.Join(nodeDir, "config"), nodeDirPerm); err != nil {
			_ = os.RemoveAll(args.outputDir)
			return err
		}

		nodeIDs[i], valPubKeys[i], err = genutil.InitializeNodeValidatorFiles(nodeConfig)
		if err != nil {
			_ = os.RemoveAll(args.outputDir)
			return err
		}

		memo := fmt.Sprintf("%s@%s:"+strconv.Itoa(26656-3*i), nodeIDs[i], args.startingIPAddress)

		if persistentPeers == "" {
			persistentPeers = memo
		} else {
			persistentPeers = persistentPeers + "," + memo
		}

		genFiles = append(genFiles, nodeConfig.GenesisFile())

		kb, err := keyring.New(sdk.KeyringServiceName(), args.keyringBackend, nodeDir, inBuf, clientCtx.Codec)
		if err != nil {
			return err
		}

		keyringAlgos, _ := kb.SupportedAlgorithms()
		algo, err := keyring.NewSigningAlgoFromString(args.algo, keyringAlgos)
		if err != nil {
			return err
		}

		addr, secret, err := testutil.GenerateSaveCoinKey(kb, nodeDirName, "", true, algo)
		if err != nil {
			_ = os.RemoveAll(args.outputDir)
			return err
		}

		info := map[string]string{"secret": secret}

		cliPrint, err := json.Marshal(info)
		if err != nil {
			return err
		}

		// save private key seed words
		file := filepath.Join(nodeDir, fmt.Sprintf("%v.json", "key_seed"))
		if err := writeFile(file, nodeDir, cliPrint); err != nil {
			return err
		}

		accTokens := sdk.TokensFromConsensusPower(1000, sdk.DefaultPowerReduction)
		accStakingTokens := sdk.TokensFromConsensusPower(500, sdk.DefaultPowerReduction)
		coins := sdk.Coins{
			sdk.NewCoin("testtoken", accTokens),
			sdk.NewCoin(sdk.DefaultBondDenom, accStakingTokens),
		}

		genBalances = append(genBalances, banktypes.Balance{Address: addr.String(), Coins: coins.Sort()})
		genAccounts = append(genAccounts, authtypes.NewBaseAccount(addr, nil, 0, 0))

		var valTokens sdk.Coin
		valTokens, ok := args.validatorsStakesAmount[i]
		if !ok {
			valTokens = sdk.NewCoin(sdk.DefaultBondDenom, sdk.TokensFromConsensusPower(100, sdk.DefaultPowerReduction))
		}
		createValMsg, err := stakingtypes.NewMsgCreateValidator(
			sdk.ValAddress(addr).String(),
			valPubKeys[i],
			valTokens,
			stakingtypes.NewDescription(nodeDirName, "", "", "", ""),
			stakingtypes.NewCommissionRates(math.LegacyOneDec(), math.LegacyOneDec(), math.LegacyOneDec()),
			math.OneInt(),
		)
		if err != nil {
			return err
		}

		txBuilder := clientCtx.TxConfig.NewTxBuilder()
		if err := txBuilder.SetMsgs(createValMsg); err != nil {
			return err
		}

		txBuilder.SetMemo(memo)

		txFactory := tx.Factory{}
		txFactory = txFactory.
			WithChainID(args.chainID).
			WithMemo(memo).
			WithKeybase(kb).
			WithTxConfig(clientCtx.TxConfig)

		if err := tx.Sign(cmd.Context(), txFactory, nodeDirName, txBuilder, true); err != nil {
			return err
		}

		txBz, err := clientCtx.TxConfig.TxJSONEncoder()(txBuilder.GetTx())
		if err != nil {
			return err
		}
		file = filepath.Join(gentxsDir, fmt.Sprintf("%v.json", "gentx-"+nodeIDs[i]))
		gentxsFiles = append(gentxsFiles, file)
		if err := writeFile(file, gentxsDir, txBz); err != nil {
			return err
		}

		appConfig.GRPC.Address = args.startingIPAddress + ":" + strconv.Itoa(9090-2*i)
		appConfig.API.Address = "tcp://localhost:" + strconv.Itoa(1317-i)
		serverconfig.WriteConfigFile(filepath.Join(nodeDir, "config", "app.toml"), appConfig)
	}

	if err := initGenFiles(clientCtx, mbm, args.chainID, genAccounts, genBalances, genFiles, args.numValidators); err != nil {
		return err
	}
	// copy gentx file
	for i := 0; i < args.numValidators; i++ {
		for _, file := range gentxsFiles {
			nodeDirName := fmt.Sprintf("%s%d", args.nodeDirPrefix, i)
			nodeDir := filepath.Join(args.outputDir, nodeDirName)
			gentxsDir := filepath.Join(nodeDir, "config", "gentx")

			yes, err := isSubDir(file, gentxsDir)
			if err != nil || yes {
				continue
			}
			_, err = copyFile(file, gentxsDir)
			if err != nil {
				return err
			}
		}
	}
	err := collectGenFiles(
		clientCtx, nodeConfig, nodeIDs, valPubKeys,
		genBalIterator,
		clientCtx.TxConfig.SigningContext().ValidatorAddressCodec(),
		persistentPeers, args,
	)
	if err != nil {
		return err
	}

	cmd.PrintErrf("Successfully initialized %d node directories\n", args.numValidators)
	return nil
}

func writeFile(file, dir string, contents []byte) error {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return fmt.Errorf("could not create directory %q: %w", dir, err)
	}

	if err := os.WriteFile(file, contents, 0o644); err != nil {
		return err
	}

	return nil
}

func copyFile(src, dstDir string) (int64, error) {
	// Extract the file name from the source path
	fileName := filepath.Base(src)

	// Create the full destination path (directory + file name)
	dst := filepath.Join(dstDir, fileName)

	// Open the source file
	sourceFile, err := os.Open(src)
	if err != nil {
		return 0, err
	}
	defer sourceFile.Close()

	// Create the destination file
	destinationFile, err := os.Create(dst)
	if err != nil {
		return 0, err
	}
	defer destinationFile.Close()

	// Copy content from the source file to the destination file
	bytesCopied, err := io.Copy(destinationFile, sourceFile)
	if err != nil {
		return 0, err
	}

	// Ensure the content is written to the destination file
	err = destinationFile.Sync()
	if err != nil {
		return 0, err
	}

	return bytesCopied, nil
}

// isSubDir checks if dstDir is a parent directory of src
func isSubDir(src, dstDir string) (bool, error) {
	// Get the absolute path of src and dstDir
	absSrc, err := filepath.Abs(src)
	if err != nil {
		return false, err
	}
	absDstDir, err := filepath.Abs(dstDir)
	if err != nil {
		return false, err
	}

	// Check if absSrc is within absDstDir
	relativePath, err := filepath.Rel(absDstDir, absSrc)
	if err != nil {
		return false, err
	}

	// If the relative path doesn't go up the directory tree (doesn't contain ".."), it is inside dstDir
	isInside := !strings.HasPrefix(relativePath, "..") && !filepath.IsAbs(relativePath)
	return isInside, nil
}

// generateRandomString generates a random string of the specified length.
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyz0123456789"
	var seededRand *rand.Rand = rand.New(rand.NewSource(time.Now().UnixNano()))

	b := make([]byte, length)
	for i := range b {
		b[i] = charset[seededRand.Intn(len(charset))]
	}
	return string(b)
}
