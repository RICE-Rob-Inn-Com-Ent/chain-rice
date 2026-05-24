package k8s

import "encoding/yaml"

_helmCatalogBase: [string]: {
	repoURL: string
	chart:   string
	version: string
	notes?:  string
}
_helmCatalogBase: {
	argocd:              {repoURL: "https://argoproj.github.io/argo-helm", chart: "argo-cd", version: "6.7.14"}
	dagger:              {repoURL: "https://helm.dagger.io", chart: "dagger-helm", version: "0.18.0"}
	crossplane:          {repoURL: "https://charts.crossplane.io/stable", chart: "crossplane", version: "1.16.0"}
	velero:              {repoURL: "https://vmware-tanzu.github.io/helm-charts", chart: "velero", version: "8.0.0"}
	cilium:              {repoURL: "https://helm.cilium.io/", chart: "cilium", version: "1.16.1"}
	gateway:             {repoURL: "https://kubernetes-sigs.github.io/gateway-api", chart: "gateway-api", version: "1.1.0"}
	karpenter:           {repoURL: "oci://public.ecr.aws/karpenter/karpenter", chart: "karpenter", version: "1.0.6"}
	"external-secrets":  {repoURL: "https://charts.external-secrets.io", chart: "external-secrets", version: "0.10.5"}
	kyverno:             {repoURL: "https://kyverno.github.io/kyverno/", chart: "kyverno", version: "3.2.6"}
	falco:               {repoURL: "https://falcosecurity.github.io/charts", chart: "falco", version: "4.11.0"}
	harbor:              {repoURL: "https://helm.goharbor.io", chart: "harbor", version: "1.15.0"}
	"cert-manager":      {repoURL: "https://charts.jetstack.io", chart: "cert-manager", version: "v1.15.0"}
	keda:                {repoURL: "https://kedacore.github.io/charts", chart: "keda", version: "2.14.0"}
	knative:             {repoURL: "https://github.com/knative/serving/", chart: "(config)", version: "1.22.0"}
	"knative-bootstrap": {repoURL: "https://github.com/knative/serving/", chart: "(kustomize)", version: "1.22.0"}
	alertmanager:        {repoURL: "https://prometheus-community.github.io/helm-charts", chart: "alertmanager", version: "1.11.0"}
	grafana:             {repoURL: "https://grafana.github.io/helm-charts", chart: "grafana", version: "8.5.0"}
	loki:                {repoURL: "https://grafana.github.io/helm-charts", chart: "loki", version: "6.6.0"}
	tempo:               {repoURL: "https://grafana.github.io/helm-charts", chart: "tempo", version: "1.10.0"}
	"victoria-metrics":  {repoURL: "https://victoriametrics.github.io/helm-charts/", chart: "victoria-metrics-single", version: "0.14.0"}
	"otel-operator":     {repoURL: "https://open-telemetry.github.io/opentelemetry-helm-charts", chart: "opentelemetry-operator", version: "0.62.0"}
}

k8sStackHelmPins: [string]: {
	repoURL: string
	chart:   string
	version: string
	notes?:  string
}
k8sStackHelmPins: {
	for name, base in _helmCatalogBase {
		(name): base & {version: params.helm.versions[name] | base.version}
	}
}

_helmCatalogEnabled: bool & false | *[for s in params.stack.enabled if s == "helm-catalog" {true}][0]

stackHelmCatalogGeneratedFiles: [string]: [...]
stackHelmCatalogGeneratedFiles: {
	if _helmCatalogEnabled {
		"helm-catalog.yaml": [{
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "mason-helm-catalog"
				namespace: "kube-system"
				labels: {
					"app.kubernetes.io/part-of": "mason"
					"infra.mason/chief-profile": params.profile.name
				}
			}
			data: {
				"charts.yaml": yaml.Marshal(k8sStackHelmPins)
				"README.md":   "Helm catalog — CHIEF profile \(params.profile.name)"
			}
		}]
	}
}
