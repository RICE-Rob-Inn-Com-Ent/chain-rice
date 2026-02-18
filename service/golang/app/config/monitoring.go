package config

// PrometheusConfig represents Prometheus service configuration
type PrometheusConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Command       []string
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	DependsOn     []string
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS CloudWatch, GCP Cloud Monitoring, Azure Monitor)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}

// GrafanaConfig represents Grafana service configuration
type GrafanaConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	DependsOn     []string
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS Grafana, GCP Grafana, Azure Grafana)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}

// JaegerConfig represents Jaeger service configuration
type JaegerConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS X-Ray, GCP Cloud Trace, Azure Application Insights)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}

// LokiConfig represents Loki service configuration
type LokiConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Command       []string
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	HealthCheck   HealthCheckConfig
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS CloudWatch Logs, GCP Cloud Logging, Azure Log Analytics)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}
