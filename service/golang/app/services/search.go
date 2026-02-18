package services

import (
	"github.com/chainrice/rice/backend/app/orchestration"
)

// RegisterSearchServices registers search services
func RegisterSearchServices(o *orchestration.Orchestrator, network string) {
	// Elasticsearch
	o.RegisterService(&orchestration.Service{
		Name:      "elasticsearch",
		Image:     "docker.elastic.co/elasticsearch/elasticsearch:8.16.0",
		Container: "devcontainer-elasticsearch",
		Ports: []orchestration.PortMapping{
			{Host: "9200", Container: "9200", Protocol: "tcp"},
			{Host: "9300", Container: "9300", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"discovery.type":         "single-node",
			"ES_JAVA_OPTS":           "-Xms1g -Xmx1g",
			"xpack.security.enabled": "false",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_elasticsearch-data", Container: "/usr/share/elasticsearch/data", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"search"},
		Restart:     "unless-stopped",
		Description: "🔍 Elasticsearch - Search Engine",
	})

	// Weaviate
	o.RegisterService(&orchestration.Service{
		Name:      "weaviate",
		Image:     "semitechnologies/weaviate:latest",
		Container: "devcontainer-weaviate",
		Ports: []orchestration.PortMapping{
			{Host: "8084", Container: "8080", Protocol: "tcp"},
		},
		Environment: map[string]string{
			"QUERY_DEFAULTS_LIMIT":                    "25",
			"AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED": "true",
			"PERSISTENCE_DATA_PATH":                   "/var/lib/weaviate",
			"DEFAULT_VECTORIZER_MODULE":               "none",
			"ENABLE_MODULES":                          "text2vec-openai,text2vec-cohere,text2vec-huggingface",
			"CLUSTER_HOSTNAME":                        "node1",
		},
		Volumes: []orchestration.VolumeMapping{
			{Host: "devcontainer_weaviate-data", Container: "/var/lib/weaviate", ReadOnly: false},
		},
		Networks:    []string{network},
		Profiles:    []string{"storage", "ml"},
		Restart:     "unless-stopped",
		Description: "🔍 Weaviate - Vector Database for AI embeddings",
	})
}
