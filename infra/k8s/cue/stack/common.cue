package k8s

import "strings"

_activeProfile: params.profile.name

#stackStub: {
	_component:       string
	_targetNamespace: string
	_fileName:        string
	_note:            string
	_replicaCount:    int | *1
	_cpuRequest:      string | *"100m"
	_memoryRequest:   string | *"256Mi"
	_memoryLimit:     string | *"1Gi"

	_valuesLocal: """
		profile: \(_activeProfile)
		replicaCount: \(_replicaCount)
		resources:
		  requests:
		    cpu: \(_cpuRequest)
		    memory: \(_memoryRequest)
		  limits:
		    memory: \(_memoryLimit)
		"""
	_valuesProd: """
		profile: prod
		replicaCount: 3
		podDisruptionBudget:
		  minAvailable: 1
		resources:
		  requests:
		    cpu: \(_cpuRequest)
		    memory: \(_memoryRequest)
		  limits:
		    memory: \(_memoryLimit)
		"""
	_helmReadme: """
		# \(_component) — Helm install

		Active CHIEF profile: \(_activeProfile). Use values-\(_activeProfile).yaml when profile is local or prod.

		```bash
		helm upgrade --install \(_component) <CHART> \\
		  --namespace \(_targetNamespace) --create-namespace \\
		  -f values-\(_activeProfile).yaml
		```
		See .k8s/stack/helm-catalog/helm-catalog.yaml for chart coordinates.
		"""

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "mason-stub-\(strings.TrimSuffix(_fileName, ".yaml"))"
		namespace: _targetNamespace
		labels: {
			"app.kubernetes.io/part-of": _component
			"infra.mason/source-cue":    "infra/k8s/cue/stack/generate.cue"
			"infra.mason/stack-file":    _fileName
			"infra.mason/chief-profile": _activeProfile
		}
	}
	data: {
		"TODO.md":           _note
		"values-local.yaml": strings.TrimSpace(_valuesLocal)
		"values-prod.yaml":  strings.TrimSpace(_valuesProd)
		"HELM.md":           strings.TrimSpace(_helmReadme)
	}
}
