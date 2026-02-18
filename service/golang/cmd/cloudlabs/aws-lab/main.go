package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/sts"
)

// aws-lab is a small helper CLI intended for training labs.
// It demonstrates:
//   - reading AWS credentials/profile from the environment
//   - calling STS GetCallerIdentity
//   - listing S3 buckets in the current account
//
// Example:
//   AWS_PROFILE=training AWS_REGION=us-east-1 go run ./cmd/cloudlabs/aws-lab
func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	profile := os.Getenv("AWS_PROFILE")
	if profile == "" {
		profile = "default"
	}

	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = os.Getenv("AWS_DEFAULT_REGION")
	}
	if region == "" {
		region = "us-east-1"
	}

	fmt.Printf("[aws-lab] Using profile=%q region=%q\n", profile, region)

	sess, err := session.NewSessionWithOptions(session.Options{
		Config: aws.Config{Region: aws.String(region)},
		Profile: profile,
		SharedConfigState: session.SharedConfigEnable,
	})
	if err != nil {
		log.Fatalf("[aws-lab] failed to create AWS session: %v", err)
	}

	stsClient := sts.New(sess)
	identity, err := stsClient.GetCallerIdentityWithContext(ctx, &sts.GetCallerIdentityInput{})
	if err != nil {
		log.Fatalf("[aws-lab] STS GetCallerIdentity failed: %v", err)
	}

	fmt.Println("[aws-lab] STS GetCallerIdentity:")
	fmt.Printf("  Account : %s\n", aws.StringValue(identity.Account))
	fmt.Printf("  ARN     : %s\n", aws.StringValue(identity.Arn))
	fmt.Printf("  UserId  : %s\n", aws.StringValue(identity.UserId))

	s3Client := s3.New(sess)
	buckets, err := s3Client.ListBucketsWithContext(ctx, &s3.ListBucketsInput{})
	if err != nil {
		log.Fatalf("[aws-lab] failed to list S3 buckets: %v", err)
	}

	fmt.Println("[aws-lab] S3 buckets:")
	if len(buckets.Buckets) == 0 {
		fmt.Println("  (no buckets)")
	} else {
		for _, b := range buckets.Buckets {
			fmt.Printf("  - %s\n", aws.StringValue(b.Name))
		}
	}
}

