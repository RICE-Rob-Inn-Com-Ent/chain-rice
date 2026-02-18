package services

import (
	"github.com/chainrice/rice/backend/app/orchestration"
)

const (
	// Container names
	containerNamePostgres = "devcontainer-postgres"
	containerNameMongoDB  = "devcontainer-mongodb"
)

// RegisterDataServices registers database and storage services
func RegisterDataServices(o *orchestration.Orchestrator, network string) {
	// Postgres
	o.RegisterService(&orchestration.Service{
		Name:      "postgres",
		Image:     "postgres:16-alpine",
		Container: containerNamePostgres,
		Ports: []orchestration.PortMapping{
			{Host: "5432", Container: "5432", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"POSTGRES_USER":     "postgres",
			"POSTGRES_PASSWORD": "postgres",
			"POSTGRES_DB":       "postgres",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_postgres-data", Container: "/var/lib/postgresql/data", ReadOnly: false},
		},
		Networks: []string{network},
		Profiles: []string{"core"},
		Restart:  restartPolicyUnlessStopped,
		HealthCheck: &orchestration.HealthCheck{
			Test:        []string{"CMD-SHELL", "pg_isready -U postgres"},
			Interval:    "10s",
			Timeout:     "5s",
			Retries:     5,
			StartPeriod: "30s",
		},
		Description: "🗄️ Postgres - primary relational database",
	})

	// MongoDB
	o.RegisterService(&orchestration.Service{
		Name:      "mongodb",
		Image:     "mongo:7",
		Container: containerNameMongoDB,
		Ports: []orchestration.PortMapping{
			{Host: "27017", Container: "27017", Protocol: "tcp"},
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_mongodb-data", Container: "/data/db", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"core"},
		Restart:     restartPolicyUnlessStopped,
		Description: "🍃 MongoDB - document store",
	})

	// Redis
	o.RegisterService(&orchestration.Service{
		Name:      "redis",
		Image:     "redis:7-alpine",
		Container: "devcontainer-redis",
		Ports: []orchestration.PortMapping{
			{Host: "6379", Container: "6379", Protocol: "tcp"},
		},
		Command: []string{"redis-server", "--appendonly", "yes"},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_redis-data", Container: "/data", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"core"},
		Restart:     restartPolicyUnlessStopped,
		Description: "🔁 Redis - cache / message broker",
	})

	// MinIO
	o.RegisterService(&orchestration.Service{
		Name:      "minio",
		Image:     "minio/minio:latest",
		Container: "devcontainer-minio",
		Command:   []string{"server", "/data", "--console-address", ":9001"},
		Ports: []orchestration.PortMapping{
			{Host: "9000", Container: "9000", Protocol: "tcp"},
			{Host: "9001", Container: "9001", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"MINIO_ROOT_USER":     "minioadmin",
			"MINIO_ROOT_PASSWORD": "minioadmin",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_minio-data", Container: "/data", ReadOnly: false},
		},
		Networks: []string{network},
		Profiles: []string{"storage"},
		Restart:  restartPolicyUnlessStopped,
		HealthCheck: &orchestration.HealthCheck{
			Test:     []string{"CMD", "curl", "-f", "http://localhost:9000/minio/health/live"},
			Interval: "30s",
			Timeout:  "10s",
			Retries:  3,
		},
		Description: "📦 MinIO - Object Storage (S3-compatible)",
	})

	// pgAdmin
	o.RegisterService(&orchestration.Service{
		Name:      "pgadmin",
		Image:     "dpage/pgadmin4:latest",
		Container: "devcontainer-pgadmin",
		Ports: []orchestration.PortMapping{
			{Host: "5050", Container: "80", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"PGADMIN_DEFAULT_EMAIL":    "admin@example.com",
			"PGADMIN_DEFAULT_PASSWORD": "admin",
		},
		Networks:    []string{network},
		Profiles:    []string{"admin"},
		DependsOn:   []string{"postgres"},
		Restart:     restartPolicyUnlessStopped,
		Description: "🧰 pgAdmin - Postgres admin UI",
	})

	// Mongo Express
	o.RegisterService(&orchestration.Service{
		Name:      "mongo-express",
		Image:     "mongo-express:latest",
		Container: "devcontainer-mongo-express",
		Ports: []orchestration.PortMapping{
			{Host: "8081", Container: "8081", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"ME_CONFIG_MONGODB_SERVER":     containerNameMongoDB,
			"ME_CONFIG_MONGODB_PORT":       "27017",
			"ME_CONFIG_BASICAUTH_USERNAME": "admin",
			"ME_CONFIG_BASICAUTH_PASSWORD": "admin",
		},
		Networks:    []string{network},
		Profiles:    []string{"admin"},
		DependsOn:   []string{"mongodb"},
		Restart:     restartPolicyUnlessStopped,
		Description: "🌐 Mongo Express - MongoDB admin UI",
	})

	// Redis Commander
	o.RegisterService(&orchestration.Service{
		Name:      "redis-commander",
		Image:     "rediscommander/redis-commander:latest",
		Container: "devcontainer-redis-commander",
		Ports: []orchestration.PortMapping{
			{Host: "8082", Container: "8081", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"REDIS_HOSTS": "local:devcontainer-redis:6379",
		},
		Networks:    []string{network},
		Profiles:    []string{"admin"},
		DependsOn:   []string{"redis"},
		Restart:     restartPolicyUnlessStopped,
		Description: "📊 Redis Commander - Redis admin UI",
	})

	// IPFS (Kubo)
	o.RegisterService(&orchestration.Service{
		Name:      "ipfs",
		Image:     "ipfs/kubo:latest",
		Container: "devcontainer-ipfs",
		Ports: []orchestration.PortMapping{
			{Host: "4001", Container: "4001", Protocol: "tcp"},
			{Host: "5001", Container: "5001", Protocol: "tcp"},
			{Host: "8087", Container: "8080", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"IPFS_PROFILE": "server",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_ipfs-data", Container: "/data/ipfs", ReadOnly: false},
			{Host: "devcontainer_ipfs-staging", Container: "/export", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"web3"},
		Restart:     restartPolicyUnlessStopped,
		Description: "🌐 IPFS - Decentralized Storage for Web3",
	})
}
