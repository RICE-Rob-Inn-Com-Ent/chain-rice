package k8s

// `.k8s/stack/` — cluster platform slices grouped by role (not aligned to `.docker/`).
// Logical tiers (A–H). Emitted manifests live at `.k8s/stack/<vendor>/` (see sibling `*.cue`).
//
// | Tag | Tier key       | Role |
// |-----|----------------|------|
// | A   | delivery       | GitOps + delivery controllers (Argo CD, Dagger, Crossplane, Velero) |
// | B   | network        | L3–L7 (Cilium, Gateway API) |
// | C   | compute        | Node provisioning (Karpenter) |
// | D   | secrets        | External secret sync |
// | E   | policy         | Admission + runtime security (Kyverno, Falco) |
// | F   | artifacts      | Registry / supply chain (Harbor) |
// | G   | runtime        | Workload runtime: TLS, scale-to-zero, autoscale hooks (cert-manager, KEDA, Knative) |
// | H   | observability  | Logs / metrics / traces (Grafana stack, Victoria, Tempo, OTel, Alertmanager) |

#StackTier: {
	tag:        string
	key:        string
	purpose:    string
	components: [...string]
}

stackTiers: [...#StackTier]
stackTiers: [
	{
		tag:     "A"
		key:     "delivery"
		purpose: "GitOps and cluster delivery controllers"
		components: ["argocd", "dagger", "crossplane", "velero"]
	},
	{
		tag:     "B"
		key:     "network"
		purpose: "L3–L7 networking and ingress"
		components: ["cilium", "gateway"]
	},
	{
		tag:     "C"
		key:     "compute"
		purpose: "Node provisioning"
		components: ["karpenter"]
	},
	{
		tag:     "D"
		key:     "secrets"
		purpose: "External secret sync into the cluster"
		components: ["external-secrets"]
	},
	{
		tag:     "E"
		key:     "policy"
		purpose: "Admission policies and runtime security"
		components: ["kyverno", "falco"]
	},
	{
		tag:     "F"
		key:     "artifacts"
		purpose: "Container registry and artifact supply chain"
		components: ["harbor"]
	},
	{
		tag:     "G"
		key:     "runtime"
		purpose: "TLS, scale-to-zero (Knative), workload autoscaling (KEDA)"
		components: ["cert-manager", "keda", "knative", "knative-bootstrap"]
	},
	{
		tag:     "H"
		key:     "observability"
		purpose: "Signals: metrics, logs, traces"
		components: ["alertmanager", "grafana", "loki", "tempo", "victoria-metrics", "otel-operator"]
	},
]
