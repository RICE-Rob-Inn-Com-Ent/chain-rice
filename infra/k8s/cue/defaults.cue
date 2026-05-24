package k8s

import infra "github.com/rice-rob-inn-com-ent/rice/infra/proto/cue:infra"

// MASON defaults on #K8sParams (| *) + stack catalog — CHIEF projectParams override.

#K8sParams: infra.#K8sParams & {
	profile: name: string | *"local"

	gitops: {
		repoURL:         string | *"https://github.com/REPLACE_ORG/REPLACE_REPO.git"
		targetRevision:  string | *"HEAD"
		clusterServer:   string | *"https://kubernetes.default.svc"
		argocdNamespace: string | *"argocd"
		rootAppName:     string | *"gitops-root"
		prune:           bool | *true
		selfHeal:        bool | *true
		syncOptions: [...string] | *[
			"CreateNamespace=true",
			"ServerSideApply=true",
		]
	}

	helm: versions: [string]: string

	stack: enabled: [...string]

	serverless: {
		minScale:               int | *0
		maxScale:               int | *10
		scaleToZeroGracePeriod: string | *"30s"
		idleTimeout:            string | *"60s"
		targetUtilization:      string | *"80"
		ingressClass:           string | *"kourier.ingress.networking.knative.dev"
		domain:                 string | *"svc.cluster.local"
	}

	gpu: {
		enabled:              bool | *true
		namespace:            string | *"gpu-system"
		operatorChartVersion: string | *"v24.9.1"
		migStrategy:          string | *"single"
		timeSliceReplicas:    string | *"4"
		dcgmExporterVersion:  string | *"3.3.6-3.4.0-ubuntu22.04"
	}

	bots: {
		imageRegistry:   string | *"ghcr.io"
		imageOrg:        string | *"REPLACE_ORG"
		imageTag:        string | *"dev"
		namespace:       string | *"bots"
		imagePullPolicy: string | *"IfNotPresent"
		roles:           [...#K8sBotRole]
		quota: {
			requestsCpu:    string | *"8"
			requestsMemory: string | *"16Gi"
			limitsCpu:      string | *"16"
			limitsMemory:   string | *"32Gi"
			pods:           string | *"32"
		}
	}

	data: {
		namespace: string | *"data"
		nats:      #K8sDataSlot & {enabled: true, chartVersion: "1.2.6"}
		qdrant:    #K8sDataSlot & {enabled: true, chartVersion: "1.11.0"}
		yugabyte:  #K8sDataSlot & {enabled: true, chartVersion: "2.25.0"}
		ray:       #K8sDataSlot & {enabled: false, chartVersion: "1.1.0"}
	}

	obs: {
		profile:         string | *"standard"
		namespace:       string | *"obs"
		serviceMonitors: bool | *true
		victoriaMetrics: #K8sObsComponent & {enabled: bool | *true}
		grafana:         #K8sObsComponent & {enabled: bool | *true}
		loki:            #K8sObsComponent & {enabled: bool | *true}
		tempo:           #K8sObsComponent & {enabled: bool | *false}
		alertmanager:    #K8sObsComponent & {enabled: bool | *true}
		otelOperator:    #K8sObsComponent & {enabled: bool | *false}
	}

	workflow: {
		namespace: string | *"workflow"
		temporal:  enabled: bool | *false
		keda:      enabled: bool | *false
	}

	policy: {
		kyvernoDigestRequired: bool | *false
		falcoProfile:          string | *"default"
	}

	cluster: slices: [...string] | *[
		"platform",
		"gpu",
		"knative",
		"data",
		"workflow",
		"bots",
		"obs",
	]
}

#K8sStackComponent: infra.#K8sStackComponent & {
	enabled:       bool | *true
	replicaCount:  int | *1
	cpuRequest:    string | *"100m"
	memoryRequest: string | *"256Mi"
	memoryLimit:   string | *"1Gi"
}

#K8sDataSlot: infra.#K8sDataSlot & {
	replicas:     int | *1
	memory:       string | *"1Gi"
	storageClass: string | *"standard"
}

#K8sObsComponent: infra.#K8sObsComponent & {
	retention:      string | *"15d"
	scrapeInterval: string | *"30s"
	storageSize:    string | *"10Gi"
}

#K8sBotRole: infra.#K8sBotRole & {
	minScale:       int | *0
	memRequest:     string | *"256Mi"
	memLimit:       string | *"1Gi"
	cpuRequest:     string | *"100m"
	cpuLimit:       string | *"1000m"
	concurrency:    int | *80
	targetUtilPct:  string | *"80"
	scaleMax:       string | *"10"
	timeoutSeconds: int | *300
	port:           int | *8080
}

_stackComponentBase: #K8sStackComponent & {
	namespace:     string
	replicaCount:  1
	cpuRequest:    "100m"
	memoryRequest: "256Mi"
	memoryLimit:   "1Gi"
}

_stackComponents: [string]: #K8sStackComponent
_stackComponents: {
	argocd:             _stackComponentBase & {namespace: "argocd"}
	dagger:             _stackComponentBase & {namespace: "dagger"}
	crossplane:         _stackComponentBase & {namespace: "crossplane-system"}
	velero:             _stackComponentBase & {namespace: "velero"}
	cilium:             _stackComponentBase & {namespace: "kube-system"}
	gateway:            _stackComponentBase & {namespace: "gateway"}
	karpenter:          _stackComponentBase & {namespace: "karpenter"}
	"external-secrets": _stackComponentBase & {namespace: "external-secrets"}
	kyverno:            _stackComponentBase & {namespace: "kyverno"}
	falco:              _stackComponentBase & {namespace: "falco"}
	harbor:             _stackComponentBase & {namespace: "harbor"}
	"cert-manager":     _stackComponentBase & {namespace: "cert-manager"}
	keda:               _stackComponentBase & {namespace: "keda"}
	"knative-bootstrap": _stackComponentBase & {namespace: "knative-serving"}
	knative:            _stackComponentBase & {namespace: "knative-serving"}
	alertmanager:       _stackComponentBase & {namespace: "obs"}
	grafana:            _stackComponentBase & {namespace: "obs"}
	loki:               _stackComponentBase & {namespace: "obs"}
	tempo:              _stackComponentBase & {namespace: "obs", enabled: params.obs.tempo.enabled}
	"victoria-metrics": _stackComponentBase & {namespace: "obs"}
	"otel-operator":    _stackComponentBase & {namespace: "obs", enabled: params.obs.otelOperator.enabled}
	"helm-catalog":     _stackComponentBase & {namespace: "kube-system"}
}

params: #K8sParams & projectParams
params: stack: {
	enabled:    params.stack.enabled
	components: _stackComponents
}
