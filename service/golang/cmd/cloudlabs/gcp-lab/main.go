package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"cloud.google.com/go/storage"
	"google.golang.org/api/option"
)

// gcp-lab is a small helper CLI for GCP labs.
// It demonstrates:
//   - application default credentials (ADC)
//   - basic storage bucket listing
//
// Requirements:
//   - `gcloud auth application-default login` done in the container
//   - or GOOGLE_APPLICATION_CREDENTIALS pointing to a service account key
func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		projectID = os.Getenv("GCLOUD_PROJECT")
	}

	if projectID == "" {
		log.Println("[gcp-lab] WARNING: GOOGLE_CLOUD_PROJECT not set, bucket listing may be limited.")
	}

	fmt.Printf("[gcp-lab] Using project=%q\n", projectID)

	client, err := newStorageClient(ctx)
	if err != nil {
		log.Fatalf("[gcp-lab] failed to create storage client: %v", err)
	}
	defer client.Close()

	fmt.Println("[gcp-lab] Listing Storage buckets:")
	it := client.Buckets(ctx, projectID)
	count := 0
	for {
		bucketAttrs, err := it.Next()
		if err != nil {
			if err.Error() == "no more items in iterator" {
				break
			}
			log.Fatalf("[gcp-lab] error while listing buckets: %v", err)
		}
		fmt.Printf("  - %s\n", bucketAttrs.Name)
		count++
	}

	if count == 0 {
		fmt.Println("  (no buckets or insufficient permissions)")
	}
}

func newStorageClient(ctx context.Context) (*storage.Client, error) {
	credsFile := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	if credsFile != "" {
		return storage.NewClient(ctx, option.WithCredentialsFile(credsFile))
	}
	return storage.NewClient(ctx)
}

