package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	_ "github.com/mattn/go-sqlite3"
	"github.com/spf13/cobra"
)

// App represents the accounting application
type App struct {
	config *Config
	db     *sql.DB
}

// Config holds accounting configuration
type Config struct {
	DatabasePath string
	Port         string
	Host         string
	APIKey       string
}

// NewApp creates a new accounting application instance
func NewApp(ctx context.Context) (*App, error) {
	config := &Config{
		DatabasePath: "./accounting.db",
		Port:         "8080",
		Host:         "localhost",
		APIKey:       "default-api-key",
	}

	// Initialize database
	db, err := initDatabase(config.DatabasePath)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize database: %w", err)
	}

	return &App{
		config: config,
		db:     db,
	}, nil
}

// initDatabase initializes the SQLite database
func initDatabase(path string) (*sql.DB, error) {
	db, err := sql.Open("sqlite3", path)
	if err != nil {
		return nil, err
	}

	// Create tables
	createTables := `
	CREATE TABLE IF NOT EXISTS invoices (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		invoice_number TEXT UNIQUE NOT NULL,
		amount DECIMAL(10,2) NOT NULL,
		currency TEXT DEFAULT 'USD',
		status TEXT DEFAULT 'pending',
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
	CREATE TABLE IF NOT EXISTS transactions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		invoice_id INTEGER,
		amount DECIMAL(10,2) NOT NULL,
		transaction_type TEXT NOT NULL,
		description TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (invoice_id) REFERENCES invoices (id)
	);
	
	CREATE TABLE IF NOT EXISTS validators (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		validator_address TEXT UNIQUE NOT NULL,
		commission_rate DECIMAL(5,4) NOT NULL,
		status TEXT DEFAULT 'active',
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	`

	if _, err := db.Exec(createTables); err != nil {
		return nil, fmt.Errorf("failed to create tables: %w", err)
	}

	return db, nil
}

// Start starts the accounting service
func (a *App) Start(ctx context.Context) error {
	log.Println("Starting accounting service...")
	
	// Set up signal handling
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Start the HTTP server
	go func() {
		if err := a.startHTTPServer(); err != nil {
			log.Printf("HTTP server error: %v", err)
		}
	}()

	// Wait for context cancellation or signal
	select {
	case <-ctx.Done():
		log.Println("Accounting service shutting down...")
		return ctx.Err()
	case sig := <-sigChan:
		log.Printf("Received signal %v, shutting down accounting service...", sig)
		return fmt.Errorf("received signal: %v", sig)
	}
}

// startHTTPServer starts the HTTP server for the accounting API
func (a *App) startHTTPServer() error {
	// This would contain the actual HTTP server startup logic
	// For now, we'll just log that it's running
	log.Printf("Accounting API server running on %s:%s", a.config.Host, a.config.Port)
	log.Printf("Database: %s", a.config.DatabasePath)
	
	// Keep the service running
	select {}
}

// GetConfig returns the current configuration
func (a *App) GetConfig() *Config {
	return a.config
}

// GetDB returns the database connection
func (a *App) GetDB() *sql.DB {
	return a.db
}

// Close closes the database connection
func (a *App) Close() error {
	if a.db != nil {
		return a.db.Close()
	}
	return nil
}

// RunCLI runs the accounting CLI
func RunCLI() {
	rootCmd := &cobra.Command{
		Use:   "accounting",
		Short: "Chain Rice Accounting Service",
		Long:  "A comprehensive accounting system for Chain Rice blockchain",
	}

	// Add subcommands
	rootCmd.AddCommand(createInvoiceCmd())
	rootCmd.AddCommand(listInvoicesCmd())
	rootCmd.AddCommand(createTransactionCmd())
	rootCmd.AddCommand(listTransactionsCmd())
	rootCmd.AddCommand(createValidatorCmd())
	rootCmd.AddCommand(listValidatorsCmd())

	// Execute the command
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

// CLI Commands
func createInvoiceCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "create-invoice [invoice-number] [amount]",
		Short: "Create a new invoice",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("Creating invoice %s with amount %s\n", args[0], args[1])
		},
	}
}

func listInvoicesCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "list-invoices",
		Short: "List all invoices",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Listing all invoices...")
		},
	}
}

func createTransactionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "create-transaction [amount] [type] [description]",
		Short: "Create a new transaction",
		Args:  cobra.ExactArgs(3),
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("Creating transaction: %s %s (%s)\n", args[0], args[1], args[2])
		},
	}
}

func listTransactionsCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "list-transactions",
		Short: "List all transactions",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Listing all transactions...")
		},
	}
}

func createValidatorCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "create-validator [address] [commission-rate]",
		Short: "Create a new validator",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("Creating validator %s with commission %s\n", args[0], args[1])
		},
	}
}

func listValidatorsCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "list-validators",
		Short: "List all validators",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Listing all validators...")
		},
	}
}

// Export functions for external use
func NewAccountingApp(ctx context.Context) (*App, error) {
	return NewApp(ctx)
}

func GetDefaultConfig() *Config {
	return &Config{
		DatabasePath: "./accounting.db",
		Port:         "8080",
		Host:         "localhost",
		APIKey:       "default-api-key",
	}
}
