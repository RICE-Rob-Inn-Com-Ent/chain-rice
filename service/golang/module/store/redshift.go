package store

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/chainrice/rice/backend/app/services"
	_ "github.com/lib/pq"
)

// RedshiftDataWarehouseClient implements DataWarehouseClient for AWS
type RedshiftDataWarehouseClient struct {
	db        *sql.DB
	clusterID string
	region    string
}

// NewRedshiftDataWarehouseClient creates a new Redshift data warehouse client
func NewRedshiftDataWarehouseClient(ctx context.Context, config DataWarehouseConfig) (*RedshiftDataWarehouseClient, error) {
	host := config.Credentials["host"]
	port := config.Credentials["port"]
	if port == "" {
		port = "5439"
	}
	user := config.Credentials["user"]
	password := config.Credentials["password"]
	database := config.Database
	if database == "" {
		database = "dev"
	}

	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=require",
		host, port, user, password, database,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open Redshift connection: %w", err)
	}

	// Test connection
	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping Redshift: %w", err)
	}

	return &RedshiftDataWarehouseClient{
		db:        db,
		clusterID: config.Credentials["cluster_id"],
		region:    config.Region,
	}, nil
}

// Query executes a SQL query
func (c *RedshiftDataWarehouseClient) Query(ctx context.Context, sql string) (Rows, error) {
	rows, err := c.db.QueryContext(ctx, sql)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %w", err)
	}

	return &SQLRowsAdapter{Rows: rows}, nil
}

// CreateTable creates a table with schema
func (c *RedshiftDataWarehouseClient) CreateTable(ctx context.Context, tableID string, schema Schema) error {
	// Build CREATE TABLE statement
	createSQL := fmt.Sprintf("CREATE TABLE IF NOT EXISTS %s (", tableID)

	columns := make([]string, len(schema.Fields))
	for i, field := range schema.Fields {
		colType := mapRedshiftType(field.Type)
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

// LoadData loads data from S3
func (c *RedshiftDataWarehouseClient) LoadData(ctx context.Context, sourceURI string, tableID string) error {
	// Redshift COPY command from S3
	accessKey := c.db.Stats().OpenConnections // Placeholder - should come from config
	secretKey := ""                            // Placeholder - should come from config

	copySQL := fmt.Sprintf(`
		COPY %s
		FROM '%s'
		CREDENTIALS 'aws_access_key_id=%s;aws_secret_access_key=%s'
		FORMAT AS PARQUET;
	`, tableID, sourceURI, accessKey, secretKey)

	_, err := c.db.ExecContext(ctx, copySQL)
	if err != nil {
		return fmt.Errorf("failed to load data: %w", err)
	}

	return nil
}

// ExportData exports data to S3
func (c *RedshiftDataWarehouseClient) ExportData(ctx context.Context, tableID string, destURI string) error {
	// Redshift UNLOAD command to S3
	accessKey := "" // Placeholder - should come from config
	secretKey := "" // Placeholder - should come from config

	unloadSQL := fmt.Sprintf(`
		UNLOAD ('SELECT * FROM %s')
		TO '%s'
		CREDENTIALS 'aws_access_key_id=%s;aws_secret_access_key=%s'
		FORMAT PARQUET;
	`, tableID, destURI, accessKey, secretKey)

	_, err := c.db.ExecContext(ctx, unloadSQL)
	if err != nil {
		return fmt.Errorf("failed to export data: %w", err)
	}

	return nil
}

// GetProvider returns the cloud provider
func (c *RedshiftDataWarehouseClient) GetProvider() services.CloudProvider {
	return services.CloudProviderAWS
}

// Close closes the client connection
func (c *RedshiftDataWarehouseClient) Close() error {
	return c.db.Close()
}

func mapRedshiftType(typ string) string {
	switch typ {
	case "STRING", "VARCHAR":
		return "VARCHAR(256)"
	case "INTEGER", "INT64":
		return "BIGINT"
	case "FLOAT", "FLOAT64":
		return "DOUBLE PRECISION"
	case "BOOLEAN", "BOOL":
		return "BOOLEAN"
	case "DATE":
		return "DATE"
	case "TIMESTAMP":
		return "TIMESTAMP"
	default:
		return "VARCHAR(256)"
	}
}
