package pipeline

import (
	"context"
	"fmt"

	"github.com/chainrice/rice/backend/module"
	dataflow "google.golang.org/api/dataflow/v1b3"
	"google.golang.org/api/option"
)

// DataflowClient implements DataPipelineClient for GCP
type DataflowClient struct {
	projectID string
	region    string
	service   *dataflow.Service
}

// NewDataflowClient creates a new Dataflow client
func NewDataflowClient(ctx context.Context, config DataPipelineConfig) (*DataflowClient, error) {
	var opts []option.ClientOption
	if credsPath := config.Credentials["credentials_path"]; credsPath != "" {
		opts = append(opts, option.WithCredentialsFile(credsPath))
	} else if credsJSON := config.Credentials["credentials_json"]; credsJSON != "" {
		opts = append(opts, option.WithCredentialsJSON([]byte(credsJSON)))
	}

	service, err := dataflow.NewService(ctx, opts...)
	if err != nil {
		return nil, fmt.Errorf("failed to create Dataflow service: %w", err)
	}

	return &DataflowClient{
		projectID: config.ProjectID,
		region:    config.Region,
		service:   service,
	}, nil
}

// SubmitJob submits a batch processing job
func (c *DataflowClient) SubmitJob(ctx context.Context, job JobConfig) (JobID, error) {
	jobRequest := &dataflow.LaunchFlexTemplateRequest{
		LaunchParameter: &dataflow.LaunchFlexTemplateParameter{
			JobName:              job.Name,
			Parameters:           job.Parameters,
			ContainerSpecGcsPath: job.Template,
		},
	}

	resp, err := c.service.Projects.Locations.FlexTemplates.Launch(
		c.projectID,
		c.region,
		jobRequest,
	).Do()

	if err != nil {
		return "", fmt.Errorf("failed to submit job: %w", err)
	}

	return JobID(resp.Job.Id), nil
}

// SubmitStreamingJob submits a streaming job
func (c *DataflowClient) SubmitStreamingJob(ctx context.Context, job StreamingJobConfig) (JobID, error) {
	// Dataflow uses same API for streaming, just different template
	jobRequest := &dataflow.LaunchFlexTemplateRequest{
		LaunchParameter: &dataflow.LaunchFlexTemplateParameter{
			JobName:              job.Name,
			Parameters:           job.Parameters,
			ContainerSpecGcsPath: job.Source, // Template path
		},
	}

	resp, err := c.service.Projects.Locations.FlexTemplates.Launch(
		c.projectID,
		c.region,
		jobRequest,
	).Do()

	if err != nil {
		return "", fmt.Errorf("failed to submit streaming job: %w", err)
	}

	return JobID(resp.Job.Id), nil
}

// GetJobStatus gets job status
func (c *DataflowClient) GetJobStatus(ctx context.Context, jobID JobID) (JobStatus, error) {
	job, err := c.service.Projects.Locations.Jobs.Get(
		c.projectID,
		c.region,
		string(jobID),
	).Do()

	if err != nil {
		return JobStatusFailed, fmt.Errorf("failed to get job status: %w", err)
	}

	switch job.CurrentState {
	case "JOB_STATE_PENDING":
		return JobStatusPending, nil
	case "JOB_STATE_RUNNING":
		return JobStatusRunning, nil
	case "JOB_STATE_DONE":
		return JobStatusSucceeded, nil
	case "JOB_STATE_FAILED":
		return JobStatusFailed, nil
	case "JOB_STATE_CANCELLED":
		return JobStatusCancelled, nil
	default:
		return JobStatusPending, nil
	}
}

// CancelJob cancels a running job
func (c *DataflowClient) CancelJob(ctx context.Context, jobID JobID) error {
	_, err := c.service.Projects.Locations.Jobs.Update(
		c.projectID,
		c.region,
		string(jobID),
		&dataflow.Job{
			RequestedState: "JOB_STATE_CANCELLED",
		},
	).Do()

	if err != nil {
		return fmt.Errorf("failed to cancel job: %w", err)
	}

	return nil
}

// GetProvider returns the cloud provider
func (c *DataflowClient) GetProvider() module.CloudProvider {
	return module.CloudProviderGCP
}

// Close closes the client connection
func (c *DataflowClient) Close() error {
	// Dataflow service doesn't need explicit close
	return nil
}
