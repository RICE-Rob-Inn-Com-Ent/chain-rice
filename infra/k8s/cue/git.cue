package k8s

argoRootApplication: {
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "Application"
	metadata: {
		name:      defaults.rootAppName
		namespace: defaults.argocdNamespace
		annotations: {
			"infra.mason/source-cue":       "infra/k8s/cue/git.cue"
			"argocd.argoproj.io/sync-wave": "-1"
		}
		finalizers: ["resources-finalizer.argocd.argoproj.io"]
	}
	spec: {
		project: "default"
		source: {
			repoURL:        defaults.repoURL
			targetRevision: defaults.targetRevision
			path:           paths.clusterDir
			directory: {
				recurse: false
				include: "*.yaml"
			}
		}
		destination: {
			server:    defaults.clusterServer
			namespace: defaults.argocdNamespace
		}
		syncPolicy: {
			if params.gitops.prune || params.gitops.selfHeal {
				automated: {
					if params.gitops.prune {
						prune: true
					}
					if params.gitops.selfHeal {
						selfHeal: true
					}
				}
			}
			syncOptions: params.gitops.syncOptions
		}
	}
}

gitAppDocuments: [argoRootApplication]

#GitStub: {
	key:   string
	title: string
}

gitProjectStubs: [...#GitStub]
gitProjectStubs: [
	{key: "umbrella", title: "Top-level umbrella AppProject"},
	{key: "ai", title: "AI apps"},
	{key: "data", title: "Data plane"},
	{key: "workflow", title: "Workflow / Temporal"},
	{key: "platform", title: "Platform stack"},
]

gitSetStubs: [...#GitStub]
gitSetStubs: [
	{key: "obs", title: "Observability stack"},
	{key: "platform", title: "Platform components"},
	{key: "ai", title: "AI workloads"},
	{key: "data", title: "Data plane apps"},
	{key: "workflow", title: "Temporal / workflow"},
	{key: "namespaces", title: "Namespace provisioning"},
	{key: "roles", title: "Role workloads"},
]

gitProjectDocuments: [
	for s in gitProjectStubs {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "git-stub-appproject-\(s.key)"
			namespace: "default"
			annotations: {
				"infra.mason/source-cue": "infra/k8s/cue/git.cue"
				"infra.mason/stub-kind":  "AppProject"
				"infra.mason/stub-key":   s.key
			}
		}
		data: title: s.title
	},
]

gitSetDocuments: [
	for s in gitSetStubs {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "git-stub-applicationset-\(s.key)"
			namespace: "default"
			annotations: {
				"infra.mason/source-cue": "infra/k8s/cue/git.cue"
				"infra.mason/stub-kind":  "ApplicationSet"
				"infra.mason/stub-key":   s.key
			}
		}
		data: title: s.title
	},
]

gitGeneratedFiles: {
	"\(paths.gitApp)":     gitAppDocuments
	"\(paths.gitProject)": gitProjectDocuments
	"\(paths.gitSet)":     gitSetDocuments
}
