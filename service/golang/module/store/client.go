package store

import (
	"context"
	"database/sql"
	"fmt"
	"os"

	"github.com/chainrice/rice/backend/app/services"
)

// Rows represents query result rows (compatible with sql.Rows and bigquery.RowIterator)
// Defined here to avoid import cycle with module package
type Rows interface {
	Next() bool
	Scan(dest ...interface{}) error
	Close() error
	Err() error
}

// Schema represents table schema definition
// Defined here to avoid import cycle with module package
type Schema struct {
	Fields []SchemaField
}

// SchemaField represents a single field in a schema
type SchemaField struct {
	Name        string
	Type        string
	Mode        string // NULLABLE, REQUIRED, REPEATED
	Description string
}

// DataWarehouseClient is the unified interface for all data warehouse services
type DataWarehouseClient interface {
	// Query executes SQL query
	Query(ctx context.Context, sql string) (Rows, error)

	// CreateTable creates a table with schema
	CreateTable(ctx context.Context, tableID string, schema Schema) error

	// LoadData loads data from storage
	LoadData(ctx context.Context, sourceURI string, tableID string) error

	// ExportData exports data to storage
	ExportData(ctx context.Context, tableID string, destURI string) error

	// GetProvider returns the cloud provider
	GetProvider() services.CloudProvider

	// Close closes the client connection
	Close() error
}

// DataWarehouseConfig holds configuration for data warehouse
type DataWarehouseConfig struct {
	Provider    services.CloudProvider
	ProjectID   string // GCP Project / AWS Account / Azure Subscription
	Region      string
	Database    string // Dataset (GCP) / Database (AWS/Azure)
	Credentials map[string]string
}

// NewDataWarehouseClient creates a data warehouse client based on provider
func NewDataWarehouseClient(ctx context.Context, config DataWarehouseConfig) (DataWarehouseClient, error) {
	switch config.Provider {
	case services.CloudProviderGCP:
		return NewBigQueryDataWarehouseClient(ctx, config)
	case services.CloudProviderAWS:
		return NewRedshiftDataWarehouseClient(ctx, config)
	case services.CloudProviderAzure:
		return NewSynapseDataWarehouseClient(ctx, config)
	default:
		return nil, fmt.Errorf("unsupported provider: %s", config.Provider)
	}
}

// DefaultDataWarehouseConfig returns default configuration
func DefaultDataWarehouseConfig() DataWarehouseConfig {
	return DataWarehouseConfig{
		Provider:    services.CloudProviderLocal,
		ProjectID:   "",
		Region:      "us-central1",
		Database:    "",
		Credentials: make(map[string]string),
	}
}

// DataWarehouseFromEnv creates DataWarehouseConfig from environment variables
func DataWarehouseFromEnv() DataWarehouseConfig {
	config := DefaultDataWarehouseConfig()

	// Detect provider
	if provider := os.Getenv("DATAWAREHOUSE_PROVIDER"); provider != "" {
		switch provider {
		case "gcp", "google":
			config.Provider = services.CloudProviderGCP
		case "aws":
			config.Provider = services.CloudProviderAWS
		case "azure", "microsoft":
			config.Provider = services.CloudProviderAzure
		}
	} else {
		// Auto-detect from existing cloud config
		if os.Getenv("GOOGLE_CLOUD_PROJECT") != "" || os.Getenv("GCP_PROJECT_ID") != "" {
			config.Provider = services.CloudProviderGCP
		} else if os.Getenv("AWS_REGION") != "" || os.Getenv("AWS_ACCESS_KEY_ID") != "" {
			config.Provider = services.CloudProviderAWS
		} else if os.Getenv("AZURE_SUBSCRIPTION_ID") != "" || os.Getenv("AZURE_CLIENT_ID") != "" {
			config.Provider = services.CloudProviderAzure
		}
	}

	// GCP configuration
	if config.Provider == services.CloudProviderGCP {
		config.ProjectID = getEnv("GOOGLE_CLOUD_PROJECT", getEnv("GCP_PROJECT_ID", ""))
		config.Region = getEnv("GCP_REGION", "us-central1")
		config.Database = getEnv("BIGQUERY_DATASET", getEnv("GCP_DATASET", ""))
		config.Credentials["credentials_path"] = os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
		config.Credentials["credentials_json"] = os.Getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
	}

	// AWS configuration
	if config.Provider == services.CloudProviderAWS {
		config.ProjectID = getEnv("AWS_ACCOUNT_ID", "")
		config.Region = getEnv("AWS_REGION", "us-east-1")
		config.Database = getEnv("REDSHIFT_DATABASE", getEnv("AWS_DATABASE", ""))
		config.Credentials["host"] = getEnv("REDSHIFT_HOST", "")
		config.Credentials["port"] = getEnv("REDSHIFT_PORT", "5439")
		config.Credentials["user"] = getEnv("REDSHIFT_USER", "")
		config.Credentials["password"] = os.Getenv("REDSHIFT_PASSWORD")
		config.Credentials["cluster_id"] = getEnv("REDSHIFT_CLUSTER_ID", "")
		config.Credentials["access_key_id"] = os.Getenv("AWS_ACCESS_KEY_ID")
		config.Credentials["secret_access_key"] = os.Getenv("AWS_SECRET_ACCESS_KEY")
	}

	// Azure configuration
	if config.Provider == services.CloudProviderAzure {
		config.ProjectID = getEnv("AZURE_SUBSCRIPTION_ID", "")
		config.Region = getEnv("AZURE_LOCATION", "eastus")
		config.Database = getEnv("SYNAPSE_DATABASE", getEnv("AZURE_DATABASE", ""))
		config.Credentials["server"] = getEnv("SYNAPSE_SERVER", "")
		config.Credentials["user"] = getEnv("SYNAPSE_USER", "")
		config.Credentials["password"] = os.Getenv("SYNAPSE_PASSWORD")
		config.Credentials["workspace"] = getEnv("SYNAPSE_WORKSPACE", "")
		config.Credentials["client_id"] = os.Getenv("AZURE_CLIENT_ID")
		config.Credentials["client_secret"] = os.Getenv("AZURE_CLIENT_SECRET")
		config.Credentials["tenant_id"] = os.Getenv("AZURE_TENANT_ID")
	}

	return config
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// SQLRowsAdapter adapts sql.Rows to Rows interface
type SQLRowsAdapter struct {
	*sql.Rows
}

// Next implements Rows interface
func (r *SQLRowsAdapter) Next() bool {
	return r.Rows.Next()
}

// Scan implements Rows interface
func (r *SQLRowsAdapter) Scan(dest ...interface{}) error {
	return r.Rows.Scan(dest...)
}

// Close implements Rows interface
func (r *SQLRowsAdapter) Close() error {
	return r.Rows.Close()
}

// Err implements Rows interface
func (r *SQLRowsAdapter) Err() error {
	return r.Rows.Err()
}
