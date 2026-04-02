package bench

// TODO:
// [ ] implement Trino client setup:
//     NewTrinoClient() *trino.Conn
//     reads RICE_TRINO_URL from env
//     reads RICE_TRINO_USER, RICE_TRINO_CATALOG from env
// [ ] implement federated query execution:
//     Query(ctx, sql string) (*sql.Rows, error)
//     federates across: YugabyteDB, DuckDB, external sources
// [ ] implement query instrumentation:
//     every Trino query gets OTel span
//     span attributes: query_hash, catalog, schema, row_count

import (
	"context"
	"database/sql"

	_ "github.com/trinodb/trino-go-client/trino"
)

// OpenTrino opens a database/sql handle using the Trino driver (federated SQL / cross-catalog queries).
// DSN example: "http://user@trino.example:8080?catalog=hive&schema=default"
func OpenTrino(dsn string) (*sql.DB, error) {
	return sql.Open("trino", dsn)
}

// PingTrino verifies connectivity (use in readiness probes).
func PingTrino(ctx context.Context, db *sql.DB) error {
	if db == nil {
		return sql.ErrConnDone
	}
	return db.PingContext(ctx)
}

// QueryTrino runs a query and returns rows for the caller to scan.
func QueryTrino(ctx context.Context, db *sql.DB, query string, args ...any) (*sql.Rows, error) {
	return db.QueryContext(ctx, query, args...)
}
