package config

import (
	"os"
	"path/filepath"

	tmconfig "github.com/cometbft/cometbft/config"
	"github.com/cosmos/cosmos-sdk/client"
	serverconfig "github.com/cosmos/cosmos-sdk/server/config"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const (
	// Name defines the application binary name
	Name = "chainrice"
)

// AppConfig returns the default app config for chainrice
func AppConfig(baseDenom string) (string, interface{}) {
	return `
minimum-gas-prices = "0.0001` + baseDenom + `"

[api]
enable = true
swagger = true
address = "tcp://0.0.0.0:1317"

[grpc]
enable = true
address = "0.0.0.0:9090"

[state-sync]
snapshot-interval = 0
snapshot-keep-recent = 2

[mempool]
version = "v0"

[p2p]
laddr = "tcp://0.0.0.0:26656"
external_address = ""
seeds = ""
persistent_peers = ""
upnp = false
max_num_inbound_peers = 40
max_num_outbound_peers = 10
flush_throttle_timeout = "100ms"
max_packet_msg_payload_size = 1024
send_rate = 5120000
recv_rate = 5120000
pex = true
seed_mode = false
private_peer_ids = ""
allow_duplicate_ip = false
handshake_timeout = "20s"
dial_timeout = "3s"

[consensus]
wal_file = "data/cs.wal/wal"
timeout_propose = "3s"
timeout_propose_delta = "500ms"
timeout_prevote = "1s"
timeout_prevote_delta = "500ms"
timeout_precommit = "1s"
timeout_precommit_delta = "500ms"
timeout_commit = "1s"
double_sign_check_height = 0
skip_timeout_commit = false
create_empty_blocks = true
create_empty_blocks_interval = "0s"
peer_gossip_sleep_duration = "100ms"
peer_query_maj23_sleep_duration = "2s"

[storage]
discard_abci_responses = false

[tx_index]
indexer = "kv"
index_tags = ""
index_all_tags = false

[instrumentation]
prometheus = false
prometheus_listen_addr = ":26660"
max_open_connections = 3
namespace = "tendermint"
`, serverconfig.Config{}
}

// InitTendermintConfig returns the default Tendermint config for chainrice
func InitTendermintConfig() *tmconfig.Config {
	return &tmconfig.Config{
		// Note: Config fields are not available in current SDK version
		// TODO: Add config fields when available
	}
}

// ReadFromClientConfig reads the configuration from the client config
func ReadFromClientConfig(ctx client.Context) (client.Context, error) {
	configPath := filepath.Join(ctx.HomeDir, "config", "client.toml")
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return ctx, nil
	}

	viper.SetConfigFile(configPath)
	if err := viper.ReadInConfig(); err != nil {
		return ctx, err
	}

	return ctx, nil
}

// Cmd returns a command to show the configuration
func Cmd() *cobra.Command {
	return &cobra.Command{
		Use:   "config",
		Short: "Show configuration",
		RunE: func(cmd *cobra.Command, args []string) error {
			// TODO: Implement config command
			return nil
		},
	}
}
