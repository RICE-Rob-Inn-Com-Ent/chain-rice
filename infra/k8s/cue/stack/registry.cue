package k8s

// Per-component stack metadata (taxonomy A–H). Generation: stack/generate.cue.

#StackRegistryEntry: {
	namespace: string
	files:     [...string]
	note:      string
}

_stackRegistry: [string]: #StackRegistryEntry
_stackRegistry: {
	argocd: {
		namespace: "argocd"
		files: ["argocd-cm.yaml", "argocd-rbac-cm.yaml", "argocd-secret.yaml", "cmp-plugin.yaml", "notifications-cm.yaml", "install.yaml", "dex.yaml"]
		note:  "Argo CD — GitOps delivery; params.stack.components.argocd for replica/resources."
	}
	dagger: {
		namespace: "dagger"
		files: ["install.yaml"]
		note:  "Dagger CI engine — Helm values in ConfigMap; wire to GitOps when enabled."
	}
	crossplane: {
		namespace: "crossplane-system"
		files: ["install.yaml"]
		note:  "Crossplane — composite resource controllers."
	}
	velero: {
		namespace: "velero"
		files: ["install.yaml"]
		note:  "Velero — cluster backup/restore."
	}
	cilium: {
		namespace: "kube-system"
		files: ["install.yaml", "hubble.yaml"]
		note:  "Cilium CNI — tunnel/LB/hubble from params + profile values."
	}
	gateway: {
		namespace: "gateway"
		files: ["gatewayclass.yaml", "install.yaml"]
		note:  "Gateway API — ingress controller slice."
	}
	karpenter: {
		namespace: "karpenter"
		files: ["install.yaml", "nodepool.yaml"]
		note:  "Karpenter — OCI chart; node pools in values-prod."
	}
	"external-secrets": {
		namespace: "external-secrets"
		files: ["install.yaml", "cluster-secret-store.yaml"]
		note:  "External Secrets — ClusterSecretStore scaffold."
	}
	kyverno: {
		namespace: "kyverno"
		files: ["install.yaml", "policies.yaml"]
		note:  "Kyverno — digest/cosign policies when params.policy.kyvernoDigestRequired."
	}
	falco: {
		namespace: "falco"
		files: ["install.yaml"]
		note:  "Falco — runtime security; profile params.policy.falcoProfile."
	}
	harbor: {
		namespace: "harbor"
		files: ["install.yaml"]
		note:  "Harbor — OCI registry; externalURL in values-prod."
	}
	"cert-manager": {
		namespace: "cert-manager"
		files: ["install.yaml"]
		note:  "cert-manager — TLS issuers for ingress/Knative."
	}
	keda: {
		namespace: "keda"
		files: ["install.yaml"]
		note:  "KEDA — scalers for Temporal/workflow when params.workflow.keda.enabled."
	}
	knative: {
		namespace: "knative-serving"
		files: ["config-autoscale.yaml", "config-domain.yaml"]
		note:  "Knative Serving config — scale-to-zero from params.serverless."
	}
	"knative-bootstrap": {
		namespace: "knative-serving"
		files: [] // special: stackKnativeBootstrapGeneratedFiles
		note:  "Knative install bundle — kustomize remote bases."
	}
	alertmanager: {
		namespace: "obs"
		files: ["install.yaml"]
		note:  "Alertmanager — routing; enabled via params.obs."
	}
	grafana: {
		namespace: "obs"
		files: ["install.yaml", "datasources.yaml"]
		note:  "Grafana — datasources point at VM/Loki/Tempo."
	}
	loki: {
		namespace: "obs"
		files: ["install.yaml"]
		note:  "Loki — log aggregation; retention from params.obs.loki."
	}
	tempo: {
		namespace: "obs"
		files: ["install.yaml"]
		note:  "Tempo — traces; params.obs.tempo.enabled."
	}
	"victoria-metrics": {
		namespace: "obs"
		files: ["install.yaml", "vmagent.yaml"]
		note:  "VictoriaMetrics — metrics storage; scrapeInterval from params."
	}
	"otel-operator": {
		namespace: "obs"
		files: ["install.yaml"]
		note:  "OpenTelemetry operator — params.obs.otelOperator.enabled."
	}
	"helm-catalog": {
		namespace: "kube-system"
		files: [] // stackHelmCatalogGeneratedFiles
		note:  "Helm pin catalog ConfigMap."
	}
}
