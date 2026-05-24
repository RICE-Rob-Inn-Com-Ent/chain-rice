package token

import (
	"cosmossdk.io/depinject"
	"cosmossdk.io/depinject/appconfig"
)

// Config holds optional node-level tuning for x/token (gas hints, limits). Not consensus state.
type Config struct {
	// MintGasLimit is a suggested gas ceiling for mint-style messages (documentation / local estimator).
	MintGasLimit uint64 `json:"mint_gas_limit" yaml:"mint_gas_limit"`
	// BurnGasLimit is a suggested gas ceiling for burn-style messages.
	BurnGasLimit uint64 `json:"burn_gas_limit" yaml:"burn_gas_limit"`
	// TransferGasLimit is reserved for future P2P transfer messages.
	TransferGasLimit uint64 `json:"transfer_gas_limit" yaml:"transfer_gas_limit"`
}

// DefaultConfig returns conservative SMITH defaults for [Config].
func DefaultConfig() Config {
	return Config{
		MintGasLimit:     120_000,
		BurnGasLimit:     120_000,
		TransferGasLimit: 80_000,
	}
}

// LoadAppConfig returns depinject options from YAML/JSON app config (runtime + module providers).
// Wire module-specific providers (keeper, msg/query servers) alongside cosmossdk.io/runtime.
func LoadAppConfigYAML(bz []byte) depinject.Config {
	return appconfig.LoadYAML(bz)
}

// LoadAppConfigJSON is the JSON equivalent of LoadAppConfigYAML.
func LoadAppConfigJSON(bz []byte) depinject.Config {
	return appconfig.LoadJSON(bz)
}
