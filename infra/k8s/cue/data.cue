package k8s

import "list"

#DataSlotDoc: {
	slot:          string
	configMapName: string
	chart:         string
	values:        string
}

_dataSlots: [...#DataSlotDoc]
_dataSlots: [
	if params.data.nats.enabled {
		{
			slot:          "nats"
			configMapName: "data-nats-values"
			chart:         "nats/nats"
			values: """
				nats:
				  jetstream:
				    enabled: true
				    memStorage: \(params.data.nats.memory)
				replicaCount: \(params.data.nats.replicas)
				"""
		}
	},
	if params.data.qdrant.enabled {
		{
			slot:          "qdrant"
			configMapName: "data-qdrant-values"
			chart:         "qdrant/qdrant"
			values: """
				replicaCount: \(params.data.qdrant.replicas)
				resources:
				  requests:
				    memory: \(params.data.qdrant.memory)
				persistence:
				  storageClass: \(params.data.qdrant.storageClass)
				"""
		}
	},
	if params.data.yugabyte.enabled {
		{
			slot:          "yugabyte"
			configMapName: "data-yugabyte-values"
			chart:         "yugabytedb/yugaware"
			values: """
				replicaCount: \(params.data.yugabyte.replicas)
				resource:
				  master:
				    memory: \(params.data.yugabyte.memory)
				  tserver:
				    memory: \(params.data.yugabyte.memory)
				storageClass: \(params.data.yugabyte.storageClass)
				"""
		}
	},
	if params.data.ray.enabled {
		{
			slot:          "ray"
			configMapName: "data-ray-values"
			chart:         "ray-project/ray-cluster"
			values: """
				head:
				  resources:
				    limits:
				      memory: \(params.data.ray.memory)
				"""
		}
	},
]

dataNamespaceDoc: [{
	apiVersion: "v1"
	kind:       "Namespace"
	metadata: {
		name: params.data.namespace
		labels: {
			"app.kubernetes.io/part-of": "data"
		}
	}
}]

dataInstallDocuments: [
	for slot in _dataSlots {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      slot.configMapName
			namespace: params.data.namespace
			labels: {
				"infra.mason/data-plane": slot.slot
				"infra.mason/helm-chart": slot.chart
			}
		}
		data: {
			"values.yaml": slot.values
			"HELM.md":     "helm upgrade --install \(slot.slot) \(slot.chart) -n \(params.data.namespace) -f values.yaml"
		}
	},
]

dataGeneratedFiles: {
	"\(paths.data.namespace)": dataNamespaceDoc
	"\(paths.data.install)":   list.Concat([dataNamespaceDoc, dataInstallDocuments])
}
