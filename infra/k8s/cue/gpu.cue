package k8s

gpu: {
	namespace:            params.gpu.namespace
	operatorChartVersion: params.gpu.operatorChartVersion
	migStrategy:          params.gpu.migStrategy
	timeSliceReplicas:    params.gpu.timeSliceReplicas
	dcgmExporterVersion:  params.gpu.dcgmExporterVersion
}

gpuOperatorInstallDocs: [
	if params.gpu.enabled {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: gpu.namespace
			labels: {"app.kubernetes.io/part-of": "gpu"}
		}
	},
	if params.gpu.enabled {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "gpu-operator-install-meta"
			namespace: gpu.namespace
			annotations: {
				"infra.mason/helm-chart":    "nvidia/gpu-operator"
				"infra.mason/chart-version": gpu.operatorChartVersion
			}
		}
		data: {
			"values.yaml": "operator:\n  defaultRuntime: containerd\ndriver:\n  enabled: true\n"
			"install.txt": "helm upgrade --install gpu-operator nvidia/gpu-operator -n \(gpu.namespace) -f values.yaml"
		}
	},
]

gpuMigConfigDocs: [
	if params.gpu.enabled {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "nvidia-mig-config"
			namespace: gpu.namespace
		}
		data: "mig-strategy": gpu.migStrategy
	},
]

gpuTimeSlicingDocs: [
	if params.gpu.enabled {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "nvidia-time-slicing"
			namespace: gpu.namespace
		}
		data: "replicas": gpu.timeSliceReplicas
	},
]

gpuDcgmExporterDocs: [
	if params.gpu.enabled {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "dcgm-exporter-bundle"
			namespace: gpu.namespace
			annotations: {"infra.mason/image-tag": gpu.dcgmExporterVersion}
		}
		data: "install.txt": "DCGM exporter image tag \(gpu.dcgmExporterVersion)"
	},
]

gpuGeneratedFiles: {
	if params.gpu.enabled {
		"\(paths.gpu.operatorInstall)": gpuOperatorInstallDocs
		"\(paths.gpu.migConfig)":       gpuMigConfigDocs
		"\(paths.gpu.timeSlicing)":     gpuTimeSlicingDocs
		"\(paths.gpu.dcgmExporter)":    gpuDcgmExporterDocs
	}
}
