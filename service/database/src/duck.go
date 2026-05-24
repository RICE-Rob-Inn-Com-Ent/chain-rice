package database

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"errors"
	"fmt"
	"net/http"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/marcboeker/go-duckdb"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	grpcCodes "google.golang.org/grpc/codes"
)

// DuckConfig tunes DuckDB for OLAP workloads (memory, parallelism, pool size).
type DuckConfig struct {
	MemoryLimit            string // e.g. "2GB"; empty uses default below
	Threads                int    // 0 = default below
	PreserveInsertionOrder bool   // default false for throughput
	MaxOpenConns           int    // 0 = min(8, GOMAXPROCS*2)
}

// DefaultDuckConfig returns SMITH defaults aligned with [ConnectDuck] PRAGMAs.
func DefaultDuckConfig() DuckConfig {
	n := runtime.GOMAXPROCS(0) * 2
	if n < 8 {
		n = 8
	}
	return DuckConfig{
		MemoryLimit:            "2GB",
		Threads:                4,
		PreserveInsertionOrder: false,
		MaxOpenConns:           n,
	}
}

// Duck wraps embedded DuckDB behind [database/sql] for OLAP and vector-friendly analytics.
type Duck struct {
	db  *sql.DB
	cfg DuckConfig

	// appenderSQL holds a dedicated pooled connection for [Duck.Appender] so callers receive
	// a bare [*duckdb.Appender] without leaking a [*sql.Conn]. Released in [Duck.Close].
	appenderSQL *sql.Conn
	appenderDrv driver.Conn

	mu sync.RWMutex // coordinates [Close] with readers; [sql.DB] remains safe for concurrent Query.

	// appenderBusy serializes native appenders on the single appender lane (one live appender per [Duck]).
	appenderBusy atomic.Bool
}

// ConnectDuck opens DuckDB at path (use ":memory:" for a transient database).
// Applies performance PRAGMAs, loads httpfs per connection, and returns a thread-safe [Duck].
func ConnectDuck(path string) (*Duck, error) {
	return ConnectDuckWithConfig(path, DefaultDuckConfig())
}

// ConnectDuckWithConfig is like [ConnectDuck] with explicit [DuckConfig].
func ConnectDuckWithConfig(path string, cfg DuckConfig) (*Duck, error) {
	dsn := strings.TrimSpace(path)
	if dsn == "" {
		dsn = ":memory:"
	}

	connector, err := duckdb.NewConnector(dsn, duckConnInit(&cfg))
	if err != nil {
		return nil, duckErr(err, "duckdb.NewConnector")
	}

	db := sql.OpenDB(connector)
	max := cfg.MaxOpenConns
	if max <= 0 {
		max = DefaultDuckConfig().MaxOpenConns
	}
	// Reserve one extra slot for the dedicated appender lane.
	db.SetMaxOpenConns(max + 1)
	db.SetMaxIdleConns(max + 1)
	db.SetConnMaxLifetime(0)

	d := &Duck{db: db, cfg: cfg}
	if err := d.warmupPragmas(context.Background()); err != nil {
		_ = db.Close()
		return nil, err
	}
	if err := d.initAppenderLane(context.Background()); err != nil {
		_ = db.Close()
		return nil, err
	}
	return d, nil
}

func (d *Duck) initAppenderLane(ctx context.Context) error {
	c, err := d.db.Conn(ctx)
	if err != nil {
		return duckErr(err, "initAppenderLane.Conn")
	}
	err = c.Raw(func(dc any) error {
		dr, ok := dc.(driver.Conn)
		if !ok {
			return errors.New("duck: appender lane is not a driver.Conn")
		}
		d.appenderDrv = dr
		return nil
	})
	if err != nil {
		_ = c.Close()
		return duckErr(err, "initAppenderLane.Raw")
	}
	d.appenderSQL = c
	return nil
}

func duckConnInit(cfg *DuckConfig) func(driver.ExecerContext) error {
	mem := cfg.MemoryLimit
	if mem == "" {
		mem = "2GB"
	}
	threads := cfg.Threads
	if threads <= 0 {
		threads = 4
	}
	preserve := "false"
	if cfg.PreserveInsertionOrder {
		preserve = "true"
	}

	return func(ec driver.ExecerContext) error {
		ctx := context.Background()
		// DuckDB session tuning (SET is the supported surface; PRAGMA aliases exist for some keys).
		initStmts := []string{
			fmt.Sprintf(`SET memory_limit='%s'`, escapeSingleQuoted(mem)),
			fmt.Sprintf(`SET threads=%d`, threads),
			fmt.Sprintf(`SET preserve_insertion_order=%s`, preserve),
			// PRAGMA form for operators expecting classic DuckDB tuning knobs:
			fmt.Sprintf(`PRAGMA threads=%d`, threads),
		}
		for _, q := range initStmts {
			if _, err := ec.ExecContext(ctx, q, nil); err != nil {
				return duckErr(err, "duck.init: "+q)
			}
		}
		// Best-effort install; LOAD is required for remote HTTP/S3 reads.
		if _, err := ec.ExecContext(ctx, `INSTALL httpfs;`, nil); err != nil {
			kit.Logger().InfoContext(ctx, "duck: INSTALL httpfs skipped", "error", err)
		}
		if _, err := ec.ExecContext(ctx, `LOAD httpfs;`, nil); err != nil {
			return duckErr(err, "duck.init: LOAD httpfs")
		}
		return nil
	}
}

func escapeSingleQuoted(s string) string {
	return strings.ReplaceAll(s, `'`, `''`)
}

func (d *Duck) warmupPragmas(ctx context.Context) error {
	// Prime a connection so callers see failures early; per-connection init already ran via connector.
	if d == nil || d.db == nil {
		return duckErr(errors.New("nil duck"), "warmupPragmas")
	}
	if err := d.db.PingContext(ctx); err != nil {
		return duckErr(err, "warmupPragmas.Ping")
	}
	return nil
}

// DB returns the underlying [*sql.DB] for advanced use (keep [Close] on [Duck] as the primary lifecycle).
func (d *Duck) DB() *sql.DB {
	if d == nil {
		return nil
	}
	return d.db
}

// QueryVector runs an analytical query with OTel client spans and [kit.Context] propagation.
func (d *Duck) QueryVector(kctx *kit.Context, query string, args ...any) (*sql.Rows, error) {
	if d == nil || d.db == nil {
		return nil, duckErr(errors.New("nil duck"), "QueryVector")
	}
	ctx := poolContext(kctx)
	ctx, span := otel.Tracer(tracerName).Start(ctx, "duck.QueryVector",
		trace.WithSpanKind(trace.SpanKindClient),
		trace.WithAttributes(
			attribute.String("db.system", "duckdb"),
			attribute.String("db.operation", "QueryVector"),
			attribute.String("db.statement", truncateSQL(query)),
		),
	)
	defer span.End()

	rows, err := d.db.QueryContext(ctx, query, args...)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, duckErr(err, "QueryVector")
	}
	span.SetStatus(codes.Ok, "")
	return rows, nil
}

// QueryJSON reads a JSON file via DuckDB [read_json_auto].
func (d *Duck) QueryJSON(kctx *kit.Context, filePath string) (*sql.Rows, error) {
	if strings.TrimSpace(filePath) == "" {
		return nil, duckErr(errors.New("empty file path"), "QueryJSON")
	}
	// Parameterized path avoids SQL injection from file names.
	const q = `SELECT * FROM read_json_auto($1)`
	return d.QueryVector(kctx, q, filePath)
}

// Appender creates a native DuckDB [duckdb.Appender] for fast bulk loads into table (default schema).
// Call [duckdb.Appender.Close] when finished, then [Duck.ReleaseAppender] before opening another appender.
func (d *Duck) Appender(table string) (*duckdb.Appender, error) {
	if d == nil || d.db == nil {
		return nil, duckErr(errors.New("nil duck"), "Appender")
	}
	if d.appenderDrv == nil {
		return nil, duckErr(errors.New("nil appender lane"), "Appender")
	}
	table = strings.TrimSpace(table)
	if table == "" {
		return nil, duckErr(errors.New("empty table"), "Appender")
	}
	if !d.appenderBusy.CompareAndSwap(false, true) {
		return nil, duckErr(errors.New("duck: appender lane busy (call ReleaseAppender after Appender.Close)"), "Appender")
	}
	app, err := duckdb.NewAppenderFromConn(d.appenderDrv, "", table)
	if err != nil {
		d.appenderBusy.Store(false)
		return nil, duckErr(err, "Appender.NewAppenderFromConn")
	}
	return app, nil
}

// ReleaseAppender marks the appender lane free after [duckdb.Appender.Close] has returned.
func (d *Duck) ReleaseAppender() {
	if d == nil {
		return
	}
	d.appenderBusy.Store(false)
}

// Close closes the database and releases resources.
func (d *Duck) Close() error {
	if d == nil || d.db == nil {
		return nil
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	var errs error
	if d.appenderSQL != nil {
		errs = errors.Join(errs, d.appenderSQL.Close())
		d.appenderSQL = nil
		d.appenderDrv = nil
	}
	d.appenderBusy.Store(false)
	if err := d.db.Close(); err != nil {
		errs = errors.Join(errs, duckErr(err, "Close"))
	}
	d.db = nil
	return errs
}

func duckErr(err error, op string) error {
	if err == nil {
		return nil
	}
	return kit.New("DATABASE_DUCK_FAILED", err.Error(), http.StatusInternalServerError, grpcCodes.Internal).Wrap(err, op)
}

// QueryExec runs Exec on DuckDB (DDL, COPY, etc.) using [context.Context].
func QueryExec(ctx context.Context, db *sql.DB, q string, args ...any) (sql.Result, error) {
	if db == nil {
		return nil, errors.New("database: nil duckdb")
	}
	return db.ExecContext(ctx, q, args...)
}

// QueryRows runs QueryContext for SELECT-style workloads.
func QueryRows(ctx context.Context, db *sql.DB, q string, args ...any) (*sql.Rows, error) {
	if db == nil {
		return nil, errors.New("database: nil duckdb")
	}
	return db.QueryContext(ctx, q, args...)
}

// DuckLegacy opens DuckDB with driver defaults (deprecated: prefer [ConnectDuck]).
func DuckLegacy(dsn string) (*sql.DB, error) {
	if dsn == "" {
		dsn = "?threads=4"
	}
	db, err := sql.Open("duckdb", dsn)
	if err != nil {
		return nil, fmt.Errorf("duckdb open: %w", err)
	}
	return db, nil
}
