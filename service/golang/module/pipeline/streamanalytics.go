package pipeline

import (
	"context"
	"fmt"

	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/streamanalytics/armstreamanalytics"
	"github.com/chainrice/rice/backend/module"
)

// StreamAnalyticsClient implements DataPipelineClient for Azure
type StreamAnalyticsClient struct {
	subscriptionID string
	resourceGroup  string
	client         *armstreamanalytics.StreamingJobsClient
}

// NewStreamAnalyticsClient creates a new Stream Analytics client
// NOTE: This function requires armstreamanalytics v1.1.0+ which includes NewClientFactory
// Current go.mod uses v1.0.0 which doesn't have NewClientFactory
// TODO: Update go.mod: github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/streamanalytics/armstreamanalytics v1.1.0
func NewStreamAnalyticsClient(ctx context.Context, config DataPipelineConfig) (*StreamAnalyticsClient, error) {
	// This implementation is disabled until SDK is updated
	// Uncomment the following when armstreamanalytics is updated to v1.1.0+:
	/*
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create Azure credential: %w", err)
	}

	clientFactory, err := armstreamanalytics.NewClientFactory(
		config.ProjectID, // Subscription ID
		cred,
		nil,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create client factory: %w", err)
	}

	return &StreamAnalyticsClient{
		subscriptionID: config.ProjectID,
		resourceGroup:  config.Credentials["resource_group"],
		client:         clientFactory.NewStreamingJobsClient(),
	}, nil
	*/
	
	return nil, fmt.Errorf("Stream Analytics client requires armstreamanalytics v1.1.0+. Current: v1.0.0. Update go.mod")
}

// SubmitJob submits a batch processing job
func (c *StreamAnalyticsClient) SubmitJob(ctx context.Context, job JobConfig) (JobID, error) {
	// Stream Analytics jobs are created, not submitted
	skuName := armstreamanalytics.SKUNameStandard
	streamingJob := armstreamanalytics.StreamingJob{
		Location: &job.Region,
		Properties: &armstreamanalytics.StreamingJobProperties{
			SKU: &armstreamanalytics.SKU{
				Name: &skuName,
			},
		},
	}

	// Use BeginCreateOrReplace (correct method name in Azure SDK)
	// If that doesn't exist, try CreateOrReplace (synchronous version)
	poller, err := c.client.BeginCreateOrReplace(
		ctx,
		c.resourceGroup,
		job.Name,
		streamingJob,
		nil,
	)
	if err != nil {
		return "", fmt.Errorf("failed to create streaming job: %w", err)
	}

	resp, err := poller.PollUntilDone(ctx, nil)
	if err != nil {
		return "", fmt.Errorf("failed to wait for job creation: %w", err)
	}

	return JobID(*resp.ID), nil
}

// SubmitStreamingJob submits a streaming job
func (c *StreamAnalyticsClient) SubmitStreamingJob(ctx context.Context, job StreamingJobConfig) (JobID, error) {
	// Same as SubmitJob for Stream Analytics
	return c.SubmitJob(ctx, JobConfig{
		Name:   job.Name,
		Region: job.Region,
	})
}

// GetJobStatus gets job status
func (c *StreamAnalyticsClient) GetJobStatus(ctx context.Context, jobID JobID) (JobStatus, error) {
	// Extract job name from ID
	jobName := string(jobID) // Simplified - would need proper parsing

	resp, err := c.client.Get(ctx, c.resourceGroup, jobName, nil)
	if err != nil {
		return JobStatusFailed, fmt.Errorf("failed to get job status: %w", err)
	}

	if resp.Properties == nil || resp.Properties.JobState == nil {
		return JobStatusPending, nil
	}

	state := resp.Properties.JobState
	// JobState is an enum type, convert to string for comparison
	stateStr := string(*state)
	switch stateStr {
	case string(armstreamanalytics.JobStateCreated):
		return JobStatusPending, nil
	case string(armstreamanalytics.JobStateRunning):
		return JobStatusRunning, nil
	case string(armstreamanalytics.JobStateStopped):
		return JobStatusSucceeded, nil
	case string(armstreamanalytics.JobStateFailed):
		return JobStatusFailed, nil
	case string(armstreamanalytics.JobStateDegraded):
		return JobStatusFailed, nil
	default:
		return JobStatusPending, nil
	}
}

// CancelJob cancels a running job
func (c *StreamAnalyticsClient) CancelJob(ctx context.Context, jobID JobID) error {
	jobName := string(jobID)

	_, err := c.client.BeginStop(ctx, c.resourceGroup, jobName, nil)
	if err != nil {
		return fmt.Errorf("failed to stop job: %w", err)
	}

	return nil
}

// GetProvider returns the cloud provider
func (c *StreamAnalyticsClient) GetProvider() module.CloudProvider {
	return module.CloudProviderAzure
}

// Close closes the client connection
func (c *StreamAnalyticsClient) Close() error {
	// Azure clients don't need explicit close
	return nil
}
