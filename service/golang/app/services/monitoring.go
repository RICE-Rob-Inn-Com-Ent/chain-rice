package services

import (
	"github.com/chainrice/rice/backend/app/orchestration"
)

// RegisterMonitoringServices registers monitoring services
func RegisterMonitoringServices(o *orchestration.Orchestrator, network string) {
	// Prometheus
	o.RegisterService(&orchestration.Service{
		Name:      "prometheus",
		Image:     "prom/prometheus:latest",
		Container: "devcontainer-prometheus",
		Command: []string{
			"--config.file=/etc/prometheus/prometheus.yml",
			"--storage.tsdb.path=/prometheus",
			"--web.console.libraries=/usr/share/prometheus/console_libraries",
			"--web.console.templates=/usr/share/prometheus/consoles",
		},
		Ports: []orchestration.PortMapping{
			{Host: "9090", Container: "9090", Protocol: "tcp"},
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_prometheus-data", Container: "/prometheus", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"monitoring"},
		DependsOn:   []string{"traefik"},
		Restart:     "unless-stopped",
		Description: "📊 Prometheus - Metrics Collection",
	})

	// Grafana
	o.RegisterService(&orchestration.Service{
		Name:      "grafana",
		Image:     "grafana/grafana:latest",
		Container: "devcontainer-grafana",
		Ports: []orchestration.PortMapping{
			{Host: "3000", Container: "3000", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"GF_SECURITY_ADMIN_USER":     "admin",
			"GF_SECURITY_ADMIN_PASSWORD": "admin",
			"GF_SERVER_ROOT_URL":         "http://localhost:3000",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_grafana-data", Container: "/var/lib/grafana", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"monitoring"},
		DependsOn:   []string{"prometheus"},
		Restart:     "unless-stopped",
		Description: "📊 Grafana - Visualization & Dashboards",
	})

	// Jaeger
	o.RegisterService(&orchestration.Service{
		Name:      "jaeger",
		Image:     "jaegertracing/all-in-one:1.60",
		Container: "devcontainer-jaeger",
		Ports: []orchestration.PortMapping{
			{Host: "16686", Container: "16686", Protocol: "tcp"},
			{Host: "14268", Container: "14268", Protocol: "tcp"},
			{Host: "6831", Container: "6831", Protocol: "udp"},
			{Host: "4317", Container: "4317", Protocol: "tcp"},
			{Host: "4318", Container: "4318", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"COLLECTOR_OTLP_ENABLED": "true",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_jaeger-tmp", Container: "/tmp", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"monitoring"},
		Restart:     "unless-stopped",
		Description: "🔍 Jaeger - Distributed Tracing",
	})

	// Loki
	o.RegisterService(&orchestration.Service{
		Name:      "loki",
		Image:     "grafana/loki:2.9.0",
		Container: "devcontainer-loki",
		Command:   []string{"-config.file=/etc/loki/local-config.yaml"},
		Ports: []orchestration.PortMapping{
			{Host: "3100", Container: "3100", Protocol: "tcp"},
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_loki-data", Container: "/loki", ReadOnly: false},
		},
		Networks: []string{network},
		Profiles: []string{"monitoring"},
		Restart:  "unless-stopped",
		HealthCheck: &orchestration.HealthCheck{
			Test:     []string{"CMD", "wget", "-q", "-O", "-", "http://localhost:3100/ready"},
			Interval: "30s",
			Timeout:  "10s",
			Retries:  3,
		},
		Description: "📝 Loki - Log Aggregation",
	})
}
