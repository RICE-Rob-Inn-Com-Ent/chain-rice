package migrations

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
	"go.uber.org/zap"
)

// RunMigrations runs database migrations
func RunMigrations(dbURL string, migrationsPath string, logger *zap.SugaredLogger) error {
	if dbURL == "" {
		return fmt.Errorf("database URL is required")
	}

	// Open database connection
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}
	defer db.Close()

	// Create postgres driver instance
	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		return fmt.Errorf("failed to create postgres driver: %w", err)
	}

	// Get absolute path to migrations
	absPath, err := filepath.Abs(migrationsPath)
	if err != nil {
		return fmt.Errorf("failed to get absolute path: %w", err)
	}

	// Check if migrations directory exists
	if _, err := os.Stat(absPath); os.IsNotExist(err) {
		return fmt.Errorf("migrations directory does not exist: %s", absPath)
	}

	// Create migrate instance
	m, err := migrate.NewWithDatabaseInstance(
		fmt.Sprintf("file://%s", absPath),
		"postgres",
		driver,
	)
	if err != nil {
		return fmt.Errorf("failed to create migrate instance: %w", err)
	}

	// Run migrations
	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	if err == migrate.ErrNoChange {
		logger.Info("Database is up to date")
	} else {
		logger.Info("Migrations completed successfully")
	}

	return nil
}

// GetVersion returns the current migration version
func GetVersion(dbURL string) (uint, bool, error) {
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		return 0, false, fmt.Errorf("failed to open database: %w", err)
	}
	defer db.Close()

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		return 0, false, fmt.Errorf("failed to create postgres driver: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"file://migrations",
		"postgres",
		driver,
	)
	if err != nil {
		return 0, false, fmt.Errorf("failed to create migrate instance: %w", err)
	}

	version, dirty, err := m.Version()
	if err != nil {
		return 0, false, err
	}

	return version, dirty, nil
}
