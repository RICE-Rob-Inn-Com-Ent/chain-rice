package config

// TraefikConfig represents Traefik service configuration
type TraefikConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Command       []string
	Environment   map[string]string
	Volumes       []VolumeMapping
	Capabilities  []string
	HealthCheck   HealthCheckConfig
	Network       string
	RestartPolicy string
	DependsOn     []string
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS ALB/NLB, GCP Load Balancer, Azure Load Balancer)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}
