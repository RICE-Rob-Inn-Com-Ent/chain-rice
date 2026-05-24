package database

import (
	"context"
	"errors"
	"fmt"
	"regexp"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/jackc/pgerrcode"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"go.opentelemetry.io/otel/codes"
)

const maxSerializationRetries = 3

var savepointNameRe = regexp.MustCompile(`^[a-zA-Z_][a-zA-Z0-9_]*$`)

// Transaction runs fn inside a single ACID transaction (commit on success, rollback on error or panic).
// Serialization failures (SQLSTATE 40001) retry the whole transaction up to [maxSerializationRetries] times.
// Uses [poolContext] so the same [*kit.Context] / trace continues through [pgxpool.Pool.Begin].
func (p *Pool) Transaction(kctx *kit.Context, fn func(tx pgx.Tx) error) error {
	if p == nil || p.inner == nil {
		return kit.Err.Internal("database: nil pool")
	}
	ctx := poolContext(kctx)
	ctx, span := p.startSpan(ctx, "db.Transaction", "")
	defer span.End()

	var lastErr error
	for attempt := 0; attempt < maxSerializationRetries; attempt++ {
		if attempt > 0 {
			kit.Logger().InfoContext(ctx, "database: transaction retry after serialization",
				"attempt", attempt,
			)
		}
		err := p.execOneTx(ctx, fn)
		if err == nil {
			span.SetStatus(codes.Ok, "")
			return nil
		}
		lastErr = err
		if !isSerializationFailure(err) {
			span.RecordError(err)
			span.SetStatus(codes.Error, err.Error())
			return err
		}
	}
	span.RecordError(lastErr)
	span.SetStatus(codes.Error, lastErr.Error())
	return lastErr
}

func (p *Pool) execOneTx(ctx context.Context, fn func(pgx.Tx) error) (err error) {
	tx, beginErr := p.inner.Begin(ctx)
	if beginErr != nil {
		return mapPgxErr(beginErr)
	}

	committed := false
	defer func() {
		if r := recover(); r != nil {
			if !committed {
				_ = tx.Rollback(context.WithoutCancel(ctx))
			}
			switch x := r.(type) {
			case error:
				err = kit.Err.Internal("database: transaction panic").Wrap(x, "panic")
			default:
				err = kit.Err.Internal("database: transaction panic").
					WithDetails(map[string]any{"recover": fmt.Sprint(x)})
			}
			return
		}
		if !committed {
			_ = tx.Rollback(context.WithoutCancel(ctx))
		}
	}()

	if err = fn(tx); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return mapPgxErr(err)
	}
	committed = true
	return nil
}

func isSerializationFailure(err error) bool {
	var pe *pgconn.PgError
	return errors.As(err, &pe) && pe.Code == pgerrcode.SerializationFailure
}

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
