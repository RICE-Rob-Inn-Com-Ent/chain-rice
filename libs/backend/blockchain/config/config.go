package config

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/viper"
	tmconfig "github.com/cometbft/cometbft/config"

	"github.com/rice-dev/backend/blockchain/app"
)

const (
	// AppConfigFileName defines the config file name
	AppConfigFileName = "app.toml"
)

// AppConfig defines the configuration for the application
type AppConfig struct {
	*tmconfig.Config
	App app.Config
}

// ReadFromClientConfig reads values from client config and sets them in AppConfig
func ReadFromClientConfig(v *viper.Viper) (*AppConfig, error) {
	conf := DefaultConfig()
	
	// read from the app config file
	appConfigPath := filepath.Join(v.GetString("home"), "config", AppConfigFileName)
	if _, err := os.Stat(appConfigPath); err == nil {
		viper.SetConfigFile(appConfigPath)
		if err := viper.ReadInConfig(); err != nil {
			return nil, fmt.Errorf("error reading config file: %w", err)
		}
		
		if err := viper.Unmarshal(&conf.App); err != nil {
			return nil, fmt.Errorf("error unmarshaling config: %w", err)
		}
	}

	return conf, nil
}

// DefaultConfig returns a default configuration for the application
func DefaultConfig() *AppConfig {
	return &AppConfig{
		Config: tmconfig.DefaultConfig(),
		App:    app.DefaultConfig(),
	}
}

// AppConfig returns the application configuration
func (c *AppConfig) AppConfig() app.Config {
	return c.App
}

// InitTendermintConfig returns the default Tendermint configuration
func InitTendermintConfig() *tmconfig.Config {
	return tmconfig.DefaultConfig()
}
