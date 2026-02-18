package pipeline

import (
	"context"
	"fmt"
	"os"

	"github.com/chainrice/rice/backend/module"
)

// DataPipelineClient is the unified interface for all data processing pipeline services
type DataPipelineClient interface {
	// SubmitJob submits a batch processing job
	SubmitJob(ctx context.Context, job JobConfig) (JobID, error)

	// SubmitStreamingJob submits a streaming job
	SubmitStreamingJob(ctx context.Context, job StreamingJobConfig) (JobID, error)

	// GetJobStatus gets job status
	GetJobStatus(ctx context.Context, jobID JobID) (JobStatus, error)

	// CancelJob cancels a running job
	CancelJob(ctx context.Context, jobID JobID) error

	// GetProvider returns the cloud provider
	GetProvider() module.CloudProvider

	// Close closes the client connection
	Close() error
}

// JobID represents a job identifier
type JobID string

// JobStatus represents job status
type JobStatus string

const (
	JobStatusPending   JobStatus = "PENDING"
	JobStatusRunning   JobStatus = "RUNNING"
	JobStatusSucceeded JobStatus = "SUCCEEDED"
	JobStatusFailed    JobStatus = "FAILED"
	JobStatusCancelled JobStatus = "CANCELLED"
)

// JobConfig holds configuration for a batch job
type JobConfig struct {
	Name       string
	Parameters map[string]string
	Template   string // Template path or name
	Region     string
}

// StreamingJobConfig holds configuration for a streaming job
type StreamingJobConfig struct {
	Name       string
	Parameters map[string]string
	Source     string // Source stream/topic
	Sink       string // Destination
	Region     string
}

// DataPipelineConfig holds configuration for data processing
type DataPipelineConfig struct {
	Provider    module.CloudProvider
	ProjectID   string
	Region      string
	Credentials map[string]string
}

// NewDataPipelineClient creates a pipeline client based on provider
func NewDataPipelineClient(ctx context.Context, config DataPipelineConfig) (DataPipelineClient, error) {
	switch config.Provider {
	case module.CloudProviderGCP:
		return NewDataflowClient(ctx, config)
	case module.CloudProviderAWS:
		return NewKinesisClient(ctx, config)
	case module.CloudProviderAzure:
		return NewStreamAnalyticsClient(ctx, config)
	default:
		return nil, fmt.Errorf("unsupported provider: %s", config.Provider)
	}
}

// DefaultDataPipelineConfig returns default configuration
func DefaultDataPipelineConfig() DataPipelineConfig {
	return DataPipelineConfig{
		Provider:    module.CloudProviderLocal,
		ProjectID:   "",
		Region:      "us-central1",
		Credentials: make(map[string]string),
	}
}

// DataPipelineFromEnv creates DataPipelineConfig from environment variables
func DataPipelineFromEnv() DataPipelineConfig {
	config := DefaultDataPipelineConfig()

	// Detect provider
	if provider := os.Getenv("DATAPIPELINE_PROVIDER"); provider != "" {
		switch provider {
		case "gcp", "google":
			config.Provider = module.CloudProviderGCP
		case "aws":
			config.Provider = module.CloudProviderAWS
		case "azure", "microsoft":
			config.Provider = module.CloudProviderAzure
		}
	} else {
		// Auto-detect
		if os.Getenv("GOOGLE_CLOUD_PROJECT") != "" || os.Getenv("GCP_PROJECT_ID") != "" {
			config.Provider = module.CloudProviderGCP
		} else if os.Getenv("AWS_REGION") != "" || os.Getenv("AWS_ACCESS_KEY_ID") != "" {
			config.Provider = module.CloudProviderAWS
		} else if os.Getenv("AZURE_SUBSCRIPTION_ID") != "" || os.Getenv("AZURE_CLIENT_ID") != "" {
			config.Provider = module.CloudProviderAzure
		}
	}

	// GCP configuration
	if config.Provider == module.CloudProviderGCP {
		config.ProjectID = getEnv("GOOGLE_CLOUD_PROJECT", getEnv("GCP_PROJECT_ID", ""))
		config.Region = getEnv("GCP_REGION", "us-central1")
		config.Credentials["credentials_path"] = os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
		config.Credentials["credentials_json"] = os.Getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
	}

	// AWS configuration
	if config.Provider == module.CloudProviderAWS {
		config.ProjectID = getEnv("AWS_ACCOUNT_ID", "")
		config.Region = getEnv("AWS_REGION", "us-east-1")
		config.Credentials["access_key_id"] = os.Getenv("AWS_ACCESS_KEY_ID")
		config.Credentials["secret_access_key"] = os.Getenv("AWS_SECRET_ACCESS_KEY")
	}

	// Azure configuration
	if config.Provider == module.CloudProviderAzure {
		config.ProjectID = getEnv("AZURE_SUBSCRIPTION_ID", "")
		config.Region = getEnv("AZURE_LOCATION", "eastus")
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
