package config

import (
	"os"
	"strings"

	"github.com/chainrice/rice/backend/app/orchestration"
	"github.com/chainrice/rice/backend/app/services"
)

// Re-export types from orchestration package for convenience
type PortMapping = orchestration.PortMapping
type VolumeMapping = orchestration.VolumeMapping
type HealthCheckConfig = orchestration.HealthCheckConfig

const (
	// Container names
	containerNamePostgres = "devcontainer-postgres"
	containerNameMongoDB  = "devcontainer-mongodb"

	// Docker restart policy
	restartPolicyUnlessStopped = "unless-stopped"
)

// PostgresConfig represents PostgreSQL service configuration
type PostgresConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	HealthCheck   HealthCheckConfig
	Cloud         *services.CloudConfig // Cloud configuration (AWS RDS, GCP Cloud SQL, Azure Database)
	UseCloud      bool                  // Whether to use cloud service instead of Docker
}

// MongoConfig represents MongoDB service configuration
type MongoConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	Cloud         *services.CloudConfig // Cloud configuration (AWS DocumentDB, GCP MongoDB Atlas, Azure Cosmos DB)
	UseCloud      bool                  // Whether to use cloud service instead of Docker
}

// RedisConfig represents Redis service configuration
type RedisConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Command       []string
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	Cloud         *services.CloudConfig // Cloud configuration (AWS ElastiCache, GCP Memorystore, Azure Cache)
	UseCloud      bool                  // Whether to use cloud service instead of Docker
}

// MinIOConfig represents MinIO service configuration (object storage - S3-compatible)
type MinIOConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Command       []string
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	HealthCheck   HealthCheckConfig
	Cloud         *services.CloudConfig // Cloud configuration (AWS S3, GCP Cloud Storage, Azure Blob Storage)
	UseCloud      bool                  // Whether to use cloud service instead of Docker
}

// getEnv gets environment variable or returns fallback
func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// getEnvBool gets boolean environment variable
func getEnvBool(key string, defaultValue bool) bool {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return strings.ToLower(value) == "true" || value == "1"
}

// NewPostgresConfig creates a new PostgreSQL configuration (supports AWS RDS, GCP Cloud SQL, Azure Database)
func NewPostgresConfig() *PostgresConfig {
	cloudConfig := services.GetCloudConfig("postgres")
	useCloud := cloudConfig != nil && getEnvBool("USE_CLOUD_POSTGRES", false)

	cfg := &PostgresConfig{
		Cloud:    cloudConfig,
		UseCloud: useCloud,
	}

	if useCloud {
		// Cloud configuration - endpoint will be set from cloud provider
		switch cloudConfig.Provider {
		case services.CloudProviderAWS:
			// AWS RDS
			cfg.Environment = map[string]string{
				"POSTGRES_HOST":     getEnv("RDS_HOST", cloudConfig.ResourceName+".rds.amazonaws.com"),
				"POSTGRES_PORT":     getEnv("RDS_PORT", "5432"),
				"POSTGRES_USER":     getEnv("RDS_USERNAME", "postgres"),
				"POSTGRES_PASSWORD": getEnv("RDS_PASSWORD", ""),
				"POSTGRES_DB":       getEnv("RDS_DB_NAME", "postgres"),
				"POSTGRES_SSLMODE":  "require",
			}
		case services.CloudProviderGCP:
			// GCP Cloud SQL
			cfg.Environment = map[string]string{
				"POSTGRES_HOST":     getEnv("CLOUD_SQL_HOST", cloudConfig.ProjectID+":"+cloudConfig.Region+":"+cloudConfig.ResourceName),
				"POSTGRES_PORT":     getEnv("CLOUD_SQL_PORT", "5432"),
				"POSTGRES_USER":     getEnv("CLOUD_SQL_USER", "postgres"),
				"POSTGRES_PASSWORD": getEnv("CLOUD_SQL_PASSWORD", ""),
				"POSTGRES_DB":       getEnv("CLOUD_SQL_DB", "postgres"),
				"POSTGRES_SSLMODE":  "require",
			}
		case services.CloudProviderAzure:
			// Azure Database for PostgreSQL
			cfg.Environment = map[string]string{
				"POSTGRES_HOST":     getEnv("AZURE_POSTGRES_HOST", cloudConfig.ResourceName+".postgres.database.azure.com"),
				"POSTGRES_PORT":     getEnv("AZURE_POSTGRES_PORT", "5432"),
				"POSTGRES_USER":     getEnv("AZURE_POSTGRES_USER", "postgres@"+cloudConfig.ResourceName),
				"POSTGRES_PASSWORD": getEnv("AZURE_POSTGRES_PASSWORD", ""),
				"POSTGRES_DB":       getEnv("AZURE_POSTGRES_DB", "postgres"),
				"POSTGRES_SSLMODE":  "require",
			}
		}
	} else {
		// Local Docker configuration
		cfg.Image = "postgres:16-alpine"
		cfg.ContainerName = containerNamePostgres
		cfg.Ports = []PortMapping{
			{Host: "5432", Container: "5432", Protocol: "tcp"},
		}
		cfg.Environment = map[string]string{
			"POSTGRES_USER":     getEnv("POSTGRES_USER", "postgres"),
			"POSTGRES_PASSWORD": getEnv("POSTGRES_PASSWORD", "postgres"),
			"POSTGRES_DB":       getEnv("POSTGRES_DB", "postgres"),
		}
		cfg.Volumes = []VolumeMapping{
			{Host: "devcontainer_postgres-data", Container: "/var/lib/postgresql/data", ReadOnly: false},
			{Host: getEnv("POSTGRES_INIT_PATH", "../database/postgres/init/00-init-databases.sql"), Container: "/docker-entrypoint-initdb.d/00-init-databases.sql", ReadOnly: true},
		}
		cfg.Network = getEnv("DOCKER_NETWORK", "crice")
		cfg.RestartPolicy = restartPolicyUnlessStopped
		cfg.HealthCheck = HealthCheckConfig{
			Test:        []string{"CMD-SHELL", "pg_isready -U postgres"},
			Interval:    "10s",
			Timeout:     "5s",
			Retries:     5,
			StartPeriod: "30s",
		}
	}

	return cfg
}

// NewMongoConfig creates a new MongoDB configuration (supports AWS DocumentDB, GCP MongoDB Atlas, Azure Cosmos DB)
func NewMongoConfig() *MongoConfig {
	cloudConfig := services.GetCloudConfig("mongodb")
	useCloud := cloudConfig != nil && getEnvBool("USE_CLOUD_MONGODB", false)

	cfg := &MongoConfig{
		Cloud:    cloudConfig,
		UseCloud: useCloud,
	}

	if useCloud {
		// Cloud configuration
		switch cloudConfig.Provider {
		case services.CloudProviderAWS:
			// AWS DocumentDB
			cfg.Environment = map[string]string{
				"MONGODB_HOST":     getEnv("DOCUMENTDB_HOST", cloudConfig.ResourceName+".docdb.amazonaws.com"),
				"MONGODB_PORT":     getEnv("DOCUMENTDB_PORT", "27017"),
				"MONGODB_USER":     getEnv("DOCUMENTDB_USER", "admin"),
				"MONGODB_PASSWORD": getEnv("DOCUMENTDB_PASSWORD", ""),
				"MONGODB_DB":       getEnv("DOCUMENTDB_DB", "admin"),
				"MONGODB_TLS":      "true",
			}
		case services.CloudProviderGCP:
			// GCP MongoDB Atlas (via connection string)
			cfg.Environment = map[string]string{
				"MONGODB_URI": getEnv("MONGODB_ATLAS_URI", ""),
			}
		case services.CloudProviderAzure:
			// Azure Cosmos DB for MongoDB
			cfg.Environment = map[string]string{
				"MONGODB_HOST":     getEnv("COSMOSDB_HOST", cloudConfig.ResourceName+".mongo.cosmos.azure.com"),
				"MONGODB_PORT":     getEnv("COSMOSDB_PORT", "10255"),
				"MONGODB_USER":     getEnv("COSMOSDB_USER", cloudConfig.ResourceName),
				"MONGODB_PASSWORD": getEnv("COSMOSDB_PASSWORD", ""),
				"MONGODB_DB":       getEnv("COSMOSDB_DB", "admin"),
				"MONGODB_TLS":      "true",
			}
		}
	} else {
		// Local Docker configuration
		cfg.Image = "mongo:7"
		cfg.ContainerName = containerNameMongoDB
		cfg.Ports = []PortMapping{
			{Host: "27017", Container: "27017", Protocol: "tcp"},
		}
		cfg.Volumes = []VolumeMapping{
			{Host: "devcontainer_mongodb-data", Container: "/data/db", ReadOnly: false},
		}
		cfg.Network = getEnv("DOCKER_NETWORK", "crice")
		cfg.RestartPolicy = restartPolicyUnlessStopped
	}

	return cfg
}

// NewRedisConfig creates a new Redis configuration (supports AWS ElastiCache, GCP Memorystore, Azure Cache)
func NewRedisConfig() *RedisConfig {
	cloudConfig := services.GetCloudConfig("redis")
	useCloud := cloudConfig != nil && getEnvBool("USE_CLOUD_REDIS", false)

	cfg := &RedisConfig{
		Cloud:    cloudConfig,
		UseCloud: useCloud,
	}

	if useCloud {
		// Cloud configuration
		switch cloudConfig.Provider {
		case services.CloudProviderAWS:
			// AWS ElastiCache
			cfg.Environment = map[string]string{
				"REDIS_HOST": getEnv("ELASTICACHE_HOST", cloudConfig.ResourceName+".cache.amazonaws.com"),
				"REDIS_PORT": getEnv("ELASTICACHE_PORT", "6379"),
			}
		case services.CloudProviderGCP:
			// GCP Memorystore
			cfg.Environment = map[string]string{
				"REDIS_HOST": getEnv("MEMORYSTORE_HOST", cloudConfig.ResourceName+".redis.cache.google.internal"),
				"REDIS_PORT": getEnv("MEMORYSTORE_PORT", "6379"),
			}
		case services.CloudProviderAzure:
			// Azure Cache for Redis
			cfg.Environment = map[string]string{
				"REDIS_HOST":     getEnv("AZURE_REDIS_HOST", cloudConfig.ResourceName+".redis.cache.windows.net"),
				"REDIS_PORT":     getEnv("AZURE_REDIS_PORT", "6380"),
				"REDIS_PASSWORD": getEnv("AZURE_REDIS_PASSWORD", ""),
				"REDIS_TLS":      "true",
			}
		}
	} else {
		// Local Docker configuration
		cfg.Image = "redis:7-alpine"
		cfg.ContainerName = "devcontainer-redis"
		cfg.Command = []string{"redis-server", "--appendonly", "yes"}
		cfg.Ports = []PortMapping{
			{Host: "6379", Container: "6379", Protocol: "tcp"},
		}
		cfg.Volumes = []VolumeMapping{
			{Host: "devcontainer_redis-data", Container: "/data", ReadOnly: false},
		}
		cfg.Network = getEnv("DOCKER_NETWORK", "crice")
		cfg.RestartPolicy = restartPolicyUnlessStopped
	}

	return cfg
}

// NewMinIOConfig creates a new MinIO configuration (supports AWS S3, GCP Cloud Storage, Azure Blob Storage)
func NewMinIOConfig() *MinIOConfig {
	cloudConfig := services.GetCloudConfig("minio")
	useCloud := cloudConfig != nil && getEnvBool("USE_CLOUD_STORAGE", false)

	cfg := &MinIOConfig{
		Cloud:    cloudConfig,
		UseCloud: useCloud,
	}

	if useCloud {
		// Cloud configuration
		switch cloudConfig.Provider {
		case services.CloudProviderAWS:
			// AWS S3
			cfg.Environment = map[string]string{
				"S3_ENDPOINT":       getEnv("S3_ENDPOINT", "s3."+cloudConfig.Region+".amazonaws.com"),
				"S3_BUCKET":         getEnv("S3_BUCKET", cloudConfig.ResourceName),
				"S3_REGION":         cloudConfig.Region,
				"AWS_ACCESS_KEY":    cloudConfig.Credentials["access_key_id"],
				"AWS_SECRET_KEY":    cloudConfig.Credentials["secret_access_key"],
				"AWS_SESSION_TOKEN": cloudConfig.Credentials["session_token"],
			}
		case services.CloudProviderGCP:
			// GCP Cloud Storage
			cfg.Environment = map[string]string{
				"GCS_BUCKET":      getEnv("GCS_BUCKET", cloudConfig.ResourceName),
				"GCS_PROJECT_ID":  cloudConfig.ProjectID,
				"GCS_CREDENTIALS": cloudConfig.Credentials["credentials_json"],
			}
		case services.CloudProviderAzure:
			// Azure Blob Storage
			cfg.Environment = map[string]string{
				"AZURE_STORAGE_ACCOUNT": getEnv("AZURE_STORAGE_ACCOUNT", cloudConfig.ResourceName),
				"AZURE_STORAGE_KEY":     getEnv("AZURE_STORAGE_KEY", ""),
				"AZURE_CONTAINER":       getEnv("AZURE_CONTAINER", "data"),
			}
		}
	} else {
		// Local Docker configuration
		cfg.Image = "minio/minio:latest"
		cfg.ContainerName = "devcontainer-minio"
		cfg.Command = []string{"server", "/data", "--console-address", ":9001"}
		cfg.Ports = []PortMapping{
			{Host: "9000", Container: "9000", Protocol: "tcp"},
			{Host: "9001", Container: "9001", Protocol: "tcp"},
		}
		cfg.Environment = map[string]string{
			"MINIO_ROOT_USER":     getEnv("MINIO_ROOT_USER", "minioadmin"),
			"MINIO_ROOT_PASSWORD": getEnv("MINIO_ROOT_PASSWORD", "minioadmin"),
		}
		cfg.Volumes = []VolumeMapping{
			{Host: "devcontainer_minio-data", Container: "/data", ReadOnly: false},
		}
		cfg.Network = getEnv("DOCKER_NETWORK", "crice")
		cfg.RestartPolicy = restartPolicyUnlessStopped
		cfg.HealthCheck = HealthCheckConfig{
			Test:     []string{"CMD", "curl", "-f", "http://localhost:9000/minio/health/live"},
			Interval: "30s",
			Timeout:  "10s",
			Retries:  3,
		}
	}

	return cfg
}
