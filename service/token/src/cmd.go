package token

import (
	"github.com/spf13/cobra"
)

// RootCmd is the token chain CLI root: start, init, keys, tx, query (wired to Cosmos SDK client in full build).
func RootCmd() *cobra.Command {
	root := &cobra.Command{
		Use:   "tokenchaind",
		Short: "RICE token chain daemon and CLI",
	}
	root.AddCommand(
		cmdStart(),
		cmdInit(),
		cmdKeys(),
		cmdTx(),
		cmdQuery(),
	)
	return root
}

func cmdStart() *cobra.Command {
	return &cobra.Command{
		Use:   "start",
		Short: "Run the full node (CometBFT + Cosmos app)",
		RunE: func(cmd *cobra.Command, args []string) error {
			// Delegate to github.com/cosmos/cosmos-sdk/server.StartCmd / cometbft node.
			return nil
		},
	}
}

func cmdInit() *cobra.Command {
	return &cobra.Command{
		Use:   "init [moniker]",
		Short: "Initialize node home and genesis",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return nil
		},
	}
}

func cmdKeys() *cobra.Command {
	c := &cobra.Command{Use: "keys", Short: "Manage local keys"}
	c.AddCommand(
		&cobra.Command{Use: "add", Short: "Add key", RunE: func(*cobra.Command, []string) error { return nil }},
		&cobra.Command{Use: "list", Short: "List keys", RunE: func(*cobra.Command, []string) error { return nil }},
	)
	return c
}

func cmdTx() *cobra.Command {
	return &cobra.Command{Use: "tx", Short: "Submit transactions"}
}

func cmdQuery() *cobra.Command {
	return &cobra.Command{Use: "query", Short: "Query chain state"}
}
