package token

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/spf13/cobra"
)

// GRPC query method paths for x/token (align with generated protos when available).
const (
	GRPCQueryBalance     = "/rice.token.v1.Query/Balance"
	GRPCQueryAllBalances = "/rice.token.v1.Query/AllBalances"
	GRPCQueryTotalSupply = "/rice.token.v1.Query/TotalSupply"
	GRPCQueryParams      = "/rice.token.v1.Query/Params"
)

// RootCmd is the token chain CLI root: start, init, keys, tx, query.
func RootCmd() *cobra.Command {
	root := &cobra.Command{
		Use:   "tokenchaind",
		Short: "RICE token chain daemon and CLI",
	}
	tx := &cobra.Command{Use: "tx", Short: "Transactions"}
	tx.AddCommand(GetTxCmd())
	q := &cobra.Command{Use: "query", Short: "Queries"}
	q.AddCommand(GetQueryCmd())

	root.AddCommand(
		cmdStart(),
		cmdInit(),
		cmdKeys(),
		tx,
		q,
	)
	return root
}

func cmdStart() *cobra.Command {
	return &cobra.Command{
		Use:   "start",
		Short: "Run the full node (CometBFT + Cosmos app)",
		RunE: func(cmd *cobra.Command, args []string) error {
			return fmt.Errorf("tokenchaind: compose with cosmossdk.io/server StartCmd in the app binary")
		},
	}
}

func cmdInit() *cobra.Command {
	return &cobra.Command{
		Use:   "init [moniker]",
		Short: "Initialize node home and genesis",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return fmt.Errorf("tokenchaind: compose with genutil InitCmd in the app binary")
		},
	}
}

func cmdKeys() *cobra.Command {
	c := &cobra.Command{Use: "keys", Short: "Manage local keys"}
	c.AddCommand(
		&cobra.Command{Use: "add", Short: "Add key", RunE: func(*cobra.Command, []string) error {
			return fmt.Errorf("keys: use cosmos-sdk keys CLI in the app binary")
		}},
		&cobra.Command{Use: "list", Short: "List keys", RunE: func(*cobra.Command, []string) error {
			return fmt.Errorf("keys: use cosmos-sdk keys CLI in the app binary")
		}},
	)
	return c
}

// GetTxCmd returns cobra commands for x/token transactions (library + .rice shell).
// Compose into the app root with: rootTx.AddCommand(token.GetTxCmd()).
func GetTxCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        ModuleName,
		Short:                      "x/token transactions",
		DisableFlagParsing:         false,
		SuggestionsMinimumDistance: 2,
	}
	cmd.AddCommand(
		getTxSendCmd(),
		getTxMintCmd(),
		getTxBurnCmd(),
	)
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func getTxSendCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "send [from] [to] [amount]",
		Short: "Send native x/token units (MsgSend)",
		Args:  cobra.ExactArgs(3),
		RunE: func(cmd *cobra.Command, args []string) error {
			if _, err := client.GetClientTxContext(cmd); err != nil {
				return err
			}
			msg := &MsgSend{FromAddress: args[0], ToAddress: args[1], Amount: args[2]}
			if err := msg.ValidateBasic(); err != nil {
				return err
			}
			bz, err := json.Marshal(msg)
			if err != nil {
				return err
			}
			_, _ = fmt.Fprintf(cmd.OutOrStdout(), "MsgSend (validated JSON draft):\n%s\n", string(bz))
			_, _ = fmt.Fprintln(cmd.ErrOrStderr(), "next: sign/broadcast MsgSend from the rice app binary (tx factory + baseapp)")
			return nil
		},
	}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func getTxMintCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "mint [recipient] [amount]",
		Short: "Mint to recipient (MsgMint; authority / gov only on-chain)",
		Args:  cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			if _, err := client.GetClientTxContext(cmd); err != nil {
				return err
			}
			msg := &MsgMint{Recipient: args[0], Amount: args[1]}
			if err := msg.ValidateBasic(); err != nil {
				return err
			}
			bz, err := json.Marshal(msg)
			if err != nil {
				return err
			}
			_, _ = fmt.Fprintf(cmd.OutOrStdout(), "MsgMint (validated JSON draft):\n%s\n", string(bz))
			_, _ = fmt.Fprintln(cmd.ErrOrStderr(), "next: sign/broadcast MsgMint from the rice app binary")
			return nil
		},
	}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func getTxBurnCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "burn [from] [amount]",
		Short: "Burn from account (MsgBurn)",
		Args:  cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			if _, err := client.GetClientTxContext(cmd); err != nil {
				return err
			}
			msg := &MsgBurn{FromAddress: args[0], Amount: args[1]}
			if err := msg.ValidateBasic(); err != nil {
				return err
			}
			bz, err := json.Marshal(msg)
			if err != nil {
				return err
			}
			_, _ = fmt.Fprintf(cmd.OutOrStdout(), "MsgBurn (validated JSON draft):\n%s\n", string(bz))
			_, _ = fmt.Fprintln(cmd.ErrOrStderr(), "next: sign/broadcast MsgBurn from the rice app binary")
			return nil
		},
	}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

// GetQueryCmd returns cobra commands for x/token queries (library + .rice shell).
// Compose into the app query root with: rootQuery.AddCommand(token.GetQueryCmd()).
func GetQueryCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   ModuleName,
		Short: "Query x/token state",
	}
	cmd.AddCommand(
		getQueryBalanceCmd(),
		getQueryAllBalancesCmd(),
		getQueryTotalSupplyCmd(),
		getQueryParamsCmd(),
	)
	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}

func getQueryBalanceCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "balance [address]",
		Short: "Account balance for the native mint denom",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			req := &QueryBalanceRequest{Address: args[0]}
			return printQueryDraft(cmd, GRPCQueryBalance, req)
		},
	}
}

func getQueryAllBalancesCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "all-balances [limit]",
		Short: "Non-zero balances up to limit (default 256)",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			var limit uint64 = DefaultAllBalancesLimit
			if len(args) == 1 {
				u, err := strconv.ParseUint(args[0], 10, 64)
				if err != nil {
					return err
				}
				limit = u
			}
			req := &QueryAllBalancesRequest{Limit: limit}
			return printQueryDraft(cmd, GRPCQueryAllBalances, req)
		},
	}
}

func getQueryTotalSupplyCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "total-supply",
		Short: "Total supply of the native mint denom",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			req := &QueryTotalSupplyRequest{}
			return printQueryDraft(cmd, GRPCQueryTotalSupply, req)
		},
	}
}

func getQueryParamsCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "params",
		Short: "x/token module parameters",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			req := &QueryParamsRequest{}
			return printQueryDraft(cmd, GRPCQueryParams, req)
		},
	}
}

func printQueryDraft(cmd *cobra.Command, grpcPath string, req any) error {
	if _, err := client.GetClientQueryContext(cmd); err != nil {
		return err
	}
	bz, err := json.Marshal(req)
	if err != nil {
		return err
	}
	_, err = fmt.Fprintf(cmd.OutOrStdout(), "gRPC path: %s\nrequest JSON (hand-rolled types; use with grpcurl once server exposes service):\n%s\n", grpcPath, string(bz))
	return err
}
