package store

import (
	"context"
	"log"
)

// DataWarehouseKeeper manages data warehouse connections and operations
type DataWarehouseKeeper struct {
	client DataWarehouseClient
}

// NewDataWarehouseKeeper creates a new data warehouse keeper
func NewDataWarehouseKeeper(client DataWarehouseClient) *DataWarehouseKeeper {
	return &DataWarehouseKeeper{
		client: client,
	}
}

// GetClient returns the underlying data warehouse client
func (k *DataWarehouseKeeper) GetClient() DataWarehouseClient {
	return k.client
}

// Query executes a SQL query
func (k *DataWarehouseKeeper) Query(ctx context.Context, sql string) (Rows, error) {
	return k.client.Query(ctx, sql)
}

// CreateTable creates a table with schema
func (k *DataWarehouseKeeper) CreateTable(ctx context.Context, tableID string, schema Schema) error {
	return k.client.CreateTable(ctx, tableID, schema)
}

// LoadData loads data from storage
func (k *DataWarehouseKeeper) LoadData(ctx context.Context, sourceURI string, tableID string) error {
	return k.client.LoadData(ctx, sourceURI, tableID)
}

// ExportData exports data to storage
func (k *DataWarehouseKeeper) ExportData(ctx context.Context, tableID string, destURI string) error {
	return k.client.ExportData(ctx, tableID, destURI)
}

// GetProvider returns the cloud provider
func (k *DataWarehouseKeeper) GetProvider() interface{} {
	return k.client.GetProvider()
}

// HealthCheck performs a health check
func (k *DataWarehouseKeeper) HealthCheck(ctx context.Context) error {
	// Execute a simple query to check connectivity
	_, err := k.client.Query(ctx, "SELECT 1")
	return err
}

// Close closes the connection
func (k *DataWarehouseKeeper) Close() error {
	log.Println("Closing data warehouse connection")
	return k.client.Close()
}
