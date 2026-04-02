package web

// TODO:
// [ ] implement gocloud.dev blob storage:
//     NewBucket(ctx) (*blob.Bucket, error)
//     reads RICE_STORAGE_URL from env:
//     s3://bucket → AWS S3
//     gs://bucket → GCS
//     azblob://container → Azure Blob
// [ ] implement file operations:
//     Upload(ctx, key string, r io.Reader) error
//     Download(ctx, key string) (io.ReadCloser, error)
//     Delete(ctx, key string) error
//     Exists(ctx, key string) (bool, error)
// [ ] implement presigned URLs:
//     SignedURL(ctx, key string, ttl time.Duration) (string, error)

import (
	"context"
	"io"

	"gocloud.dev/blob"
	_ "gocloud.dev/blob/fileblob"
	_ "gocloud.dev/blob/gcsblob"
	_ "gocloud.dev/blob/s3blob"
)

// OpenBucket opens a blob bucket from a URL (e.g. s3://, gs://, file://).
func OpenBucket(ctx context.Context, urlstr string) (*blob.Bucket, error) {
	return blob.OpenBucket(ctx, urlstr)
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
func Download(ctx context.Context, b *blob.Bucket, key string) (io.ReadCloser, error) {
	if b == nil {
		return nil, errNilBucket
	}
	return b.NewReader(ctx, key, nil)
}

// SignedURL returns a time-limited URL when the driver supports it (S3/GCS).
func SignedURL(ctx context.Context, b *blob.Bucket, key string, opts *blob.SignedURLOptions) (string, error) {
	if b == nil {
		return "", errNilBucket
	}
	return b.SignedURL(ctx, key, opts)
}
