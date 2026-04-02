// Package database is the data layer: YugabyteDB (PostgreSQL wire), Valkey cache, DuckDB analytics.
package database

// TODO:
// [ ] implement pgx connection pool:
//     NewPool(ctx) (*pgxpool.Pool, error)
//     reads DB_URL from env (RICE_DB_URL)
//     MaxConns from RICE_DB_MAX_CONNS env var (default: 25)
//     MinConns from RICE_DB_MIN_CONNS env var (default: 5)
//     ConnectTimeout from RICE_DB_CONNECT_TIMEOUT_S
// [ ] implement pool health:
//     HealthCheck(ctx, pool) error — pgxpool.Ping()
//     called by bench/health.go on every /health request
// [ ] implement pool instrumentation:
//     OTel span per query via pgx tracer interface
//     pool.Config().Tracer = otelPgxTracer

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// PoolConfig configures the pgx pool against YugabyteDB (PostgreSQL-compatible).
type PoolConfig struct {
	DSN             string
	MaxConns        int32
	MinConns        int32
	MaxConnLifetime time.Duration
	MaxConnIdleTime time.Duration
	HealthTimeout   time.Duration
}

// DefaultPoolConfig returns sensible defaults; override DSN from env / secrets.
func DefaultPoolConfig(dsn string) PoolConfig {
	return PoolConfig{
		DSN:             dsn,
		MaxConns:        32,
		MinConns:        2,
		MaxConnLifetime: time.Hour,
		MaxConnIdleTime: 30 * time.Minute,
		HealthTimeout:   5 * time.Second,
	}
}

// NewPool builds a pgxpool.Pool from config (YugabyteDB / Postgres).
func NewPool(ctx context.Context, cfg PoolConfig) (*pgxpool.Pool, error) {
	if cfg.DSN == "" {
		return nil, errors.New("database: empty DSN")
	}
	pcfg, err := pgxpool.ParseConfig(cfg.DSN)
	if err != nil {
		return nil, fmt.Errorf("parse pool config: %w", err)
	}
	if cfg.MaxConns > 0 {
		pcfg.MaxConns = cfg.MaxConns
	}
	if cfg.MinConns > 0 {
		pcfg.MinConns = cfg.MinConns
	}
	if cfg.MaxConnLifetime > 0 {
		pcfg.MaxConnLifetime = cfg.MaxConnLifetime
	}
	if cfg.MaxConnIdleTime > 0 {
		pcfg.MaxConnIdleTime = cfg.MaxConnIdleTime
	}
	return pgxpool.NewWithConfig(ctx, pcfg)
}

// Ping checks connectivity (use for readiness probes).
func Ping(ctx context.Context, pool *pgxpool.Pool) error {
	if pool == nil {
		return errors.New("database: nil pool")
	}
	return pool.Ping(ctx)
}

// ConnectWithRetry opens the pool and retries on transient startup failures.
func ConnectWithRetry(ctx context.Context, cfg PoolConfig, attempts int, backoff time.Duration) (*pgxpool.Pool, error) {
	var last error
	for i := range attempts {
		if i > 0 {
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			case <-time.After(backoff):
			}
		}
		p, err := NewPool(ctx, cfg)
		if err != nil {
			last = err
			continue
		}
		pingCtx := ctx
		if cfg.HealthTimeout > 0 {
			var cancel context.CancelFunc
			pingCtx, cancel = context.WithTimeout(ctx, cfg.HealthTimeout)
			defer cancel()
		}
		if err := Ping(pingCtx, p); err != nil {
			p.Close()
			last = err
			continue
		}
		return p, nil
	}
	if last == nil {
		last = errors.New("database: connect failed")
	}
	return nil, fmt.Errorf("after %d attempts: %w", attempts, last)
}
