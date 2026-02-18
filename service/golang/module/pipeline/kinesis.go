package pipeline

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kinesisanalyticsv2"
	"github.com/chainrice/rice/backend/module"
)

// KinesisClient implements DataPipelineClient for AWS
type KinesisClient struct {
	session *session.Session
	region  string
	client  *kinesisanalyticsv2.KinesisAnalyticsV2
}

// NewKinesisClient creates a new Kinesis Data Analytics client
func NewKinesisClient(ctx context.Context, config DataPipelineConfig) (*KinesisClient, error) {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(config.Region),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create AWS session: %w", err)
	}

	return &KinesisClient{
		session: sess,
		region:  config.Region,
		client:  kinesisanalyticsv2.New(sess),
	}, nil
}

// SubmitJob submits a batch processing job
func (c *KinesisClient) SubmitJob(ctx context.Context, job JobConfig) (JobID, error) {
	// Kinesis Data Analytics uses applications, not jobs
	input := &kinesisanalyticsv2.CreateApplicationInput{
		ApplicationName:    aws.String(job.Name),
		RuntimeEnvironment: aws.String("FLINK-1_15"),
	}

	resp, err := c.client.CreateApplicationWithContext(ctx, input)
	if err != nil {
		return "", fmt.Errorf("failed to create application: %w", err)
	}

	return JobID(*resp.ApplicationDetail.ApplicationARN), nil
}

// SubmitStreamingJob submits a streaming job
func (c *KinesisClient) SubmitStreamingJob(ctx context.Context, job StreamingJobConfig) (JobID, error) {
	// Same as SubmitJob for Kinesis
	return c.SubmitJob(ctx, JobConfig{
		Name:   job.Name,
		Region: job.Region,
	})
}

// GetJobStatus gets job status
func (c *KinesisClient) GetJobStatus(ctx context.Context, jobID JobID) (JobStatus, error) {
	appName := string(jobID) // Extract name from ARN if needed

	resp, err := c.client.DescribeApplicationWithContext(ctx, &kinesisanalyticsv2.DescribeApplicationInput{
		ApplicationName: aws.String(appName),
	})
	if err != nil {
		return JobStatusFailed, fmt.Errorf("failed to get application status: %w", err)
	}

	status := *resp.ApplicationDetail.ApplicationStatus
	switch status {
	case "CREATING":
		return JobStatusPending, nil
	case "RUNNING":
		return JobStatusRunning, nil
	case "UPDATING":
		return JobStatusRunning, nil
	case "DELETING":
		return JobStatusCancelled, nil
	case "FAILED":
		return JobStatusFailed, nil
	default:
		return JobStatusPending, nil
	}
}

// CancelJob cancels a running job
func (c *KinesisClient) CancelJob(ctx context.Context, jobID JobID) error {
	appName := string(jobID)

	_, err := c.client.DeleteApplicationWithContext(ctx, &kinesisanalyticsv2.DeleteApplicationInput{
		ApplicationName: aws.String(appName),
		CreateTimestamp: nil, // Would need timestamp for proper deletion
	})

	if err != nil {
		return fmt.Errorf("failed to delete application: %w", err)
	}

	return nil
}

// GetProvider returns the cloud provider
func (c *KinesisClient) GetProvider() module.CloudProvider {
	return module.CloudProviderAWS
}

// Close closes the client connection
func (c *KinesisClient) Close() error {
	// AWS clients don't need explicit close
	return nil
}
