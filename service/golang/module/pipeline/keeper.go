package pipeline

import (
	"context"
	"log"
)

// DataPipelineKeeper manages data pipeline connections and operations
type DataPipelineKeeper struct {
	client DataPipelineClient
}

// NewDataPipelineKeeper creates a new data pipeline keeper
func NewDataPipelineKeeper(client DataPipelineClient) *DataPipelineKeeper {
	return &DataPipelineKeeper{
		client: client,
	}
}

// GetClient returns the underlying pipeline client
func (k *DataPipelineKeeper) GetClient() DataPipelineClient {
	return k.client
}

// SubmitJob submits a batch processing job
func (k *DataPipelineKeeper) SubmitJob(ctx context.Context, job JobConfig) (JobID, error) {
	return k.client.SubmitJob(ctx, job)
}

// SubmitStreamingJob submits a streaming job
func (k *DataPipelineKeeper) SubmitStreamingJob(ctx context.Context, job StreamingJobConfig) (JobID, error) {
	return k.client.SubmitStreamingJob(ctx, job)
}

// GetJobStatus gets job status
func (k *DataPipelineKeeper) GetJobStatus(ctx context.Context, jobID JobID) (JobStatus, error) {
	return k.client.GetJobStatus(ctx, jobID)
}

// CancelJob cancels a running job
func (k *DataPipelineKeeper) CancelJob(ctx context.Context, jobID JobID) error {
	return k.client.CancelJob(ctx, jobID)
}

// GetProvider returns the cloud provider
func (k *DataPipelineKeeper) GetProvider() interface{} {
	return k.client.GetProvider()
}

// Close closes the connection
func (k *DataPipelineKeeper) Close() error {
	log.Println("Closing data pipeline connection")
	return k.client.Close()
}
