package data

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

// CockroachConfig extends PostgreSQL config with CockroachDB-specific options
type CockroachConfig struct {
	PostgresConfig // Embed PostgreSQL config
	ClusterID    string
	Region       string
	MultiRegion  bool
}

// CockroachDefaultConfig returns default CockroachDB configuration
func CockroachDefaultConfig() CockroachConfig {
	pgConfig := PostgresDefaultConfig()
	pgConfig.Port = 26257
	pgConfig.SSLMode = "require"

	return CockroachConfig{
		PostgresConfig: pgConfig,
		ClusterID:   "",
		Region:      "",
		MultiRegion: false,
	}
}

// CockroachFromEnv creates config from environment variables
func CockroachFromEnv() CockroachConfig {
	config := CockroachDefaultConfig()

	if cockroachURL := os.Getenv("COCKROACH_URL"); cockroachURL != "" {
		if parsed, err := cockroachParseCockroachURL(cockroachURL); err == nil {
			config = parsed
		} else {
			log.Printf("Warning: Failed to parse COCKROACH_URL, using individual env vars: %v", err)
		}
	} else if dbURL := os.Getenv("DATABASE_URL"); dbURL != "" {
		if strings.Contains(dbURL, "cockroach") || strings.Contains(dbURL, ":26257") {
			if parsed, err := cockroachParseCockroachURL(dbURL); err == nil {
				config = parsed
			}
		}
	}

	pgConfig := PostgresFromEnv()
	config.PostgresConfig = pgConfig

	if portStr := os.Getenv("COCKROACH_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err == nil {
			config.Port = port
		}
	} else if config.Port == 5432 {
		config.Port = 26257
	}

	if clusterID := os.Getenv("COCKROACH_CLUSTER_ID"); clusterID != "" {
		config.ClusterID = clusterID
	}
	if region := os.Getenv("COCKROACH_REGION"); region != "" {
		config.Region = region
	}
	if multiRegion := os.Getenv("COCKROACH_MULTI_REGION"); multiRegion != "" {
		config.MultiRegion = strings.ToLower(multiRegion) == "true"
	}

	if config.SSLMode == "disable" {
		config.SSLMode = "require"
	}

	return config
}

// ConnectionString builds CockroachDB connection string
func (c CockroachConfig) ConnectionString() string {
	return fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		c.Host,
		c.Port,
		c.User,
		c.Password,
		c.Database,
		c.SSLMode,
	)
}

func cockroachParseCockroachURL(urlStr string) (CockroachConfig, error) {
	config := CockroachDefaultConfig()

	urlStr = strings.Replace(urlStr, "cockroach://", "postgresql://", 1)

	pgConfig := PostgresDefaultConfig()
	if strings.HasPrefix(urlStr, "postgresql://") {
		urlStr = urlStr[13:]
		parts := strings.Split(urlStr, "@")
		if len(parts) == 2 {
			authParts := strings.Split(parts[0], ":")
			if len(authParts) == 2 {
				pgConfig.User = authParts[0]
				pgConfig.Password = authParts[1]
			} else {
				pgConfig.User = parts[0]
			}
			urlStr = parts[1]
		}

		parts2 := strings.Split(urlStr, "/")
		if len(parts2) == 2 {
			pgConfig.Database = strings.Split(parts2[1], "?")[0]
			urlStr = parts2[0]
		}

		parts3 := strings.Split(urlStr, ":")
		if len(parts3) == 2 {
			pgConfig.Host = parts3[0]
			if port, err := strconv.Atoi(parts3[1]); err == nil {
				pgConfig.Port = port
			}
		} else {
			pgConfig.Host = urlStr
		}
	}

	config.PostgresConfig = pgConfig
	return config, nil
}

// CockroachConnection wraps the sql.DB with additional functionality for CockroachDB
type CockroachConnection struct {
	*sql.DB
	config CockroachConfig
}

// CockroachNewConnection creates a new CockroachDB connection
func CockroachNewConnection(config CockroachConfig) (*CockroachConnection, error) {
	connStr := config.ConnectionString()

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open CockroachDB connection: %w", err)
	}

	db.SetMaxOpenConns(config.MaxConns)
	db.SetMaxIdleConns(config.MinConns)
	db.SetConnMaxLifetime(time.Hour)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping CockroachDB: %w", err)
	}

	return &CockroachConnection{
		DB:     db,
		config: config,
	}, nil
}

// Close closes the database connection
func (db *CockroachConnection) Close() error {
	return db.DB.Close()
}

// HealthCheck performs a health check on the database
func (db *CockroachConnection) HealthCheck(ctx context.Context) error {
	return db.PingContext(ctx)
}

// Transaction executes a function within a database transaction
func (db *CockroachConnection) Transaction(ctx context.Context, fn func(*sql.Tx) error) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback()
			panic(p)
		} else if err != nil {
			_ = tx.Rollback()
		} else {
			err = tx.Commit()
		}
	}()

	err = fn(tx)
	return err
}

// GetConfig returns the connection configuration
func (db *CockroachConnection) GetConfig() CockroachConfig {
	return db.config
}

// GetRegion returns the CockroachDB region if configured
func (db *CockroachConnection) GetRegion() string {
	return db.config.Region
}

// IsMultiRegion returns whether multi-region is enabled
func (db *CockroachConnection) IsMultiRegion() bool {
	return db.config.MultiRegion
}

// CockroachKeeper manages CockroachDB connections and operations
type CockroachKeeper struct {
	conn *CockroachConnection
}

// CockroachNewKeeper creates a new CockroachDB keeper
func CockroachNewKeeper(config CockroachConfig) (*CockroachKeeper, error) {
	conn, err := CockroachNewConnection(config)
	if err != nil {
		return nil, err
	}

	log.Printf("Connected to CockroachDB database: %s (region: %s, multi-region: %v)",
		config.Database, config.Region, config.MultiRegion)

	return &CockroachKeeper{
		conn: conn,
	}, nil
}

// GetConnection returns the underlying database connection
func (k *CockroachKeeper) GetConnection() *CockroachConnection {
	return k.conn
}

// HealthCheck performs a health check
func (k *CockroachKeeper) HealthCheck(ctx context.Context) error {
	return k.conn.HealthCheck(ctx)
}

// Close closes the connection
func (k *CockroachKeeper) Close() error {
	log.Println("Closing CockroachDB connection")
	return k.conn.Close()
}

// GetRegion returns the CockroachDB region
func (k *CockroachKeeper) GetRegion() string {
	return k.conn.GetRegion()
}

// IsMultiRegion returns whether multi-region is enabled
func (k *CockroachKeeper) IsMultiRegion() bool {
	return k.conn.IsMultiRegion()
}
