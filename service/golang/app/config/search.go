package config

// ElasticsearchConfig represents Elasticsearch service configuration
type ElasticsearchConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS OpenSearch, GCP Elastic, Azure Cognitive Search)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}

// WeaviateConfig represents Weaviate service configuration (vector search)
type WeaviateConfig struct {
	Image         string
	ContainerName string
	Ports         []PortMapping
	Environment   map[string]string
	Volumes       []VolumeMapping
	Network       string
	RestartPolicy string
	Cloud         interface{} // *CloudConfig - cloud configuration (AWS Bedrock, GCP Vertex AI, Azure OpenAI)
	UseCloud      bool        // Whether to use cloud service instead of Docker
}
