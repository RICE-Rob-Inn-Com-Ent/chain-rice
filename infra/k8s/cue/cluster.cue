package k8s

defaults: {
	repoURL:         params.gitops.repoURL
	targetRevision:  params.gitops.targetRevision
	clusterServer:   params.gitops.clusterServer
	argocdNamespace: params.gitops.argocdNamespace
	rootAppName:     params.gitops.rootAppName
}

#ClusterApp: {
	metadataName: string
	fileName:     string
	sourcePath:   string
	namespace:    string
	project:      string | *"default"
	syncWave:     string | *"0"
}

_clusterCatalog: [string]: #ClusterApp
_clusterCatalog: {
	platform: {
		metadataName: "platform"
		fileName:     "platform.yaml"
		sourcePath:   paths.release.platform
		namespace:    "platform"
		syncWave:     "0"
	}
	gpu: {
		metadataName: "gpu"
		fileName:     "gpu.yaml"
		sourcePath:   paths.gpuDir
		namespace:    params.gpu.namespace
		syncWave:     "5"
	}
	knative: {
		metadataName: "knative"
		fileName:     "knative.yaml"
		sourcePath:   paths.stack.knativeBootstrap
		namespace:    "knative-serving"
		syncWave:     "7"
	}
	data: {
		metadataName: "data"
		fileName:     "data.yaml"
		sourcePath:   paths.release.data
		namespace:    params.data.namespace
		syncWave:     "10"
	}
	workflow: {
		metadataName: "workflow"
		fileName:     "workflow.yaml"
		sourcePath:   paths.release.workflow
		namespace:    params.workflow.namespace
		syncWave:     "20"
	}
	bots: {
		metadataName: "bots"
		fileName:     "bots.yaml"
		sourcePath:   paths.release.bots
		namespace:    params.bots.namespace
		syncWave:     "30"
	}
	obs: {
		metadataName: "obs"
		fileName:     "obs.yaml"
		sourcePath:   paths.release.obs
		namespace:    params.obs.namespace
		syncWave:     "40"
	}
}

clusterApps: [
	for slice in params.cluster.slices {
		_clusterCatalog[slice]
	},
]

argoClusterApplications: {
	for app in clusterApps {
		(app.fileName): {
			apiVersion: "argoproj.io/v1alpha1"
			kind:       "Application"
			metadata: {
				name:      app.metadataName
				namespace: defaults.argocdNamespace
				annotations: {
					"infra.mason/source-cue":       "infra/k8s/cue/cluster.cue"
					"argocd.argoproj.io/sync-wave": app.syncWave
				}
				finalizers: ["resources-finalizer.argocd.argoproj.io"]
			}
			spec: {
				project: app.project
				source: {
					repoURL:        defaults.repoURL
					targetRevision: defaults.targetRevision
					path:           app.sourcePath
				}
				destination: {
					server:    defaults.clusterServer
					namespace: app.namespace
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
	}
}

clusterGeneratedFiles: {
	for app in clusterApps {
		"\(paths.clusterDir)/\(app.fileName)": [argoClusterApplications[app.fileName]]
	}
}
