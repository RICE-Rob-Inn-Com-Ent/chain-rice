package testutil

import (
	"context"
	"testing"

	"github.com/chainrice/rice/backend/module"
	"github.com/cosmos/cosmos-sdk/crypto/keys/ed25519"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// ============================================================================
// Sample Data Generation
// ============================================================================

// AccAddress returns a sample account address
func AccAddress() string {
	pk := ed25519.GenPrivKey().PubKey()
	addr := pk.Address()
	return sdk.AccAddress(addr).String()
}

// ============================================================================
// PostgreSQL Test Utilities
// ============================================================================

// NewTestPostgresConnection creates a PostgreSQL connection for testing
func NewTestPostgresConnection(t *testing.T) *module.PostgresConnection {
	config := module.PostgresConfig{
		Host:     "localhost",
		Port:     5432,
		User:     "postgres",
		Password: "postgres",
		Database: "test_db",
		SSLMode:  "disable",
		MaxConns: 5,
		MinConns: 1,
	}

	conn, err := module.PostgresNewConnection(config)
	if err != nil {
		t.Fatalf("Failed to create test PostgreSQL connection: %v", err)
	}

	// Clean up on test end
	t.Cleanup(func() {
		conn.Close()
	})

	return conn
}

// CleanupTestDatabase cleans up test data
func CleanupTestDatabase(ctx context.Context, conn *module.PostgresConnection, tables []string) error {
	for _, table := range tables {
		_, err := conn.DB.ExecContext(ctx, "TRUNCATE TABLE "+table+" CASCADE")
		if err != nil {
			return err
		}
	}
	return nil
}

// ============================================================================
// MongoDB Test Utilities
// ============================================================================

// NewTestMongoClient creates a MongoDB client for testing
func NewTestMongoClient(t *testing.T) *module.MongoClient {
	config := module.MongoConfig{
		Host:        "localhost",
		Port:        27017,
		Username:    "",
		Password:    "",
		Database:    "test_db",
		AuthSource:  "admin",
		ReplicaSet:  "",
		TLS:         false,
		MaxPoolSize: 10,
		MinPoolSize: 1,
	}

	client, err := module.MongoNewConnection(config)
	if err != nil {
		t.Fatalf("Failed to create test MongoDB client: %v", err)
	}

	// Clean up on test end
	t.Cleanup(func() {
		ctx := context.Background()
		// Drop test database
		db := client.GetDatabase()
		db.Drop(ctx)
		client.Close()
	})

	return client
}

// CleanupTestMongo cleans up test collections
func CleanupTestMongo(ctx context.Context, client *module.MongoClient, collections []string) error {
	db := client.GetDatabase()
	for _, collection := range collections {
		if err := db.Collection(collection).Drop(ctx); err != nil {
			return err
		}
	}
	return nil
}

// ============================================================================
// CockroachDB Test Utilities
// ============================================================================

// NewTestCockroachConnection creates a CockroachDB connection for testing
func NewTestCockroachConnection(t *testing.T) *module.CockroachConnection {
	config := module.CockroachConfig{
		PostgresConfig: module.PostgresConfig{
			Host:     "localhost",
			Port:     26257,
			User:     "root",
			Password: "",
			Database: "test_db",
			SSLMode:  "disable", // For local testing
			MaxConns: 5,
			MinConns: 1,
		},
		ClusterID:   "",
		Region:      "",
		MultiRegion: false,
	}

	conn, err := module.CockroachNewConnection(config)
	if err != nil {
		t.Fatalf("Failed to create test CockroachDB connection: %v", err)
	}

	// Clean up on test end
	t.Cleanup(func() {
		conn.Close()
	})

	return conn
}

// CleanupTestCockroach cleans up test data
func CleanupTestCockroach(ctx context.Context, conn *module.CockroachConnection, tables []string) error {
	for _, table := range tables {
		_, err := conn.DB.ExecContext(ctx, "TRUNCATE TABLE "+table+" CASCADE")
		if err != nil {
			return err
		}
	}
	return nil
}

// ============================================================================
// Redis Test Utilities
// ============================================================================

// NewTestRedisClient creates a Redis client for testing
func NewTestRedisClient(t *testing.T) *module.RedisClient {
	config := module.RedisConfig{
		Host:     "localhost",
		Port:     6379,
		Password: "",
		DB:       15, // Use DB 15 for testing
		PoolSize: 5,
	}

	client, err := module.RedisNewConnection(config)
	if err != nil {
		t.Fatalf("Failed to create test Redis client: %v", err)
	}

	// Clean up on test end
	t.Cleanup(func() {
		// Flush test database
		ctx := context.Background()
		client.FlushDB(ctx)
		client.Close()
	})

	return client
}

// CleanupTestRedis cleans up test keys
func CleanupTestRedis(ctx context.Context, client *module.RedisClient, patterns []string) error {
	for _, pattern := range patterns {
		if err := client.InvalidateCachePattern(ctx, pattern); err != nil {
			return err
		}
	}
	return nil
}
