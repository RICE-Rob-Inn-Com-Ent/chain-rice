package database

// TODO:
// [ ] implement golang-migrate runner:
//     MigrateUp(ctx, db) error — applies all pending migrations
//     MigrateDown(ctx, db, steps int) error — rollback n steps
//     MigrateVersion(ctx, db) (uint, bool, error) — current version
// [ ] implement migration source:
//     reads from database/sql/migrations/ — embed.FS
//     never reads from filesystem at runtime
// [ ] implement migration locking:
//     YugabyteDB advisory lock prevents concurrent migrations
//     lock timeout from RICE_MIGRATE_LOCK_TIMEOUT_S env var
// [ ] implement migration on startup:
//     auto-migrate when RICE_DB_AUTO_MIGRATE=true (dev only)
//     production: explicit rice audit → migrate step

import (
	"errors"
	"fmt"
	"io/fs"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	"github.com/golang-migrate/migrate/v4/source/iofs"
)

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
