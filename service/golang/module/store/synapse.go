package store

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/chainrice/rice/backend/app/services"
	_ "github.com/microsoft/go-mssqldb"
)

// SynapseDataWarehouseClient implements DataWarehouseClient for Azure
type SynapseDataWarehouseClient struct {
	db        *sql.DB
	workspace string
}

// NewSynapseDataWarehouseClient creates a new Synapse data warehouse client
func NewSynapseDataWarehouseClient(ctx context.Context, config DataWarehouseConfig) (*SynapseDataWarehouseClient, error) {
	server := config.Credentials["server"]
	user := config.Credentials["user"]
	password := config.Credentials["password"]
	database := config.Database
	if database == "" {
		database = "master"
	}

	dsn := fmt.Sprintf(
		"server=%s;user id=%s;password=%s;database=%s;encrypt=true",
		server, user, password, database,
	)

	db, err := sql.Open("sqlserver", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open Synapse connection: %w", err)
	}

	// Test connection
	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping Synapse: %w", err)
	}

	return &SynapseDataWarehouseClient{
		db:        db,
		workspace: config.Credentials["workspace"],
	}, nil
}

// Query executes a SQL query
func (c *SynapseDataWarehouseClient) Query(ctx context.Context, sql string) (Rows, error) {
	rows, err := c.db.QueryContext(ctx, sql)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %w", err)
	}

	return &SQLRowsAdapter{Rows: rows}, nil
}

// CreateTable creates a table with schema
func (c *SynapseDataWarehouseClient) CreateTable(ctx context.Context, tableID string, schema Schema) error {
	// Build CREATE TABLE statement
	createSQL := fmt.Sprintf("CREATE TABLE IF NOT EXISTS %s (", tableID)

	columns := make([]string, len(schema.Fields))
	for i, field := range schema.Fields {
		colType := mapSynapseType(field.Type)
		nullable := ""
		if field.Mode == "REQUIRED" {
			nullable = "NOT NULL"
		}
		columns[i] = fmt.Sprintf("%s %s %s", field.Name, colType, nullable)
	}

	createSQL += fmt.Sprintf("%s)", columns[0])
	if len(columns) > 1 {
		for i := 1; i < len(columns); i++ {
			createSQL = createSQL[:len(createSQL)-1] + ", " + columns[i] + ")"
		}
	}

	_, err := c.db.ExecContext(ctx, createSQL)
	if err != nil {
		return fmt.Errorf("failed to create table: %w", err)
	}

	return nil
}

// LoadData loads data from Azure Blob Storage
func (c *SynapseDataWarehouseClient) LoadData(ctx context.Context, sourceURI string, tableID string) error {
	// Synapse COPY INTO command
	copySQL := fmt.Sprintf(`
		COPY INTO %s
		FROM '%s'
		WITH (
			FILE_TYPE = 'PARQUET',
			CREDENTIAL = (IDENTITY = 'Managed Identity')
		);
	`, tableID, sourceURI)

	_, err := c.db.ExecContext(ctx, copySQL)
	if err != nil {
		return fmt.Errorf("failed to load data: %w", err)
	}

	return nil
}

// ExportData exports data to Azure Blob Storage
func (c *SynapseDataWarehouseClient) ExportData(ctx context.Context, tableID string, destURI string) error {
	// Synapse uses COPY INTO for export as well
	exportSQL := fmt.Sprintf(`
		COPY INTO '%s'
		FROM %s
		WITH (
			FILE_TYPE = 'PARQUET',
			CREDENTIAL = (IDENTITY = 'Managed Identity')
		);
	`, destURI, tableID)

	_, err := c.db.ExecContext(ctx, exportSQL)
	if err != nil {
		return fmt.Errorf("failed to export data: %w", err)
	}

	return nil
}

// GetProvider returns the cloud provider
func (c *SynapseDataWarehouseClient) GetProvider() services.CloudProvider {
	return services.CloudProviderAzure
}

// Close closes the client connection
func (c *SynapseDataWarehouseClient) Close() error {
	return c.db.Close()
}

func mapSynapseType(typ string) string {
	switch typ {
	case "STRING", "VARCHAR":
		return "VARCHAR(256)"
	case "INTEGER", "INT64":
		return "BIGINT"
	case "FLOAT", "FLOAT64":
		return "FLOAT"
	case "BOOLEAN", "BOOL":
		return "BIT"
	case "DATE":
		return "DATE"
	case "TIMESTAMP":
		return "DATETIME2"
	default:
		return "VARCHAR(256)"
	}
}
