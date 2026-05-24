package database

// Query layer: hand-written + sqlc-generated SQL behind a single [Queries] interface.
//
// # sqlc workflow
//
// 1. Add queries under queries/ and run `sqlc generate` from the service/database module root (sqlc.yaml).
// 2. Point sqlc `emit_interface: true` if you want a second interface in the gen package, or
//    paste each generated method signature into [Queries] below, rewriting:
//      context.Context → *kit.Context
//      github.com/google/uuid.UUID → kit.UUID
//      []byte / string for jsonb columns → SMITH domain structs (see sqlc override notes).
// 3. Implement those methods on [queriesRuntime] by delegating to the sqlc struct:
//      return q.sqlc.GetUser(poolContext(ctx), id.Std())
//
// # Type overrides (sqlc.yaml)
//
// Use `overrides` so Postgres maps to SMITH types, for example:
//
//	version: "2"
//	sql:
//	  - engine: "postgresql"
//	    schema: "schema.sql"
//	    queries: "queries.sql"
//	    gen:
//	      go:
//	        package: "sqlcgen"
//	        out: "sqlcgen"
//	        sql_package: "pgx/v5"
//	        emit_interface: true
//	        overrides:
//	          - db_type: "uuid"
//	            go_type:
//	              import: "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
//	              type: "UUID"
//	          - db_type: "jsonb"
//	            go_type:
//	              import: "github.com/RICE-Rob-Inn-Com-Ent/rice/service/yourpkg"
//	              type: "Metadata"   # or use struct name for domain JSON

import (
	"context"
	"fmt"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// DBTX is the minimal surface sqlc expects for pgx/v5; both [*pgxpool.Pool] and [pgx.Tx] satisfy it.
type DBTX interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

// Queries is the application-facing contract. Handlers depend on this interface, not on Postgres
// directly. Re-instantiate with [Queries.WithTx] (or [NewQueries] on a [pgx.Tx]) inside transactions.
//
// sqlc: after codegen, add one method per sqlc query here (kit.Context + kit.UUID + domain types).
type Queries interface {
	// WithTx returns the same logical API using tx. Prefer this over [NewQueries](tx) when you
	// already hold a [Queries] from the pool.
	WithTx(tx pgx.Tx) Queries

	// Ping checks connectivity (optional; remove if you prefer a pure sqlc-only interface).
	Ping(ctx *kit.Context) error

	// sqlc:region begin — paste generated method signatures below (do not delete this comment).
	//
	// Example placeholders (delete when real queries exist):
	//   GetUserByID(ctx *kit.Context, id kit.UUID) (UserRow, error)
	//   ListUsersByOrg(ctx *kit.Context, orgID kit.UUID) ([]UserRow, error)
	//   CreateUser(ctx *kit.Context, arg CreateUserParams) (UserRow, error)
	//
	// sqlc:region end
}

// queriesRuntime is the default [Queries] implementation until sqlc wiring is merged.
// Embed or compose the sqlc-generated *sqlcgen.Queries here and forward each interface method.
type queriesRuntime struct {
	db DBTX
	// sqlc: add `sqlc *sqlcgen.Queries` and set in NewQueries via sqlcgen.New(db).
}

// NewQueries wraps a pool or transaction for typed queries. Pass the same [DBTX] sqlc uses
// ([*pgxpool.Pool] for normal work, [pgx.Tx] inside [Pool.Transaction]).
// The return type is the [Queries] interface (not *Queries): avoid pointers-to-interface in APIs.
func NewQueries(db DBTX) Queries {
	if db == nil {
		return &queriesRuntime{}
	}
	return &queriesRuntime{db: db}
}

func (q *queriesRuntime) WithTx(tx pgx.Tx) Queries {
	if tx == nil {
		return q
	}
	return &queriesRuntime{db: tx}
}

func (q *queriesRuntime) Ping(ctx *kit.Context) error {
	if q == nil || q.db == nil {
		return kit.Err.Internal("database: nil query db")
	}
	_, err := q.db.Exec(poolContext(ctx), "SELECT 1")
	return mapPgxErr(err)
}

// --- mock (tests) ---

// mockQueries is a stub [Queries] for tests; extend fields when new interface methods are added.
type mockQueries struct {
	pingFn func(ctx *kit.Context) error
}

// MockQueriesOption configures [NewMockQueries].
type MockQueriesOption func(*mockQueries)

// MockQueriesPing sets the implementation for [Queries.Ping].
func MockQueriesPing(fn func(ctx *kit.Context) error) MockQueriesOption {
	return func(m *mockQueries) { m.pingFn = fn }
}

// NewMockQueries returns a [Queries] with safe defaults (Ping succeeds unless overridden).
func NewMockQueries(opts ...MockQueriesOption) Queries {
	m := &mockQueries{}
	for _, o := range opts {
		o(m)
	}
	return m
}

// MockQueries returns a no-op [Queries] stub (same as [NewMockQueries] with no options).
func MockQueries() Queries {
	return NewMockQueries()
}

func (m *mockQueries) WithTx(tx pgx.Tx) Queries {
	_ = tx
	return m
}

func (m *mockQueries) Ping(ctx *kit.Context) error {
	if m == nil {
		return nil
	}
	if m.pingFn != nil {
		return m.pingFn(ctx)
	}
	return nil
}

var (
	_ Queries = (*queriesRuntime)(nil)
	_ Queries = (*mockQueries)(nil)
)

// QueryExecutor is the façade for ad-hoc SQL and bulk helpers on a pool (not the typed [Queries] API).
type QueryExecutor struct {
	Pool *pgxpool.Pool
}

// Exec runs a command (INSERT/UPDATE/DELETE) without returning rows.
func (q *QueryExecutor) Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error) {
	if q == nil || q.Pool == nil {
		return pgconn.CommandTag{}, fmt.Errorf("database: nil query executor")
	}
	return q.Pool.Exec(ctx, sql, args...)
}

// Query runs a query and returns rows (caller must Close the Rows).
func (q *QueryExecutor) Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error) {
	if q == nil || q.Pool == nil {
		return nil, fmt.Errorf("database: nil query executor")
	}
	return q.Pool.Query(ctx, sql, args...)
}

// QueryRow runs a query expected to return at most one row.
func (q *QueryExecutor) QueryRow(ctx context.Context, sql string, args ...any) pgx.Row {
	return q.Pool.QueryRow(ctx, sql, args...)
}

// CopyFrom uses the PostgreSQL COPY protocol for bulk loads (YugabyteDB-compatible).
func (q *QueryExecutor) CopyFrom(ctx context.Context, tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	if q == nil || q.Pool == nil {
		return 0, fmt.Errorf("database: nil query executor")
	}
	return q.Pool.CopyFrom(ctx, tableName, columnNames, rowSrc)
}

// Batch collects statements for a single round-trip (pgx batch).
func (q *QueryExecutor) Batch(ctx context.Context, b *pgx.Batch) pgx.BatchResults {
	if q == nil || q.Pool == nil {
		return nil
	}
	return q.Pool.SendBatch(ctx, b)
}
