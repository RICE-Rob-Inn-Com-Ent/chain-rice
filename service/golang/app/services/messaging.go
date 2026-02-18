package services

import (
	"github.com/chainrice/rice/backend/app/orchestration"
)

// RegisterMessagingServices registers messaging services
func RegisterMessagingServices(o *orchestration.Orchestrator, network string) {
	// Kafka
	o.RegisterService(&orchestration.Service{
		Name:      "kafka",
		Image:     "confluentinc/cp-kafka:7.5.0",
		Container: "devcontainer-kafka",
		Ports: []orchestration.PortMapping{
			{Host: "9092", Container: "9092", Protocol: "tcp"},
			{Host: "9093", Container: "9093", Protocol: "tcp"},
		},
		Environment: map[string]string{
			// KRaft mode configuration
			"KAFKA_PROCESS_ROLES":                            "broker,controller",
			"KAFKA_NODE_ID":                                  "1",
			"KAFKA_CONTROLLER_QUORUM_VOTERS":                 "1@localhost:9093",
			"KAFKA_LISTENERS":                                "PLAINTEXT://:9092,CONTROLLER://:9093",
			"KAFKA_ADVERTISED_LISTENERS":                     "PLAINTEXT://localhost:9092",
			"KAFKA_CONTROLLER_LISTENER_NAMES":                "CONTROLLER",
			"KAFKA_LISTENER_SECURITY_PROTOCOL_MAP":           "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT",
			"KAFKA_INTER_BROKER_LISTENER_NAME":               "PLAINTEXT",
			"KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR":         "1",
			"KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR": "1",
			"KAFKA_TRANSACTION_STATE_LOG_MIN_ISR":            "1",
		},
		Networks:  []string{network},
		Profiles:  []string{"messaging"},
		DependsOn: []string{}, // No dependencies - KRaft mode doesn't need Zookeeper
		Restart:   "unless-stopped",
		HealthCheck: &orchestration.HealthCheck{
			Test:     []string{"CMD", "kafka-broker-api-versions", "--bootstrap-server", "localhost:9092"},
			Interval: "30s",
			Timeout:  "10s",
			Retries:  3,
		},
		Description: "🚀 Apache Kafka - Streaming platform (KRaft mode)",
	})

	// Kafka UI
	o.RegisterService(&orchestration.Service{
		Name:      "kafka-ui",
		Image:     "provectuslabs/kafka-ui:latest",
		Container: "devcontainer-kafka-ui",
		Ports: []orchestration.PortMapping{
			{Host: "8083", Container: "8080", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"KAFKA_CLUSTERS_0_NAME":             "local",
			"KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS": "kafka:9092",
			// No Zookeeper needed - using KRaft mode
		},
		Networks:    []string{network},
		Profiles:    []string{"messaging", "admin"},
		DependsOn:   []string{"kafka"},
		Restart:     "unless-stopped",
		Description: "🎨 Kafka UI - Management UI for Kafka (KRaft mode)",
	})

	// RabbitMQ
	o.RegisterService(&orchestration.Service{
		Name:      "rabbitmq",
		Image:     "rabbitmq:3-management-alpine",
		Container: "devcontainer-rabbitmq",
		Ports: []orchestration.PortMapping{
			{Host: "5672", Container: "5672", Protocol: "tcp"},
			{Host: "15672", Container: "15672", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"RABBITMQ_DEFAULT_USER": "admin",
			"RABBITMQ_DEFAULT_PASS": "admin",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_rabbitmq-data", Container: "/var/lib/rabbitmq", ReadOnly: false},
		},
		Networks: []string{network},
		Profiles: []string{"messaging"},
		Restart:  "unless-stopped",
		HealthCheck: &orchestration.HealthCheck{
			Test:     []string{"CMD", "rabbitmq-diagnostics", "ping"},
			Interval: "30s",
			Timeout:  "10s",
			Retries:  3,
		},
		Description: "🐰 RabbitMQ - Message Queue",
	})
}
