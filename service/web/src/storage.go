package web

// Blob storage via gocloud.dev (AWS S3, GCS, Azure Blob, local file://). URLs are read from
// config/env at runtime — never hardcode buckets.

import (
	"context"
	"io"
	"os"
	"strings"
	"time"

	"gocloud.dev/blob"
	_ "gocloud.dev/blob/azureblob"
	_ "gocloud.dev/blob/fileblob"
	_ "gocloud.dev/blob/gcsblob"
	_ "gocloud.dev/blob/s3blob"
)

// EnvStorageURL is the default bucket URL for [OpenBucketFromEnv] (s3://, gs://, azblob://, file://).
const EnvStorageURL = "RICE_STORAGE_URL"

// OpenBucket opens a blob bucket from a URL (e.g. s3://, gs://, azblob://, file://).
func OpenBucket(ctx context.Context, urlstr string) (*blob.Bucket, error) {
	return blob.OpenBucket(ctx, urlstr)
}

// OpenBucketFromEnv opens the bucket at [EnvStorageURL]; returns an error if unset or empty.
func OpenBucketFromEnv(ctx context.Context) (*blob.Bucket, error) {
	u := strings.TrimSpace(os.Getenv(EnvStorageURL))
	if u == "" {
		return nil, errStorageURLUnset
	}
	return OpenBucket(ctx, u)
}

// Upload writes reader into key using optional content type.
func Upload(ctx context.Context, b *blob.Bucket, key string, r io.Reader, contentType string) error {
	if b == nil {
		return errNilBucket
	}
	opts := &blob.WriterOptions{}
	if contentType != "" {
		opts.ContentType = contentType
	}
	w, err := b.NewWriter(ctx, key, opts)
	if err != nil {
		return err
	}
	if _, err := io.Copy(w, r); err != nil {
		_ = w.Close()
		return err
	}
	return w.Close()
}

// Download opens key for read.
func Download(ctx context.Context, b *blob.Bucket, key string) (*blob.Reader, error) {
	if b == nil {
		return nil, errNilBucket
	}
	return b.NewReader(ctx, key, nil)
}

// Delete removes an object from the bucket.
func Delete(ctx context.Context, b *blob.Bucket, key string) error {
	if b == nil {
		return errNilBucket
	}
	return b.Delete(ctx, key)
}

// Exists reports whether key is present.
func Exists(ctx context.Context, b *blob.Bucket, key string) (bool, error) {
	if b == nil {
		return false, errNilBucket
	}
	return b.Exists(ctx, key)
}

// SignedURL returns a time-limited URL when the driver supports it (S3/GCS/Azure).
func SignedURL(ctx context.Context, b *blob.Bucket, key string, opts *blob.SignedURLOptions) (string, error) {
	if b == nil {
		return "", errNilBucket
	}
	return b.SignedURL(ctx, key, opts)
}

// SignedURLGET builds a GET signed URL valid for ttl.
func SignedURLGET(ctx context.Context, b *blob.Bucket, key string, ttl time.Duration) (string, error) {
	return SignedURL(ctx, b, key, &blob.SignedURLOptions{Expiry: ttl, Method: "GET"})
}
