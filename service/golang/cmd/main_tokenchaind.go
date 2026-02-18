//go:build tokenchaind

package cmd

import (
	"fmt"
	"os"

	clienthelpers "cosmossdk.io/client/v2/helpers"
	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/chainrice/rice/backend/app/token"
)

func main() {
	rootCmd := token.NewTokenchaindRootCmd()
	if err := svrcmd.Execute(rootCmd, clienthelpers.EnvPrefix, token.DefaultNodeHome); err != nil {
		fmt.Fprintln(rootCmd.OutOrStderr(), err)
		os.Exit(1)
	}
}
