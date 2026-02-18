package services

import (
	"os"
	"strings"

	"github.com/chainrice/rice/backend/app/helpers"
)

// CloudProvider represents cloud provider type
type CloudProvider string

const (
	CloudProviderLocal CloudProvider = "local"
	CloudProviderAWS   CloudProvider = "aws"
	CloudProviderGCP   CloudProvider = "gcp"
	CloudProviderAzure CloudProvider = "azure"
)

// CloudConfig represents cloud-specific configuration
type CloudConfig struct {
	Provider     CloudProvider
	Region       string
	ProjectID    string // GCP Project ID or Azure Subscription ID
	ResourceName string // Resource identifier in cloud
	Endpoint     string // Cloud service endpoint
	Credentials  map[string]string
}

// DetectCloudProvider detects the cloud provider from environment variables
func DetectCloudProvider() CloudProvider {
	// Check for explicit provider setting
	if provider := helpers.GetEnv("CLOUD_PROVIDER", ""); provider != "" {
		switch strings.ToLower(provider) {
		case "aws":
			return CloudProviderAWS
		case "gcp", "google":
			return CloudProviderGCP
		case "azure", "microsoft":
			return CloudProviderAzure
		}
	}

	// Auto-detect from environment variables
	if os.Getenv("AWS_REGION") != "" || os.Getenv("AWS_ACCESS_KEY_ID") != "" {
		return CloudProviderAWS
	}
	if os.Getenv("GOOGLE_CLOUD_PROJECT") != "" || os.Getenv("GCP_PROJECT") != "" {
		return CloudProviderGCP
	}
	if os.Getenv("AZURE_SUBSCRIPTION_ID") != "" || os.Getenv("AZURE_CLIENT_ID") != "" {
		return CloudProviderAzure
	}

	return CloudProviderLocal
}

// GetCloudConfig returns cloud configuration for a service
func GetCloudConfig(serviceName string) *CloudConfig {
	provider := DetectCloudProvider()
	if provider == CloudProviderLocal {
		return nil
	}

	cfg := &CloudConfig{
		Provider:     provider,
		ResourceName: helpers.GetEnv(strings.ToUpper(serviceName)+"_RESOURCE_NAME", serviceName),
		Credentials:  make(map[string]string),
	}

	switch provider {
	case CloudProviderAWS:
		cfg.Region = helpers.GetEnv("AWS_REGION", "us-east-1")
		cfg.Credentials["access_key_id"] = os.Getenv("AWS_ACCESS_KEY_ID")
		cfg.Credentials["secret_access_key"] = os.Getenv("AWS_SECRET_ACCESS_KEY")
		cfg.Credentials["session_token"] = os.Getenv("AWS_SESSION_TOKEN")
	case CloudProviderGCP:
		cfg.ProjectID = helpers.GetEnv("GOOGLE_CLOUD_PROJECT", helpers.GetEnv("GCP_PROJECT", ""))
		cfg.Region = helpers.GetEnv("GCP_REGION", "us-central1")
		cfg.Credentials["credentials_json"] = os.Getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
		cfg.Credentials["credentials_path"] = os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	case CloudProviderAzure:
		cfg.ProjectID = helpers.GetEnv("AZURE_SUBSCRIPTION_ID", "")
		cfg.Region = helpers.GetEnv("AZURE_LOCATION", "eastus")
		cfg.Credentials["client_id"] = os.Getenv("AZURE_CLIENT_ID")
		cfg.Credentials["client_secret"] = os.Getenv("AZURE_CLIENT_SECRET")
		cfg.Credentials["tenant_id"] = os.Getenv("AZURE_TENANT_ID")
	}

	return cfg
}
