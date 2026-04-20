package token

import (
	"cosmossdk.io/depinject"
	"cosmossdk.io/depinject/appconfig"
)

// LoadAppConfig returns depinject options from YAML/JSON app config (runtime + module providers).
// Wire module-specific providers (keeper, msg/query servers) alongside cosmossdk.io/runtime.
func LoadAppConfigYAML(bz []byte) depinject.Config {
	return appconfig.LoadYAML(bz)
}

// LoadAppConfigJSON is the JSON equivalent of LoadAppConfigYAML.
func LoadAppConfigJSON(bz []byte) depinject.Config {
	return appconfig.LoadJSON(bz)
}
