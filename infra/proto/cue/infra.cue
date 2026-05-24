package infra

// infra.cue — CHIEF *.rice ↔ Mint contract (types only; defaults in MASON cue/defaults.cue).

#BotRole: {
	model_id:       string
	backend:        string
	quantization?:  string
	pull_on_start?: bool
}

#DockerParams: {
	compose: {
		projectName: string

		db: {
			name: string
			user: string
		}

		redis: {
			memoryLimit: string
			maxmemory:   string
		}

		yugabyte: {
			memoryLimit: string
		}

		qdrant: {
			memoryLimit:      string
			hnswM:            int
			efConstruct:      int
			maxRequestSizeMb: int
			quantization:     string
		}

		nats: {
			memoryLimit:      string
			jetstreamMaxMem:  string
			jetstreamMaxFile: string
			maxPayload:       string
		}

		temporal: {
			memoryLimit: string
		}

		postal: profile: string

		mailpit: {
			profile:     string
			maxMessages: string
			database:    string
		}

		ollama: {
			profile:         string
			memoryLimit:     string
			autoPull:        bool
			backend:         string
			maxLoadedModels: string
			keepAlive:       string
			numParallel:     string
			gpuCount:        int
		}

		vllm: {
			profile:              string
			memoryLimit:          string
			model:                string
			loraMount:            string
			weightsMount:         string
			enableLora:           bool
			maxLoraRank:          string
			gpuMemoryUtilization: string
			maxNumSeqs:           string
			gpuCount:             int
		}
	}

	db: init: sql: [...string]

	bot: registry: {
		version:               string
		pull_on_start_default: bool
		pull_retries:          int
		roles: [string]: #BotRole
		fallback_chain: [...string]
	}
}

// Rice docker.rice: bowl [package] infra = "" | use infra as docker | rc docker let { … }
// bowl [project] name → compose.projectName (not in docker.rice)

#K8sBotRole: {
	name:           string
	minScale:       int
	memRequest:     string
	memLimit:       string
	cpuRequest:     string
	cpuLimit:       string
	concurrency:    int
	targetUtilPct:  string
	scaleMax:       string
	timeoutSeconds: int
	port:           int
}

#K8sStackComponent: {
	enabled:       bool
	namespace:     string
	replicaCount:  int
	cpuRequest:    string
	memoryRequest: string
	memoryLimit:   string
}

#K8sDataSlot: {
	enabled:      bool
	replicas:     int
	memory:       string
	storageClass: string
	chartVersion: string
}

#K8sObsComponent: {
	enabled:        bool
	retention:      string
	scrapeInterval: string
	storageSize:    string
}

#K8sParams: {
	profile: name: string

	gitops: {
		repoURL:         string
		targetRevision:  string
		clusterServer:   string
		argocdNamespace: string
		rootAppName:     string
		prune:           bool
		selfHeal:        bool
		syncOptions: [...string]
	}

	helm: versions: [string]: string

	stack: {
		enabled: [...string]
		components: [string]: #K8sStackComponent
	}

	serverless: {
		minScale:               int
		maxScale:               int
		scaleToZeroGracePeriod: string
		idleTimeout:            string
		targetUtilization:      string
		ingressClass:           string
		domain:                 string
	}

	gpu: {
		enabled:              bool
		namespace:            string
		operatorChartVersion: string
		migStrategy:          string
		timeSliceReplicas:    string
		dcgmExporterVersion:  string
	}

	bots: {
		imageRegistry:   string
		imageOrg:        string
		imageTag:        string
		namespace:       string
		imagePullPolicy: string
		roles: [...#K8sBotRole]
		quota: {
			requestsCpu:    string
			requestsMemory: string
			limitsCpu:      string
			limitsMemory:   string
			pods:           string
		}
	}

	data: {
		namespace: string
		nats:      #K8sDataSlot
		qdrant:    #K8sDataSlot
		yugabyte:  #K8sDataSlot
		ray:       #K8sDataSlot
	}

	obs: {
		profile:         string
		namespace:       string
		serviceMonitors: bool
		victoriaMetrics: #K8sObsComponent
		grafana:         #K8sObsComponent
		loki:            #K8sObsComponent
		tempo:           #K8sObsComponent
		alertmanager:    #K8sObsComponent
		otelOperator:    #K8sObsComponent
	}

	workflow: {
		namespace: string
		temporal: enabled: bool
		keda: enabled:     bool
	}

	policy: {
		kyvernoDigestRequired: bool
		falcoProfile:          string
	}

	cluster: slices: [...string]
}

// Rice k8s.rice: bowl [package] infra = "" | use infra as k8s | rc k8s let { profile, gitops, stack?, … }

#TerraformDeployment: {
	cloud:    string
	region:   string
	vpc_cidr: string
}

#TerraformParams: {
	rice_environment:         string
	rice_cloud_provider:      string
	rice_github_org:          string
	rice_github_repo:         string
	rice_domain:              string
	rice_k8s_cluster_name:    string
	rice_db_instance_class:   string
	rice_registry:            string
	rice_region:              string
	rice_availability_zones: [...string]
	rice_vpc_cidr:            string
	rice_enable_gpu:          bool
	rice_gpu_instance_type:   string
	rice_aws_region:          string
	rice_aws_assume_role_arn: string
	rice_gcp_project_id:      string
	rice_gcp_region:          string
	rice_azure_subscription_id: string
	rice_azure_tenant_id:     string
	rice_tf_backend:          string
	rice_kubeconfig_path:     string
	rice_enabled_clouds:      [...string]
	rice_primary_cloud:       string
	rice_regions_aws:         [...string]
	rice_regions_gcp:         [...string]
	rice_regions_azure:       [...string]
	rice_deployments:         [...#TerraformDeployment]
}

// Rice terraform.rice: bowl [package] infra = "" | use infra as terraform | rc terraform let { environment, github, cluster, network, aws?, gcp?, azure?, gpu?, state }

#StackFeature: {
	enabled: bool
}

#StackParams: {
	ollama:  #StackFeature
	vllm:    #StackFeature
	postal:  #StackFeature
	mailpit: #StackFeature
	otp:     #StackFeature
	rpc:     #StackFeature
	agent:   #StackFeature
	docs:    #StackFeature
}

#ServerService: {
	enabled:      bool
	port:         int
	memoryLimit:  string
}

#ServerParams: {
	otp:   #ServerService
	rpc:   #ServerService
	agent: #ServerService
	docs:  #ServerService
}

#PlantumlDiagram: {
	name:    string
	content: string
}

#DocsParams: {
	siteUrl: string
	mkdocs: {
		siteName: string
		theme:    string
		nav: [...string]
	}
	openapi: {
		path: string
	}
	plantuml: {
		theme:    string
		diagrams: [...#PlantumlDiagram]
	}
}

#FrontendParams: {
	siteTitle:   string
	apiBaseUrl:  string
	seedColor:   string
	modules: {
		client:  bool
		browser: bool
		content: bool
		lang:    bool
		rule:    bool
		model:   bool
	}
}

// Rice docker.rice: otp/rpc/agent/docs set { … } alongside db, vllm, ollama, …
// Rice docs.rice:  use infra as docs  | rc docs let  { plantuml diagram …, mkdocs … }
// Rice frontend/site.rice: use infra as frontend | rc frontend let { modules set, … }
