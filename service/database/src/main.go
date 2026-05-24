package database

// Package database orchestrates Postgres (Yugabyte), Redis/Valkey, DuckDB, sessions, pub/sub,
// rate limiting, and the typed [Queries] façade for SMITH / .rice services.

import (
	"errors"
	"fmt"
	"strings"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"golang.org/x/sync/errgroup"
)

// Config wires every subsystem for [NewDatabase].
type Config struct {
	PostgresDSN    string
	MigrationsPath string // file:// or embed:// (see [RegisterEmbedMigrations]); ignored when [Config.SkipMigrate] is true
	SkipMigrate    bool

	// Pool settings; if [PoolConfig.DSN] is empty, [PostgresDSN] is used. Zero-valued limits get [DefaultPoolConfig].
	Pool PoolConfig

	RedisAddr     string
	RedisPassword string
	RedisDB       int

	// DuckPath is passed to [ConnectDuck] (e.g. file path or ":memory:"). Empty defaults to ":memory:".
	DuckPath string

	// Optional Redis key namespaces (see [SessionManager.Prefix], [RateLimiter.Prefix]).
	SessionPrefix   string
	RateLimitPrefix string
}

func (c *Config) validate() error {
	if c == nil {
		return kit.BadRequest("database: nil config")
	}
	if strings.TrimSpace(c.PostgresDSN) == "" {
		return kit.BadRequest("database: PostgresDSN is required")
	}
	if !c.SkipMigrate && strings.TrimSpace(c.MigrationsPath) == "" {
		return kit.BadRequest("database: MigrationsPath is required unless SkipMigrate is true")
	}
	if strings.TrimSpace(c.RedisAddr) == "" {
		return kit.BadRequest("database: RedisAddr is required")
	}
	return nil
}

func mergePoolConfig(cfg *Config) PoolConfig {
	pc := cfg.Pool
	if strings.TrimSpace(pc.DSN) == "" {
		pc.DSN = cfg.PostgresDSN
	}
	def := DefaultPoolConfig(pc.DSN)
	if pc.MaxConns <= 0 {
		pc.MaxConns = def.MaxConns
	}
	if pc.MinConns <= 0 {
		pc.MinConns = def.MinConns
	}
	if pc.MaxConnLifetime <= 0 {
		pc.MaxConnLifetime = def.MaxConnLifetime
	}
	if pc.MaxConnIdleTime <= 0 {
		pc.MaxConnIdleTime = def.MaxConnIdleTime
	}
	if pc.HealthTimeout <= 0 {
		pc.HealthTimeout = def.HealthTimeout
	}
	return pc
}

// migrateConnectionURL converts a normal postgres DSN into golang-migrate's pgx5 form.
func migrateConnectionURL(dsn string) string {
	s := strings.TrimSpace(dsn)
	s = strings.Replace(s, "postgres://", "pgx5://", 1)
	return s
}

// Database is the root handle for SMITH data infrastructure.
type Database struct {
	Pool    *Pool
	Cache   *Cache
	Duck    *Duck
	PubSub  *PubSub
	Session *SessionManager
	Limit   *RateLimiter
	Queries Queries
}

// NewDatabase runs [Migrate] first, then opens Postgres, Redis, and DuckDB concurrently.
// Redis-backed facades ([Cache], [PubSub], [SessionManager], [RateLimiter]) share one client.
// [Queries] is bound to the pool for typed SQL (sqlc) access via [Database.Queries].
func NewDatabase(ctx *kit.Context, cfg Config) (*Database, error) {
	if err := cfg.validate(); err != nil {
		return nil, err
	}

	if !cfg.SkipMigrate {
		migURL := migrateConnectionURL(cfg.PostgresDSN)
		if err := Migrate(migURL, cfg.MigrationsPath); err != nil {
			return nil, err
		}
	}

	pc := mergePoolConfig(&cfg)
	base := poolContext(ctx)
	g, gctx := errgroup.WithContext(base)

	var pool *Pool
	var cache *Cache
	var duck *Duck

	g.Go(func() error {
		p, err := NewPool(gctx, pc)
		if err != nil {
			return err
		}
		pool = p
		return nil
	})

	g.Go(func() error {
		c := NewCache(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)
		if c.Client == nil {
			return kit.Err.Internal("database: redis client init failed")
		}
		if err := c.Client.Ping(gctx).Err(); err != nil {
			return kit.Err.Internal("database: redis ping failed").Wrap(err, "redis.Ping")
		}
		cache = c
		return nil
	})

	g.Go(func() error {
		path := strings.TrimSpace(cfg.DuckPath)
		if path == "" {
			path = ":memory:"
		}
		d, err := ConnectDuck(path)
		if err != nil {
			return err
		}
		duck = d
		return nil
	})

	if err := g.Wait(); err != nil {
		if pool != nil {
			pool.Close()
		}
		if cache != nil && cache.Client != nil {
			_ = cache.Client.Close()
		}
		if duck != nil {
			_ = duck.Close()
		}
		return nil, err
	}

	pub := NewPubSubFromCache(cache)
	sess := NewSessionManagerFromCache(cache)
	sess.Prefix = cfg.SessionPrefix
	lim := NewRateLimiterFromCache(cache)
	lim.Prefix = cfg.RateLimitPrefix
	q := NewQueries(pool.inner)

	return &Database{
		Pool:    pool,
		Cache:   cache,
		Duck:    duck,
		PubSub:  pub,
		Session: sess,
		Limit:   lim,
		Queries: q,
	}, nil
}

// Close releases Postgres, Redis, and DuckDB. Pub/sub, session, and limiter share the Redis client
// closed via [Cache.Client].
func (db *Database) Close(ctx *kit.Context) error {
	if db == nil {
		return nil
	}
	lg := kit.Logger()
	std := poolContext(ctx)
	var errs error

	if db.Duck != nil {
		lg.InfoContext(std, "database: closing duckdb")
		errs = errors.Join(errs, db.Duck.Close())
		db.Duck = nil
	}

	if db.Cache != nil && db.Cache.Client != nil {
		lg.InfoContext(std, "database: closing redis")
		errs = errors.Join(errs, db.Cache.Client.Close())
		db.Cache.Client = nil
	}

	if db.Pool != nil {
		lg.InfoContext(std, "database: closing postgres pool")
		db.Pool.Close()
		db.Pool = nil
	}

	db.PubSub = nil
	db.Session = nil
	db.Limit = nil
	db.Queries = nil

	if errs != nil {
		lg.ErrorContext(std, "database: close completed with errors", "err", errs)
	} else {
		lg.InfoContext(std, "database: close complete")
	}
	return errs
}

// Health probes each subsystem and returns human-readable status lines (not an error map).
func (db *Database) Health(ctx *kit.Context) map[string]string {
	out := make(map[string]string)
	if db == nil {
		out["database"] = "nil"
		return out
	}
	kctx := ctx

	if db.Pool != nil {
		t0 := time.Now()
		if err := db.Pool.Ping(kctx); err != nil {
			out["postgres"] = "error: " + err.Error()
		} else {
			out["postgres"] = fmt.Sprintf("ok %dms", time.Since(t0).Milliseconds())
		}
	} else {
		out["postgres"] = "unconfigured"
	}

	if db.Cache != nil && db.Cache.Client != nil {
		t0 := time.Now()
		if err := db.Cache.Client.Ping(poolContext(ctx)).Err(); err != nil {
			out["redis"] = "error: " + err.Error()
		} else {
			ms := time.Since(t0).Milliseconds()
			out["redis"] = fmt.Sprintf("ok %dms", ms)
			out["pubsub"] = fmt.Sprintf("ok (shared) %dms", ms)
			out["session"] = fmt.Sprintf("ok (shared) %dms", ms)
			out["limiter"] = fmt.Sprintf("ok (shared) %dms", ms)
		}
	} else {
		out["redis"] = "unconfigured"
		out["pubsub"] = "unconfigured"
		out["session"] = "unconfigured"
		out["limiter"] = "unconfigured"
	}

	if db.Duck != nil && db.Duck.DB() != nil {
		t0 := time.Now()
		if err := db.Duck.DB().PingContext(poolContext(ctx)); err != nil {
			out["duckdb"] = "error: " + err.Error()
		} else {
			out["duckdb"] = fmt.Sprintf("ok %dms", time.Since(t0).Milliseconds())
		}
	} else {
		out["duckdb"] = "unconfigured"
	}

	if db.Queries != nil {
		t0 := time.Now()
		if err := db.Queries.Ping(kctx); err != nil {
			out["queries"] = "error: " + err.Error()
		} else {
			out["queries"] = fmt.Sprintf("ok %dms", time.Since(t0).Milliseconds())
		}
	} else {
		out["queries"] = "unconfigured"
	}

	return out
}
