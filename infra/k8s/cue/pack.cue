package k8s

import "list"

// pack.cue — output paths + generated file roll-up (params: defaults.cue).

paths: {
	k8sRoot: ".k8s"

	clusterDir: ".k8s/cluster"

	gitDir:     ".k8s/git"
	gitApp:     ".k8s/git/app.yaml"
	gitProject: ".k8s/git/project.yaml"
	gitSet:     ".k8s/git/set.yaml"

	data: {
		dir:       ".k8s/data"
		namespace: ".k8s/data/namespace.yaml"
		install:   ".k8s/data/install.yaml"
	}

	gpuDir: ".k8s/gpu"
	gpu: {
		operatorInstall: ".k8s/gpu/operator-install.yaml"
		migConfig:       ".k8s/gpu/mig-config.yaml"
		timeSlicing:     ".k8s/gpu/time-slicing.yaml"
		dcgmExporter:    ".k8s/gpu/dcgm-exporter.yaml"
	}

	release: {
		root:     ".k8s/release"
		platform: ".k8s/release/platform"
		workflow: ".k8s/release/workflow"
		bots:     ".k8s/release/bots"
		obs:      ".k8s/release/obs"
		data:     ".k8s/data"
	}

	stack: {
		base:             ".k8s/stack"
		knativeBootstrap: ".k8s/stack/knative-bootstrap"
		helmCatalog:      ".k8s/stack/helm-catalog"
	}
}

_stackEnabled: [string]: bool
_stackEnabled: {
	for s in params.stack.enabled {
		(s): true
	}
}

_stackKnativeBootstrapOn: bool & list.Contains(params.stack.enabled, "knative-bootstrap")
_stackHelmCatalogOn: bool & list.Contains(params.stack.enabled, "helm-catalog")

_stackNestedAll: [string]: [string]: [...]
_stackNestedAll: stackComponentGeneratedFiles & {
	if _stackKnativeBootstrapOn {
		"knative-bootstrap": stackKnativeBootstrapGeneratedFiles
	}
	if _stackHelmCatalogOn {
		"helm-catalog": stackHelmCatalogGeneratedFiles
	}
}

stackFlattenedFiles: [string]: [...]
stackFlattenedFiles: {
	for component, files in _stackNestedAll {
		for fileName, docs in files {
			"\(paths.stack.base)/\(component)/\(fileName)": docs
		}
	}
}

allGeneratedFiles: [string]: [...]
allGeneratedFiles:
	clusterGeneratedFiles &
	gitGeneratedFiles &
	dataGeneratedFiles &
	gpuGeneratedFiles &
	stackFlattenedFiles &
	releaseBotsGeneratedFiles &
	releasePlatformGeneratedFiles &
	releaseWorkflowGeneratedFiles &
	releaseObsGeneratedFiles
