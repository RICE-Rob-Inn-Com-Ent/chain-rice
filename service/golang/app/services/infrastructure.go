package services

import (
	"github.com/chainrice/rice/backend/app/orchestration"
)

// RegisterInfrastructureServices registers infrastructure services (service discovery, secrets management)
func RegisterInfrastructureServices(o *orchestration.Orchestrator, network string) {
	// Consul - Service Discovery & Configuration
	o.RegisterService(&orchestration.Service{
		Name:      "consul",
		Image:     "hashicorp/consul:latest",
		Container: "devcontainer-consul",
		Command:   []string{"agent", "-config-file=/consul/config/consul.hcl"},
		Ports: []orchestration.PortMapping{
			{Host: "8500", Container: "8500", Protocol: "tcp"},
			{Host: "8300", Container: "8300", Protocol: "tcp"},
			{Host: "8301", Container: "8301", Protocol: "tcp"},
			{Host: "8301", Container: "8301", Protocol: "udp"},
			{Host: "8302", Container: "8302", Protocol: "tcp"},
			{Host: "8302", Container: "8302", Protocol: "udp"},
			{Host: "8502", Container: "8502", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"CONSUL_BIND_INTERFACE": "eth0",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_consul-data", Container: "/consul/data", ReadOnly: false},
		},
		Networks: []string{network},
		Profiles: []string{"core", "secrets"},
		Restart:  "unless-stopped",
		HealthCheck: &orchestration.HealthCheck{
			Test:        []string{"CMD", "consul", "info"},
			Interval:    "30s",
			Timeout:     "10s",
			Retries:     3,
			StartPeriod: "10s",
		},
		Description: "🌐 Consul - Service Discovery & Configuration",
	})

	// Vault - Secrets Management
	o.RegisterService(&orchestration.Service{
		Name:      "vault",
		Image:     "hashicorp/vault:1.17.2",
		Container: "devcontainer-vault",
		Command:   []string{"server"},
		Ports: []orchestration.PortMapping{
			{Host: "8200", Container: "8200", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"VAULT_DEV_ROOT_TOKEN_ID":  "root-token-dev",
			"VAULT_DEV_LISTEN_ADDRESS": "0.0.0.0:8200",
			"VAULT_ADDR":               "http://0.0.0.0:8200",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_vault-data", Container: "/vault/file", ReadOnly: false},
			{Host: "devcontainer_vault-logs", Container: "/vault/logs", ReadOnly: false},
		},
		Networks: []string{network},
		Profiles: []string{"secrets"},
		Restart:  "unless-stopped",
		CapAdd:   []string{"IPC_LOCK"},
		HealthCheck: &orchestration.HealthCheck{
			Test:        []string{"CMD-SHELL", "vault status || exit 0"},
			Interval:    "30s",
			Timeout:     "10s",
			Retries:     3,
			StartPeriod: "10s",
		},
		Description: "🔐 Vault - Secrets Management",
	})
}
