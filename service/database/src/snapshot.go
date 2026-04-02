package database

// TODO:
// [ ] implement YugabyteDB snapshot backup:
//     Snapshot(ctx, pool) (snapshotID string, error)
//     uses YugabyteDB snapshot REST API
//     endpoint from RICE_YB_ADMIN_URL env var
// [ ] implement snapshot restore:
//     Restore(ctx, snapshotID string) error
//     used in disaster recovery
// [ ] implement automated snapshots:
//     scheduled by Temporal workflow in queue/
//     frequency from RICE_SNAPSHOT_INTERVAL_H env var

import (
	"context"
	"errors"
	"io"

	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	errNilSnapshotter       = errors.New("database: nil snapshotter")
	errSnapshotNotImplemented = errors.New("database: ExportTableCSV not wired — implement COPY TO STDOUT + sink")
)

// Snapshotter coordinates YugabyteDB → analytical store exports for SAGE (DuckDB, Parquet, or files).
type Snapshotter struct {
	Pool    *pgxpool.Pool
	DuckDSN string
}

// ExportTableCSV streams rows from a table using COPY TO STDOUT (Postgres wire).
// Implement with pgx: acquire conn, run COPY ... TO STDOUT, return io.ReadCloser piping to DuckDB COPY FROM or a file sink.
func (s *Snapshotter) ExportTableCSV(ctx context.Context, schema, table string) (io.ReadCloser, error) {
	_ = ctx
	_ = schema
	_ = table
	if s == nil || s.Pool == nil {
		return nil, errNilSnapshotter
	}
	// Wire: conn.Hijack or pgxpool.Conn with COPY -- depends on deployment; keep IO boundary here.
	return nil, errSnapshotNotImplemented
}

// SnapshotForSAGE runs a full refresh job (scheduler / Temporal calls this).
func SnapshotForSAGE(ctx context.Context, snap *Snapshotter) error {
	_ = ctx
	_ = snap
	return nil
}
