package store

import (
	"context"
	"fmt"

	"cloud.google.com/go/bigquery"
	"github.com/chainrice/rice/backend/app/services"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
)

// BigQueryDataWarehouseClient implements DataWarehouseClient for GCP
type BigQueryDataWarehouseClient struct {
	client    *bigquery.Client
	projectID string
	datasetID string
}

// NewBigQueryDataWarehouseClient creates a new BigQuery data warehouse client
func NewBigQueryDataWarehouseClient(ctx context.Context, config DataWarehouseConfig) (*BigQueryDataWarehouseClient, error) {
	var opts []option.ClientOption
	if credsPath := config.Credentials["credentials_path"]; credsPath != "" {
		opts = append(opts, option.WithCredentialsFile(credsPath))
	} else if credsJSON := config.Credentials["credentials_json"]; credsJSON != "" {
		opts = append(opts, option.WithCredentialsJSON([]byte(credsJSON)))
	}

	client, err := bigquery.NewClient(ctx, config.ProjectID, opts...)
	if err != nil {
		return nil, fmt.Errorf("failed to create BigQuery client: %w", err)
	}

	datasetID := config.Database
	if datasetID == "" {
		datasetID = "default_dataset"
	}

	return &BigQueryDataWarehouseClient{
		client:    client,
		projectID: config.ProjectID,
		datasetID: datasetID,
	}, nil
}

// Query executes a SQL query
func (c *BigQueryDataWarehouseClient) Query(ctx context.Context, sql string) (Rows, error) {
	q := c.client.Query(sql)
	// Location is a field, not a method - set it if needed
	// q.Location = c.client.Location

	it, err := q.Read(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %w", err)
	}

	return &BigQueryRowsAdapter{
		it:      it,
		hasNext: false,
	}, nil
}

// CreateTable creates a table with schema
func (c *BigQueryDataWarehouseClient) CreateTable(ctx context.Context, tableID string, schema Schema) error {
	dataset := c.client.Dataset(c.datasetID)
	table := dataset.Table(tableID)

	bqSchema := convertToBigQuerySchema(schema)
	metadata := &bigquery.TableMetadata{
		Schema: bqSchema,
	}

	return table.Create(ctx, metadata)
}

// LoadData loads data from storage
func (c *BigQueryDataWarehouseClient) LoadData(ctx context.Context, sourceURI string, tableID string) error {
	dataset := c.client.Dataset(c.datasetID)
	table := dataset.Table(tableID)

	source := bigquery.NewGCSReference(sourceURI)
	// AutoDetect doesn't exist - use a specific format or omit
	// source.SourceFormat = bigquery.AutoDetect

	loader := table.LoaderFrom(source)
	loader.WriteDisposition = bigquery.WriteAppend

	job, err := loader.Run(ctx)
	if err != nil {
		return fmt.Errorf("failed to start load job: %w", err)
	}

	status, err := job.Wait(ctx)
	if err != nil {
		return fmt.Errorf("load job failed: %w", err)
	}

	if status.Err() != nil {
		return fmt.Errorf("load job error: %w", status.Err())
	}

	return nil
}

// ExportData exports data to storage
func (c *BigQueryDataWarehouseClient) ExportData(ctx context.Context, tableID string, destURI string) error {
	dataset := c.client.Dataset(c.datasetID)
	table := dataset.Table(tableID)

	gcsRef := bigquery.NewGCSReference(destURI)
	// Format field doesn't exist in current API - format is determined by file extension
	// gcsRef.Format = bigquery.Parquet

	extractor := table.ExtractorTo(gcsRef)
	job, err := extractor.Run(ctx)
	if err != nil {
		return fmt.Errorf("failed to start export job: %w", err)
	}

	status, err := job.Wait(ctx)
	if err != nil {
		return fmt.Errorf("export job failed: %w", err)
	}

	if status.Err() != nil {
		return fmt.Errorf("export job error: %w", status.Err())
	}

	return nil
}

// GetProvider returns the cloud provider
func (c *BigQueryDataWarehouseClient) GetProvider() services.CloudProvider {
	return services.CloudProviderGCP
}

// Close closes the client connection
func (c *BigQueryDataWarehouseClient) Close() error {
	return c.client.Close()
}

// BigQueryRowsAdapter adapts bigquery.RowIterator to Rows
type BigQueryRowsAdapter struct {
	it        *bigquery.RowIterator
	nextRow   []bigquery.Value
	hasNext   bool
	nextError error
}

// Next implements Rows interface
func (r *BigQueryRowsAdapter) Next() bool {
	// BigQuery Next() requires a destination parameter
	// We need to read the row first and store it
	var row []bigquery.Value
	r.nextError = r.it.Next(&row)
	if r.nextError == iterator.Done {
		r.hasNext = false
		r.nextError = nil
		return false
	}
	if r.nextError != nil {
		r.hasNext = false
		return false
	}
	r.nextRow = row
	r.hasNext = true
	return true
}

// Scan implements Rows interface
func (r *BigQueryRowsAdapter) Scan(dest ...interface{}) error {
	if !r.hasNext {
		return fmt.Errorf("no row available, call Next() first")
	}
	if r.nextError != nil {
		return r.nextError
	}

	if len(dest) != len(r.nextRow) {
		return fmt.Errorf("mismatched column count: expected %d, got %d", len(dest), len(r.nextRow))
	}

	for i, val := range r.nextRow {
		if err := assignValue(dest[i], val); err != nil {
			return fmt.Errorf("failed to assign value at index %d: %w", i, err)
		}
	}

	return nil
}

// Close implements Rows interface
func (r *BigQueryRowsAdapter) Close() error {
	return nil // BigQuery iterator doesn't need explicit close
}

// Err implements Rows interface
func (r *BigQueryRowsAdapter) Err() error {
	// Return the error from the last Next() call
	return r.nextError
}

func convertToBigQuerySchema(schema Schema) bigquery.Schema {
	bqSchema := make(bigquery.Schema, len(schema.Fields))
	for i, field := range schema.Fields {
		// Nullable, Required, Repeated constants don't exist
		// Mode field doesn't exist in FieldSchema
		// Use Required field or omit Mode
		var required bool
		switch field.Mode {
		case "REQUIRED":
			required = true
		case "REPEATED":
			required = false // Repeated fields can't be required
		default:
			required = false // Nullable
		}

		bqSchema[i] = &bigquery.FieldSchema{
			Name:        field.Name,
			Type:        bigquery.FieldType(field.Type),
			Required:    required,
			Description: field.Description,
		}
	}
	return bqSchema
}

func assignValue(dest interface{}, val bigquery.Value) error {
	switch d := dest.(type) {
	case *string:
		if s, ok := val.(string); ok {
			*d = s
		} else {
			*d = fmt.Sprintf("%v", val)
		}
	case *int:
		if i, ok := val.(int64); ok {
			*d = int(i)
		}
	case *int64:
		if i, ok := val.(int64); ok {
			*d = i
		}
	case *float64:
		if f, ok := val.(float64); ok {
			*d = f
		}
	case *bool:
		if b, ok := val.(bool); ok {
			*d = b
		}
	default:
		return fmt.Errorf("unsupported destination type: %T", dest)
	}
	return nil
}
