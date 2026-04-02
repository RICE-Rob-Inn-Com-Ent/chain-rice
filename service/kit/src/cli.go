package kit

// TODO:
// [ ] implement root cobra command:
//     RootCmd() *cobra.Command — base for all service CLIs
//     adds: --env, --log-level, --otel-endpoint flags
//     all defaults from env vars — never hardcoded
// [ ] implement version subcommand:
//     version: prints git commit, build time, Go version
//     injected at build time via -ldflags
// [ ] implement health subcommand:
//     health: checks all dependencies (DB, NATS, Temporal)
//     exits 0 if healthy, 1 if any dep unavailable
// [ ] implement migrate subcommand:
//     migrate: runs golang-migrate up/down
//     reads DB_URL from env via SOPS-decrypted .env

import (
	"os"

	"github.com/spf13/cobra"
)

// RootCommand returns a minimal [cobra.Command] with common defaults (help, completion).
func RootCommand(use, short string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   use,
		Short: short,
		CompletionOptions: cobra.CompletionOptions{
			DisableDefaultCmd: false,
		},
	}
	return cmd
}

// WithVersion sets the version string and default version template.
func WithVersion(cmd *cobra.Command, version string) *cobra.Command {
	cmd.Version = version
	cmd.SetVersionTemplate("{{.Version}}\n")
	return cmd
}

// Execute runs cmd with [os.Args] and exits the process on error (typical main()).
func Execute(cmd *cobra.Command) error {
	return cmd.Execute()
}

// MustExecute runs Execute and exits with code 1 on failure.
func MustExecute(cmd *cobra.Command) {
	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
}

// EnableCompletion adds a hidden "completion" command (bash/zsh/fish/powershell).
func EnableCompletion(root *cobra.Command) {
	root.AddCommand(&cobra.Command{
		Use:                   "completion [bash|zsh|fish|powershell]",
		Short:                 "Generate shell completion script",
		Hidden:                true,
		DisableFlagsInUseLine: true,
		ValidArgs:             []string{"bash", "zsh", "fish", "powershell"},
		Args:                  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
		RunE: func(_ *cobra.Command, args []string) error {
			switch args[0] {
			case "bash":
				return root.GenBashCompletion(os.Stdout)
			case "zsh":
				return root.GenZshCompletion(os.Stdout)
			case "fish":
				return root.GenFishCompletion(os.Stdout, true)
			case "powershell":
				return root.GenPowerShellCompletion(os.Stdout)
			default:
				return nil
			}
		},
	})
}
