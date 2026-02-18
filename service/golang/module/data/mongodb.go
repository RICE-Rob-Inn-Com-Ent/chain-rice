package data

import (
	"context"
	"fmt"
	"log"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// MongoConfig holds MongoDB connection configuration
type MongoConfig struct {
	Host        string
	Port        int
	Username    string
	Password    string
	Database    string
	AuthSource  string
	ReplicaSet  string
	TLS         bool
	MaxPoolSize int
	MinPoolSize int
}

// MongoDefaultConfig returns default MongoDB configuration
func MongoDefaultConfig() MongoConfig {
	return MongoConfig{
		Host:        "localhost",
		Port:        27017,
		Username:    "",
		Password:    "",
		Database:    "default",
		AuthSource:  "admin",
		ReplicaSet:  "",
		TLS:         false,
		MaxPoolSize: 100,
		MinPoolSize: 10,
	}
}

// MongoFromEnv creates config from environment variables
func MongoFromEnv() MongoConfig {
	config := MongoDefaultConfig()

	if mongodbURL := os.Getenv("MONGODB_URL"); mongodbURL != "" {
		if parsed, err := mongoParseMongoURL(mongodbURL); err == nil {
			config = parsed
		} else {
			log.Printf("Warning: Failed to parse MONGODB_URL, using individual env vars: %v", err)
		}
	}

	if host := os.Getenv("MONGODB_HOST"); host != "" {
		config.Host = host
	}
	if portStr := os.Getenv("MONGODB_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err == nil {
			config.Port = port
		}
	}
	if username := os.Getenv("MONGODB_USERNAME"); username != "" {
		config.Username = username
	}
	if password := os.Getenv("MONGODB_PASSWORD"); password != "" {
		config.Password = password
	}
	if db := os.Getenv("MONGODB_DB"); db != "" {
		config.Database = db
	} else if db := os.Getenv("MONGODB_DATABASE"); db != "" {
		config.Database = db
	} else if projectSlug := os.Getenv("PROJECT_SLUG"); projectSlug != "" {
		config.Database = projectSlug
	}
	if authSource := os.Getenv("MONGODB_AUTH_SOURCE"); authSource != "" {
		config.AuthSource = authSource
	}
	if replicaSet := os.Getenv("MONGODB_REPLICA_SET"); replicaSet != "" {
		config.ReplicaSet = replicaSet
	}
	if tlsStr := os.Getenv("MONGODB_TLS"); tlsStr != "" {
		config.TLS = strings.ToLower(tlsStr) == "true"
	}
	if maxPoolStr := os.Getenv("MONGODB_MAX_POOL_SIZE"); maxPoolStr != "" {
		if maxPool, err := strconv.Atoi(maxPoolStr); err == nil {
			config.MaxPoolSize = maxPool
		}
	}
	if minPoolStr := os.Getenv("MONGODB_MIN_POOL_SIZE"); minPoolStr != "" {
		if minPool, err := strconv.Atoi(minPoolStr); err == nil {
			config.MinPoolSize = minPool
		}
	}

	return config
}

// ConnectionString builds MongoDB connection string
func (c MongoConfig) ConnectionString() string {
	var auth string
	if c.Username != "" && c.Password != "" {
		auth = fmt.Sprintf("%s:%s@", url.QueryEscape(c.Username), url.QueryEscape(c.Password))
	}

	options := []string{}
	if c.AuthSource != "" && c.Username != "" {
		options = append(options, fmt.Sprintf("authSource=%s", c.AuthSource))
	}
	if c.ReplicaSet != "" {
		options = append(options, fmt.Sprintf("replicaSet=%s", c.ReplicaSet))
	}
	if c.TLS {
		options = append(options, "tls=true")
	}
	options = append(options, fmt.Sprintf("maxPoolSize=%d", c.MaxPoolSize))
	options = append(options, fmt.Sprintf("minPoolSize=%d", c.MinPoolSize))

	optionsStr := strings.Join(options, "&")
	if optionsStr != "" {
		return fmt.Sprintf("mongodb://%s%s:%d/%s?%s", auth, c.Host, c.Port, c.Database, optionsStr)
	}
	return fmt.Sprintf("mongodb://%s%s:%d/%s", auth, c.Host, c.Port, c.Database)
}

func mongoParseMongoURL(urlStr string) (MongoConfig, error) {
	config := MongoDefaultConfig()

	if !strings.HasPrefix(urlStr, "mongodb://") {
		return config, fmt.Errorf("invalid MongoDB URL format, must start with mongodb://")
	}

	u, err := url.Parse(urlStr)
	if err != nil {
		return config, fmt.Errorf("failed to parse URL: %w", err)
	}

	config.Host = u.Hostname()
	if u.Port() != "" {
		if port, err := strconv.Atoi(u.Port()); err == nil {
			config.Port = port
		}
	}

	if u.Path != "" {
		config.Database = strings.TrimPrefix(u.Path, "/")
	}

	config.Username = u.User.Username()
	if password, ok := u.User.Password(); ok {
		config.Password = password
	}

	params := u.Query()
	if authSource := params.Get("authSource"); authSource != "" {
		config.AuthSource = authSource
	}
	if replicaSet := params.Get("replicaSet"); replicaSet != "" {
		config.ReplicaSet = replicaSet
	}
	if tls := params.Get("tls"); tls != "" {
		config.TLS = strings.ToLower(tls) == "true"
	}
	if maxPool := params.Get("maxPoolSize"); maxPool != "" {
		if max, err := strconv.Atoi(maxPool); err == nil {
			config.MaxPoolSize = max
		}
	}
	if minPool := params.Get("minPoolSize"); minPool != "" {
		if min, err := strconv.Atoi(minPool); err == nil {
			config.MinPoolSize = min
		}
	}

	return config, nil
}

// MongoClient wraps the mongo.Client with additional functionality
type MongoClient struct {
	*mongo.Client
	config MongoConfig
	db     *mongo.Database
}

// MongoNewConnection creates a new MongoDB connection
func MongoNewConnection(config MongoConfig) (*MongoClient, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clientOptions := options.Client().ApplyURI(config.ConnectionString())
	clientOptions.SetServerSelectionTimeout(5 * time.Second)
	clientOptions.SetMaxPoolSize(uint64(config.MaxPoolSize))
	clientOptions.SetMinPoolSize(uint64(config.MinPoolSize))

	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to MongoDB: %w", err)
	}

	if err := client.Ping(ctx, nil); err != nil {
		return nil, fmt.Errorf("failed to ping MongoDB: %w", err)
	}

	log.Printf("Connected to MongoDB database: %s", config.Database)

	return &MongoClient{
		Client: client,
		config: config,
		db:     client.Database(config.Database),
	}, nil
}

// Close closes the MongoDB connection
func (c *MongoClient) Close() error {
	log.Println("Closing MongoDB connection")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	return c.Client.Disconnect(ctx)
}

// HealthCheck performs a health check on MongoDB
func (c *MongoClient) HealthCheck(ctx context.Context) error {
	return c.Client.Ping(ctx, nil)
}

// GetDatabase returns the database instance
func (c *MongoClient) GetDatabase() *mongo.Database {
	return c.db
}

// GetCollection returns a collection from the database
func (c *MongoClient) GetCollection(name string) *mongo.Collection {
	return c.db.Collection(name)
}

// GetConfig returns the connection configuration
func (c *MongoClient) GetConfig() MongoConfig {
	return c.config
}

// MongoKeeper manages MongoDB connections and operations
type MongoKeeper struct {
	client *MongoClient
}

// MongoNewKeeper creates a new MongoDB keeper
func MongoNewKeeper(config MongoConfig) (*MongoKeeper, error) {
	client, err := MongoNewConnection(config)
	if err != nil {
		return nil, err
	}

	return &MongoKeeper{
		client: client,
	}, nil
}

// GetClient returns the underlying MongoDB client
func (k *MongoKeeper) GetClient() *MongoClient {
	return k.client
}

// GetDatabase returns the database instance
func (k *MongoKeeper) GetDatabase() interface{} {
	return k.client.GetDatabase()
}

// HealthCheck performs a health check
func (k *MongoKeeper) HealthCheck(ctx context.Context) error {
	return k.client.HealthCheck(ctx)
}

// Close closes the connection
func (k *MongoKeeper) Close() error {
	log.Println("Closing MongoDB connection")
	return k.client.Close()
}
