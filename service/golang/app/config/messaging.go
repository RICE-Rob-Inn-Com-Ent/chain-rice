package config

// KafkaConfig represents Kafka service configuration (KRaft mode - no Zookeeper needed)
type KafkaConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Environment   map[string]string
	Network       string
	RestartPolicy string
	DependsOn     []string
	HealthCheck   HealthCheckConfig
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS MSK, GCP Pub/Sub, Azure Event Hubs)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}

// RabbitMQConfig represents RabbitMQ service configuration
type RabbitMQConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	HealthCheck   HealthCheckConfig
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS SQS/SNS, GCP Pub/Sub, Azure Service Bus)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}
