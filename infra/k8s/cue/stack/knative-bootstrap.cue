package k8s

_knativeVersion: params.helm.versions["knative-bootstrap"] | *"1.22.0"

_knativeBootstrapEnabled: bool & false | *[for s in params.stack.enabled if s == "knative-bootstrap" {true}][0]

stackKnativeBootstrapGeneratedFiles: [string]: [...]
stackKnativeBootstrapGeneratedFiles: {
	if _knativeBootstrapEnabled {
		"kustomization.yaml": [{
			apiVersion: "kustomize.config.k8s.io/v1beta1"
			kind:       "Kustomization"
			resources: [
				"https://github.com/knative/serving/releases/download/knative-v\(_knativeVersion)/serving-core.yaml",
				"https://github.com/knative-extensions/net-kourier/releases/download/knative-v\(_knativeVersion)/kourier.yaml",
			]
			patches: [{path: "config-network-kourier.yaml"}]
		}]
		"config-network-kourier.yaml": [{
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "config-network"
				namespace: "knative-serving"
			}
			data: "ingress-class": params.serverless.ingressClass
		}]
		"config-domain.yaml": [{
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "config-domain"
				namespace: "knative-serving"
			}
			data: "\(params.serverless.domain)": ""
		}]
		"config-autoscale.yaml": [{
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "config-autoscaler"
				namespace: "knative-serving"
			}
			data: {
				"scale-to-zero-grace-period": params.serverless.scaleToZeroGracePeriod
				"stable-window":              params.serverless.idleTimeout
			}
		}]
	}
}
