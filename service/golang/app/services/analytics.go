package services

import (
	"github.com/chainrice/rice/backend/app/orchestration"
)

const (
	// Docker restart policy
	restartPolicyUnlessStopped = "unless-stopped"
)

// RegisterAnalyticsServices registers business intelligence and analytics services
func RegisterAnalyticsServices(o *orchestration.Orchestrator, network string) {
	// Apache Superset
	o.RegisterService(&orchestration.Service{
		Name:      "superset",
		Image:     "apache/superset:latest",
		Container: "devcontainer-superset",
		Ports: []orchestration.PortMapping{
			{Host: "8085", Container: "8088", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"SUPERSET_SECRET_KEY": "your-secret-key-change-in-production",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_superset-data", Container: "/app", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"bi"},
		DependsOn:   []string{"postgres"},
		Restart:     restartPolicyUnlessStopped,
		Description: "📊 Apache Superset - BI Platform",
	})

	// Metabase
	o.RegisterService(&orchestration.Service{
		Name:      "metabase",
		Image:     "metabase/metabase:latest",
		Container: "devcontainer-metabase",
		Ports: []orchestration.PortMapping{
			{Host: "3001", Container: "3000", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"MB_DB_TYPE":               "postgres",
			"MB_DB_DBNAME":             "metabase",
			"MB_DB_PORT":               "5432",
			"MB_DB_USER":               "metabase",
			"MB_DB_PASS":               "metabase",
			"MB_DB_HOST":               "devcontainer-postgres",
			"JAVA_TIMEZONE":            "UTC",
			"MB_ENCRYPTION_SECRET_KEY": "your-encryption-secret-key-change-in-production",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_metabase-data", Container: "/metabase-data", ReadOnly: false},
		},
		Networks:  []string{network},
		Profiles:  []string{"bi"},
		DependsOn: []string{"postgres"},
		Restart:   restartPolicyUnlessStopped,
		HealthCheck: &orchestration.HealthCheck{
			Test:     []string{"CMD", "curl", "-f", "http://localhost:3000/api/health"},
			Interval: "30s",
			Timeout:  "10s",
			Retries:  3,
		},
		Description: "📈 Metabase - Business Intelligence & Analytics Platform",
	})
}
