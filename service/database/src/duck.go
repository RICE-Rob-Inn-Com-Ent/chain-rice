package database

// TODO:
// [ ] implement DuckDB connection:
//     NewDuck(path string) (*sql.DB, error)
//     path from RICE_DUCKDB_PATH env var
//     read-only mode when RICE_DUCKDB_READONLY=true
// [ ] implement DuckDB OLAP queries:
//     QueryAnalytics(ctx, sql string) (*sql.Rows, error)
//     OTel span per query — db.system=duckdb
// [ ] implement DuckDB ↔ YugabyteDB ETL:
//     SyncToAnalytics(ctx, table string) error
//     reads from YugabyteDB → writes to DuckDB for analytics
//     sync interval from RICE_DUCK_SYNC_INTERVAL_S env var
// [ ] DuckDB is analytical ONLY — no writes from other roles
//     all DuckDB queries go through SMITH database/ via proto contracts

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	_ "github.com/marcboeker/go-duckdb"
)

// Duck opens an embedded DuckDB connection for OLAP (analytical queries, Arrow/Parquet via extensions).
// Register extensions (httpfs, parquet) as needed before heavy queries.
func Duck(dsn string) (*sql.DB, error) {
	if dsn == "" {
		dsn = "?threads=4"
	}
	db, err := sql.Open("duckdb", dsn)
	if err != nil {
		return nil, fmt.Errorf("duckdb open: %w", err)
	}
	return db, nil
}

// QueryExec runs Exec on DuckDB (DDL, COPY, inserts into analytical tables).
func QueryExec(ctx context.Context, db *sql.DB, q string, args ...any) (sql.Result, error) {
	if db == nil {
		return nil, errors.New("database: nil duckdb")
	}
	return db.ExecContext(ctx, q, args...)
}

// QueryRows runs QueryContext for SELECT / Arrow-friendly result sets.
func QueryRows(ctx context.Context, db *sql.DB, q string, args ...any) (*sql.Rows, error) {
	if db == nil {
		return nil, errors.New("database: nil duckdb")
	}
	return db.QueryContext(ctx, q, args...)
}
