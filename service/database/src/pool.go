// Package database is the data layer: YugabyteDB (PostgreSQL wire), Valkey cache, DuckDB analytics.
package database

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"sync"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/jackc/pgerrcode"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/trace"
	grpcCodes "google.golang.org/grpc/codes"
)

const (
	maxSQLSnippet = 256
	tracerName    = "rice/database"
	meterName     = "rice/database"
)

// Pool wraps a [pgxpool.Pool] with OTel spans, metrics, and SMITH error mapping.
type Pool struct {
	inner *pgxpool.Pool

	tracer trace.Tracer
	hist   metric.Float64Histogram
	errCtr metric.Int64Counter
	reg    metric.Registration
}

// ConnectPostgres opens a production-ready pool from connString (postgres:// or pgx5://).
// Pass [*kit.Context] so traces and metadata propagate; nil uses [context.Background].
// Defaults: MaxConns 20, MinConns 5, MaxConnLifetime 1h, MaxConnIdleTime 30m (overridden by URL when set).
func ConnectPostgres(kctx *kit.Context, connString string) (*Pool, error) {
	return connectPool(kctx, connString, nil)
}

// NewPool builds a [Pool] from [PoolConfig] (same instrumentation as [ConnectPostgres]).
func NewPool(ctx context.Context, cfg PoolConfig) (*Pool, error) {
	if cfg.DSN == "" {
		return nil, kit.Err.Internal("database: empty DSN")
	}
	return connectPool(kit.FromContext(ctx), cfg.DSN, &cfg)
}

func connectPool(kctx *kit.Context, connString string, cfg *PoolConfig) (*Pool, error) {
	dsn := normalizeConnString(connString)
	pcfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, kit.Err.Internal("database: parse pool config").Wrap(err, "pgxpool.ParseConfig")
	}

	if cfg != nil {
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
	} else {
		if pcfg.MaxConns <= 0 {
			pcfg.MaxConns = 20
		}
		if pcfg.MinConns <= 0 {
			pcfg.MinConns = 5
		}
		if pcfg.MaxConnLifetime <= 0 {
			pcfg.MaxConnLifetime = time.Hour
		}
		if pcfg.MaxConnIdleTime <= 0 {
			pcfg.MaxConnIdleTime = 30 * time.Minute
		}
	}

	lg := kit.Logger()
	pcfg.AfterConnect = func(ctx context.Context, c *pgx.Conn) error {
		lg.InfoContext(ctx, "database: new pgx connection")
		if _, err := c.Exec(ctx, `SET application_name = 'rice-smith'`); err != nil {
			return err
		}
		return nil
	}

	ctx := poolContext(kctx)
	inner, err := pgxpool.NewWithConfig(ctx, pcfg)
	if err != nil {
		return nil, kit.Err.Internal("database: open pool").Wrap(err, "pgxpool.NewWithConfig")
	}

	tr := otel.Tracer(tracerName)
	m := otel.Meter(meterName)
	hist, err := m.Float64Histogram("db.client.operation.duration",
		metric.WithUnit("s"),
		metric.WithDescription("Client-side database operation duration"),
	)
	if err != nil {
		inner.Close()
		return nil, kit.Err.Internal("database: otel histogram").Wrap(err, "Float64Histogram")
	}
	errCtr, err := m.Int64Counter("db.client.operation.errors",
		metric.WithDescription("Database operation failures"),
	)
	if err != nil {
		inner.Close()
		return nil, kit.Err.Internal("database: otel counter").Wrap(err, "Int64Counter")
	}

	p := &Pool{inner: inner, tracer: tr, hist: hist, errCtr: errCtr}

	g, err := m.Int64ObservableGauge("db.client.connections.open",
		metric.WithDescription("Total connections tracked by the pool"),
	)
	if err != nil {
		inner.Close()
		return nil, kit.Err.Internal("database: otel gauge").Wrap(err, "Int64ObservableGauge")
	}
	reg, err := m.RegisterCallback(func(_ context.Context, obs metric.Observer) error {
		if p.inner == nil {
			return nil
		}
		st := p.inner.Stat()
		obs.ObserveInt64(g, int64(st.TotalConns()))
		return nil
	}, g)
	if err != nil {
		inner.Close()
		return nil, kit.Err.Internal("database: register metrics callback").Wrap(err, "RegisterCallback")
	}
	p.reg = reg

	return p, nil
}

// PoolConfig configures the pgx pool against YugabyteDB / Postgres.
type PoolConfig struct {
	DSN             string
	MaxConns        int32
	MinConns        int32
	MaxConnLifetime time.Duration
	MaxConnIdleTime time.Duration
	HealthTimeout   time.Duration
}

// DefaultPoolConfig returns defaults aligned with high-concurrency SMITH services.
func DefaultPoolConfig(dsn string) PoolConfig {
	return PoolConfig{
		DSN:             dsn,
		MaxConns:        20,
		MinConns:        5,
		MaxConnLifetime: time.Hour,
		MaxConnIdleTime: 30 * time.Minute,
		HealthTimeout:   5 * time.Second,
	}
}

// ConnectWithRetry opens the pool and retries on transient startup failures.
func ConnectWithRetry(ctx context.Context, cfg PoolConfig, attempts int, backoff time.Duration) (*Pool, error) {
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
		var cancel context.CancelFunc
		if cfg.HealthTimeout > 0 {
			pingCtx, cancel = context.WithTimeout(ctx, cfg.HealthTimeout)
		}
		err = p.Ping(kit.FromContext(pingCtx))
		if cancel != nil {
			cancel()
		}
		if err != nil {
			p.Close()
			last = err
			continue
		}
		return p, nil
	}
	if last == nil {
		last = errors.New("database: connect failed")
	}
	return nil, kit.Err.Internal("database: connect retries exhausted").Wrap(last, "ConnectWithRetry")
}

// Ping verifies the database is reachable.
func (p *Pool) Ping(kctx *kit.Context) error {
	if p == nil || p.inner == nil {
		return kit.Err.Internal("database: nil pool")
	}
	ctx := poolContext(kctx)
	ctx, span := p.startSpan(ctx, "db.Ping", "")
	defer span.End()
	if err := p.inner.Ping(ctx); err != nil {
		p.recordErr(ctx, span, "Ping", err)
		return mapPgxErr(err)
	}
	span.SetStatus(codes.Ok, "")
	return nil
}

// Exec runs a command and records OTel latency / errors.
func (p *Pool) Exec(kctx *kit.Context, sql string, arguments ...any) (pgconn.CommandTag, error) {
	if p == nil || p.inner == nil {
		return pgconn.CommandTag{}, kit.Err.Internal("database: nil pool")
	}
	ctx := poolContext(kctx)
	ctx, span := p.startSpan(ctx, "db.Exec", sql)
	start := time.Now()
	defer span.End()

	tag, err := p.inner.Exec(ctx, sql, arguments...)
	if p.hist != nil {
		p.hist.Record(ctx, time.Since(start).Seconds(),
			metric.WithAttributes(attribute.String("db.operation", "exec")))
	}
	if err != nil {
		p.recordErr(ctx, span, "Exec", err)
		return tag, mapPgxErr(err)
	}
	span.SetStatus(codes.Ok, "")
	return tag, nil
}

// Query runs a query and returns rows; close the rows to end the client span.
func (p *Pool) Query(kctx *kit.Context, sql string, args ...any) (pgx.Rows, error) {
	if p == nil || p.inner == nil {
		return nil, kit.Err.Internal("database: nil pool")
	}
	ctx := poolContext(kctx)
	ctx, span := p.startSpan(ctx, "db.Query", sql)
	start := time.Now()
	rows, err := p.inner.Query(ctx, sql, args...)
	if err != nil {
		if p.hist != nil {
			p.hist.Record(ctx, time.Since(start).Seconds(),
				metric.WithAttributes(attribute.String("db.operation", "query")))
		}
		p.recordErr(ctx, span, "Query", err)
		span.End()
		return nil, mapPgxErr(err)
	}
	return &tracedRows{Rows: rows, span: span, start: start, pool: p, op: "query"}, nil
}

// QueryRow returns a single row; call [pgx.Row.Scan] to finish the span.
func (p *Pool) QueryRow(kctx *kit.Context, sql string, args ...any) pgx.Row {
	if p == nil || p.inner == nil {
		return errRow{err: kit.Err.Internal("database: nil pool")}
	}
	ctx := poolContext(kctx)
	ctx, span := p.startSpan(ctx, "db.QueryRow", sql)
	row := p.inner.QueryRow(ctx, sql, args...)
	return &tracedRow{Row: row, span: span, start: time.Now(), pool: p}
}

// Close shuts down the pool and unregisters OTel callbacks.
func (p *Pool) Close() {
	if p == nil {
		return
	}
	if p.reg != nil {
		_ = p.reg.Unregister()
		p.reg = nil
	}
	if p.inner != nil {
		p.inner.Close()
		p.inner = nil
	}
}

func (p *Pool) startSpan(ctx context.Context, opName, sql string) (context.Context, trace.Span) {
	attrs := []attribute.KeyValue{
		attribute.String("db.system", "postgresql"),
		attribute.String("db.operation", opName),
	}
	if sql != "" {
		attrs = append(attrs, attribute.String("db.statement", truncateSQL(sql)))
	}
	if p.inner != nil {
		st := p.inner.Stat()
		cfg := p.inner.Config()
		attrs = append(attrs,
			attribute.Int("db.pool.max_conns", int(cfg.MaxConns)),
			attribute.Int("db.pool.total", int(st.TotalConns())),
			attribute.Int("db.pool.idle", int(st.IdleConns())),
			attribute.Int("db.pool.acquired", int(st.AcquiredConns())),
		)
	}
	return p.tracer.Start(ctx, opName, trace.WithSpanKind(trace.SpanKindClient), trace.WithAttributes(attrs...))
}

func (p *Pool) recordErr(ctx context.Context, span trace.Span, op string, err error) {
	if span != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
	}
	if p.errCtr != nil {
		p.errCtr.Add(ctx, 1, metric.WithAttributes(attribute.String("db.operation", op)))
	}
}

type tracedRows struct {
	pgx.Rows
	once  sync.Once
	span  trace.Span
	start time.Time
	pool  *Pool
	op    string
}

func (r *tracedRows) Next() bool {
	ok := r.Rows.Next()
	if !ok {
		r.finish()
	}
	return ok
}

func (r *tracedRows) Close() {
	r.Rows.Close()
	r.finish()
}

func (r *tracedRows) finish() {
	r.once.Do(func() {
		if r.pool != nil && r.pool.hist != nil {
			ctx := context.Background()
			r.pool.hist.Record(ctx, time.Since(r.start).Seconds(),
				metric.WithAttributes(attribute.String("db.operation", r.op)))
		}
		if r.span != nil {
			if err := r.Rows.Err(); err != nil {
				r.span.RecordError(err)
				r.span.SetStatus(codes.Error, err.Error())
				if r.pool != nil && r.pool.errCtr != nil {
					r.pool.errCtr.Add(context.Background(), 1,
						metric.WithAttributes(attribute.String("db.operation", r.op)))
				}
			} else {
				r.span.SetStatus(codes.Ok, "")
			}
			r.span.End()
			r.span = nil
		}
	})
}

type tracedRow struct {
	Row   pgx.Row
	span  trace.Span
	start time.Time
	pool  *Pool
}

func (r *tracedRow) Scan(dest ...any) error {
	err := r.Row.Scan(dest...)
	if r.pool != nil && r.pool.hist != nil {
		ctx := context.Background()
		r.pool.hist.Record(ctx, time.Since(r.start).Seconds(),
			metric.WithAttributes(attribute.String("db.operation", "query_row")))
	}
	if r.span != nil {
		if err != nil && !errors.Is(err, pgx.ErrNoRows) {
			r.span.RecordError(err)
			r.span.SetStatus(codes.Error, err.Error())
			if r.pool != nil && r.pool.errCtr != nil {
				r.pool.errCtr.Add(context.Background(), 1,
					metric.WithAttributes(attribute.String("db.operation", "query_row")))
			}
		} else {
			r.span.SetStatus(codes.Ok, "")
		}
		r.span.End()
		r.span = nil
	}
	if err != nil {
		return mapPgxErr(err)
	}
	return nil
}

type errRow struct {
	err error
}

func (r errRow) Scan(dest ...any) error { return r.err }

func poolContext(kctx *kit.Context) context.Context {
	if kctx == nil {
		return context.Background()
	}
	return kctx
}

func normalizeConnString(s string) string {
	s = strings.TrimSpace(s)
	return strings.Replace(s, "pgx5://", "postgres://", 1)
}

func truncateSQL(sql string) string {
	if len(sql) <= maxSQLSnippet {
		return sql
	}
	return sql[:maxSQLSnippet]
}

func mapPgxErr(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, pgx.ErrNoRows) {
		return err
	}
	var pe *pgconn.PgError
	if errors.As(err, &pe) {
		switch pe.Code {
		case pgerrcode.UniqueViolation:
			return kit.Err.Conflict(pe.Message).Wrap(err, "postgres")
		case pgerrcode.ForeignKeyViolation:
			return kit.Err.BadRequest(pe.Message).Wrap(err, "postgres")
		case pgerrcode.NotNullViolation, pgerrcode.CheckViolation:
			return kit.Err.BadRequest(pe.Message).Wrap(err, "postgres")
		case pgerrcode.SerializationFailure, pgerrcode.DeadlockDetected:
			return kit.New("TRANSIENT", pe.Message, http.StatusServiceUnavailable, grpcCodes.Aborted).Wrap(err, "postgres")
		}
	}
	return kit.Err.Internal("database operation failed").Wrap(err, "pgx")
}
