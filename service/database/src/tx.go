package database

// TODO:
// [ ] implement transaction helpers:
//     WithTx(ctx, pool, fn func(pgx.Tx) error) error
//     automatic rollback on error, commit on success
// [ ] implement retry transaction:
//     WithRetryTx(ctx, pool, fn, maxRetries) error
//     YugabyteDB serializable isolation → retry on 40001
//     max retries from RICE_DB_TX_RETRIES env var (default: 3)
// [ ] implement distributed transaction:
//     WithSagaTx — compensating transactions pattern
//     each step registers compensation function
//     on failure: execute compensations in reverse order

import (
	"context"
	"fmt"
	"regexp"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var savepointNameRe = regexp.MustCompile(`^[a-zA-Z_][a-zA-Z0-9_]*$`)

// WithTx runs fn inside a single transaction (Commit on success, Rollback on error).
func WithTx(ctx context.Context, pool *pgxpool.Pool, fn func(pgx.Tx) error) error {
	if pool == nil {
		return fmt.Errorf("database: nil pool")
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if err := fn(tx); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// WithSavepoint runs fn inside a named SAVEPOINT for partial rollback.
func WithSavepoint(ctx context.Context, tx pgx.Tx, name string, fn func() error) error {
	if !savepointNameRe.MatchString(name) {
		return fmt.Errorf("database: invalid savepoint name %q", name)
	}
	if _, err := tx.Exec(ctx, "SAVEPOINT "+name); err != nil {
		return err
	}
	if err := fn(); err != nil {
		_, _ = tx.Exec(ctx, "ROLLBACK TO SAVEPOINT "+name)
		return err
	}
	_, err := tx.Exec(ctx, "RELEASE SAVEPOINT "+name)
	return err
}

// NestedTx documents the pattern: outer WithTx + inner WithSavepoint (Postgres savepoints).
type NestedTx struct {
	Tx pgx.Tx
}
