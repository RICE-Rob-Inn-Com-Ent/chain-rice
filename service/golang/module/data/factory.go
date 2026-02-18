package data

import (
	"context"
	"fmt"

	"github.com/chainrice/rice/backend/app/services"
	"github.com/chainrice/rice/backend/module/store"
)

// DataEngineeringFactory creates data engineering clients based on detected provider
type DataEngineeringFactory struct {
	cloudConfig *services.CloudConfig
}

// NewDataEngineeringFactory creates a new factory with auto-detected cloud provider
func NewDataEngineeringFactory() (*DataEngineeringFactory, error) {
	cloudConfig := services.GetCloudConfig("data")
	if cloudConfig == nil {
		return nil, fmt.Errorf("no cloud provider detected")
	}

	if cloudConfig.Provider == "" {
		return nil, fmt.Errorf("cloud provider type cannot be empty")
	}

	return &DataEngineeringFactory{
		cloudConfig: cloudConfig,
	}, nil
}

// NewDataEngineeringFactoryWithProvider creates a factory with explicit provider
func NewDataEngineeringFactoryWithProvider(provider services.CloudProvider) (*DataEngineeringFactory, error) {
	cloudConfig := services.GetCloudConfig("data")
	if cloudConfig == nil {
		// Create minimal config if auto-detection fails
		cloudConfig = &services.CloudConfig{
			Provider: provider,
		}
	} else {
		cloudConfig.Provider = provider
	}

	return &DataEngineeringFactory{
		cloudConfig: cloudConfig,
	}, nil
}

// NewDataWarehouse creates a data warehouse client
func (f *DataEngineeringFactory) NewDataWarehouse(ctx context.Context) (store.DataWarehouseClient, error) {
	if ctx == nil {
		return nil, fmt.Errorf("context cannot be nil")
	}

	if f.cloudConfig == nil {
		return nil, fmt.Errorf("cloud config cannot be nil")
	}

	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("context cancelled: %w", err)
	}

	config := store.DataWarehouseConfig{
		Provider:    f.cloudConfig.Provider,
		ProjectID:   f.cloudConfig.ProjectID,
		Region:      f.cloudConfig.Region,
		Database:    f.cloudConfig.Credentials["database"],
		Credentials: f.cloudConfig.Credentials,
	}

	client, err := store.NewDataWarehouseClient(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create data warehouse client: %w", err)
	}

	return client, nil
}

// GetCloudConfig returns the underlying cloud configuration
func (f *DataEngineeringFactory) GetCloudConfig() *services.CloudConfig {
	return f.cloudConfig
}
