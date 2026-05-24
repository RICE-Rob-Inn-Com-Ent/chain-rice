package database

// Postgres migrations via golang-migrate: file:// and embed:// sources, advisory locking, kit errors.

import (
	"context"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path"
	"strconv"
	"strings"
	"sync"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/jackc/pgx/v5"
)

// SMITH-wide advisory lock (two-key form; distinct from golang-migrate's single-key driver lock).
const (
	advisoryLockSpaceKey  = 0x52494345 // "RICE"
	advisoryLockObjectKey = 0x4D494752 // "MIGR" — rice migrate gate
)

var embedMu sync.RWMutex
var embedFS fs.FS
var embedRoot string // directory inside embedFS (e.g. "migrations")

// RegisterEmbedMigrations binds an [embed.FS] (or any [fs.FS]) for [Migrate] when migrationsPath uses embed://.
// Call once at init for binaries that embed SQL; root is the path inside fsys (often "migrations").
func RegisterEmbedMigrations(fsys fs.FS, root string) error {
	if fsys == nil {
		return errors.New("database.RegisterEmbedMigrations: nil fs")
	}
	root = strings.Trim(root, "/")
	embedMu.Lock()
	defer embedMu.Unlock()
	embedFS = fsys
	embedRoot = root
	return nil
}

// Migrate applies all pending migrations. migrationsPath must be file://... or embed://...
// (see [RegisterEmbedMigrations]). connString is the golang-migrate database URL, e.g. pgx5://user@host/db?sslmode=disable.
// [migrate.ErrNoChange] is treated as success (nil). Other errors are wrapped with [kit.Err.Internal].
func Migrate(connString, migrationsPath string) error {
	ctx := context.Background()
	lg := kit.Logger()
	lg.InfoContext(ctx, "database migrate: start", "source", migrationsPath)

	return runWithSessionAdvisoryLock(ctx, connString, func() error {
		m, err := openMigrate(connString, migrationsPath)
		if err != nil {
			return kit.Err.Internal("database migrate: open").Wrap(err, "openMigrate")
		}
		defer func() {
			se, de := m.Close()
			if se != nil || de != nil {
				lg.ErrorContext(ctx, "database migrate: close", "source_err", se, "database_err", de)
			}
		}()

		if err := m.Up(); err != nil {
			if errors.Is(err, migrate.ErrNoChange) {
				lg.InfoContext(ctx, "database migrate: already up to date")
				return nil
			}
			lg.ErrorContext(ctx, "database migrate: failed", "error", err)
			return kit.Err.Internal("database migrate: apply failed").Wrap(err, "Up")
		}
		lg.InfoContext(ctx, "database migrate: success")
		return nil
	})
}

// Force sets the schema version and clears dirty (repair path). Same source/DB URLs as [Migrate].
func Force(connString, migrationsPath string, version int) error {
	ctx := context.Background()
	lg := kit.Logger()
	lg.InfoContext(ctx, "database migrate: force", "version", version)

	return runWithSessionAdvisoryLock(ctx, connString, func() error {
		m, err := openMigrate(connString, migrationsPath)
		if err != nil {
			return kit.Err.Internal("database migrate: open").Wrap(err, "openMigrate")
		}
		defer func() { _, _ = m.Close() }()

		if err := m.Force(version); err != nil {
			lg.ErrorContext(ctx, "database migrate: force failed", "error", err)
			return kit.Err.Internal("database migrate: force failed").Wrap(err, "Force")
		}
		lg.InfoContext(ctx, "database migrate: force ok", "version", version)
		return nil
	})
}

func openMigrate(connString, migrationsPath string) (*migrate.Migrate, error) {
	switch {
	case strings.HasPrefix(migrationsPath, "file://"):
		return migrate.New(migrationsPath, connString)
	case strings.HasPrefix(migrationsPath, "embed://"):
		embedMu.RLock()
		fsys := embedFS
		root := embedRoot
		embedMu.RUnlock()
		if fsys == nil {
			return nil, errors.New("database migrate: embed:// requires RegisterEmbedMigrations before Migrate")
		}
		rel := strings.TrimPrefix(migrationsPath, "embed://")
		rel = strings.Trim(rel, "/")
		dir := root
		if rel != "" {
			dir = path.Join(root, rel)
		}
		src, err := iofs.New(fsys, dir)
		if err != nil {
			return nil, err
		}
		return migrate.NewWithSourceInstance("iofs", src, connString)
	default:
		return nil, fmt.Errorf("database migrate: migrationsPath must start with file:// or embed://, got %q", migrationsPath)
	}
}

func runWithSessionAdvisoryLock(ctx context.Context, connString string, fn func() error) error {
	dsn := pgxDSN(connString)
	cfg, err := pgx.ParseConfig(dsn)
	if err != nil {
		return kit.Err.Internal("database migrate: parse dsn for advisory lock").Wrap(err, "pgx.ParseConfig")
	}
	lockSec := migrateLockTimeoutSeconds()
	cfg.ConnectTimeout = time.Duration(lockSec) * time.Second
	if cfg.ConnectTimeout < 30*time.Second {
		cfg.ConnectTimeout = 30 * time.Second
	}

	conn, err := pgx.ConnectConfig(ctx, cfg)
	if err != nil {
		return kit.Err.Internal("database migrate: connect for advisory lock").Wrap(err, "pgx.ConnectConfig")
	}

	if _, err := conn.Exec(ctx, fmt.Sprintf(`SET lock_timeout = '%ds'`, lockSec)); err != nil {
		_ = conn.Close(ctx)
		return kit.Err.Internal("database migrate: set lock_timeout").Wrap(err, "SET lock_timeout")
	}

	if _, err := conn.Exec(ctx, `SELECT pg_advisory_lock($1::int, $2::int)`, advisoryLockSpaceKey, advisoryLockObjectKey); err != nil {
		_ = conn.Close(ctx)
		return kit.Err.Internal("database migrate: advisory lock").Wrap(err, "pg_advisory_lock")
	}

	defer func() {
		cctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		if _, e := conn.Exec(cctx, `SELECT pg_advisory_unlock($1::int, $2::int)`, advisoryLockSpaceKey, advisoryLockObjectKey); e != nil {
			kit.Logger().ErrorContext(cctx, "database migrate: advisory unlock", "error", e)
		}
		_ = conn.Close(cctx)
	}()

	return fn()
}

func migrateLockTimeoutSeconds() int {
	const def = 120
	s := strings.TrimSpace(os.Getenv("RICE_MIGRATE_LOCK_TIMEOUT_S"))
	if s == "" {
		return def
	}
	n, err := strconv.Atoi(s)
	if err != nil || n <= 0 {
		return def
	}
	return n
}

func pgxDSN(connString string) string {
	s := strings.TrimSpace(connString)
	s = strings.Replace(s, "pgx5://", "postgres://", 1)
	return s
}

// NewMigrateFromFS wires golang-migrate with SQL files from an fs.FS (e.g. //go:embed migrations).
// databaseURL must use the pgx5 driver scheme, e.g. pgx5://user:pass@host:5433/yugabyte?sslmode=disable.
// dir is the root inside fsys where numbered migration files live (e.g. "migrations").
func NewMigrateFromFS(databaseURL string, fsys fs.FS, dir string) (*migrate.Migrate, error) {
	if fsys == nil {
		return nil, errors.New("database: nil fs")
	}
	src, err := iofs.New(fsys, dir)
	if err != nil {
		return nil, fmt.Errorf("migrate iofs: %w", err)
	}
	return migrate.NewWithSourceInstance("iofs", src, databaseURL)
}

// MigrateVersion returns the applied version and dirty flag.
func MigrateVersion(m *migrate.Migrate) (version uint, dirty bool, err error) {
	if m == nil {
		return 0, false, errors.New("database: nil migrate")
	}
	return m.Version()
}
