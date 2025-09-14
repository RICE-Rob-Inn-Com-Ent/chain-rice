package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/server"
	"github.com/spf13/cobra"
)

// App represents the blockchain application
type App struct {
	config *Config
	client client.Context
}

// Config holds blockchain configuration
type Config struct {
	ChainID     string
	RPCAddress  string
	GRPCAddress string
	APIAddress  string
	DataDir     string
}

// NewApp creates a new blockchain application instance
func NewApp(ctx context.Context) (*App, error) {
	config := &Config{
		ChainID:     "chain-rice",
		RPCAddress:  "tcp://localhost:26657",
		GRPCAddress: "localhost:9090",
		APIAddress:  "localhost:1317",
		DataDir:     "./data",
	}

	clientCtx := client.Context{}.
		WithChainID(config.ChainID)

	return &App{
		config: config,
		client: clientCtx,
	}, nil
}

// Start starts the blockchain service
func (a *App) Start(ctx context.Context) error {
	log.Println("Starting blockchain service...")
	
	// Set up signal handling
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Start the blockchain node
	go func() {
		if err := a.startNode(); err != nil {
			log.Printf("Blockchain node error: %v", err)
		}
	}()

	// Wait for context cancellation or signal
	select {
	case <-ctx.Done():
		log.Println("Blockchain service shutting down...")
		return ctx.Err()
	case sig := <-sigChan:
		log.Printf("Received signal %v, shutting down blockchain service...", sig)
		return fmt.Errorf("received signal: %v", sig)
	}
}

// startNode starts the actual blockchain node
func (a *App) startNode() error {
	// This would contain the actual blockchain node startup logic
	// For now, we'll just log that it's running
	log.Printf("Blockchain node running on chain %s", a.config.ChainID)
	log.Printf("RPC: %s", a.config.RPCAddress)
	log.Printf("gRPC: %s", a.config.GRPCAddress)
	log.Printf("API: %s", a.config.APIAddress)
	
	// Keep the service running
	select {}
}

// GetConfig returns the current configuration
func (a *App) GetConfig() *Config {
	return a.config
}

// GetClient returns the client context
func (a *App) GetClient() client.Context {
	return a.client
}

// RunCLI runs the blockchain CLI
func RunCLI() {
	rootCmd := &cobra.Command{
		Use:   "blockchain",
		Short: "Chain Rice Blockchain Service",
		Long:  "A Cosmos SDK based blockchain for Chain Rice",
	}

	// Add subcommands
	rootCmd.AddCommand(server.StartCmd(nil, ""))
	rootCmd.AddCommand(server.ExportCmd(nil, ""))

	// Execute the command
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

// Export functions for external use
func NewBlockchainApp(ctx context.Context) (*App, error) {
	return NewApp(ctx)
}

func GetDefaultConfig() *Config {
	return &Config{
		ChainID:     "chain-rice",
		RPCAddress:  "tcp://localhost:26657",
		GRPCAddress: "localhost:9090",
		APIAddress:  "localhost:1317",
		DataDir:     "./data",
	}
}
