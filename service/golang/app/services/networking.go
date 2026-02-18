package services

import (
	"github.com/chainrice/rice/backend/app/orchestration"
)

// RegisterNetworkingServices registers networking services
func RegisterNetworkingServices(o *orchestration.Orchestrator, network string) {
	// Traefik
	o.RegisterService(&orchestration.Service{
		Name:      "traefik",
		Image:     "traefik:v3.1",
		Container: "devcontainer-traefik",
		Command: []string{
			"--api.dashboard=true",
			"--api.insecure=true",
			"--providers.docker=true",
			"--providers.docker.exposedByDefault=false",
			"--providers.docker.network=" + network,
			"--providers.file.filename=/etc/traefik/dynamic.yml",
			"--providers.file.watch=true",
			"--entrypoints.web.address=:80",
			"--entrypoints.websecure.address=:443",
			"--entrypoints.traefik.address=:8080",
			"--entrypoints.metrics.address=:9101",
			"--ping=true",
			"--ping.entrypoint=web",
			"--log.level=INFO",
			"--accessLog=true",
			"--metrics.prometheus=true",
			"--metrics.prometheus.addEntryPointsLabels=true",
			"--metrics.prometheus.addServicesLabels=true",
			"--metrics.prometheus.buckets=0.1,0.3,1.2,5.0",
			"--metrics.prometheus.entryPoint=metrics",
			"--tracing=true",
			"--tracing.serviceName=traefik",
			"--tracing.samplerate=1.0",
			"--tracing.otlp.grpc.endpoint=jaeger:4317",
			"--tracing.otlp.grpc.insecure=true",
		},
		Ports: []orchestration.PortMapping{
			{Host: "80", Container: "80", Protocol: "tcp"},
			{Host: "443", Container: "443", Protocol: "tcp"},
			{Host: "8080", Container: "8080", Protocol: "tcp"},
			{Host: "9101", Container: "9101", Protocol: "tcp"},
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "/var/run/docker.sock", Container: "/var/run/docker.sock", ReadOnly: true},
		},
		Networks:  []string{network},
		Profiles:  []string{"core"},
		DependsOn: []string{"consul"},
		Restart:   "unless-stopped",
		CapAdd:    []string{"CAP_NET_BIND_SERVICE"},
		HealthCheck: &orchestration.HealthCheck{
			Test:        []string{"CMD", "wget", "-q", "-O", "/dev/null", "http://localhost:8080/api/overview"},
			Interval:    "30s",
			Timeout:     "10s",
			Retries:     3,
			StartPeriod: "10s",
		},
		Description: "🔀 Traefik - Reverse Proxy & Load Balancer",
	})
}
