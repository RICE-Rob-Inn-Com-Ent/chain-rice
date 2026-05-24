package k8s

// Params-driven stack manifest generation (replaces per-vendor emit roll-up).

stackComponentGeneratedFiles: [string]: [string]: [...]
stackComponentGeneratedFiles: {
	for name in params.stack.enabled if name != "knative-bootstrap" && name != "helm-catalog" {
		let reg = _stackRegistry[name]
		let comp = params.stack.components[name]
		if comp.enabled {
			(name): {
				for fn in reg.files {
					(fn): [#stackStub & {
						_component:       name
						_targetNamespace: reg.namespace
						_fileName:        fn
						_note:            reg.note
						_replicaCount:    comp.replicaCount
						_cpuRequest:      comp.cpuRequest
						_memoryRequest:   comp.memoryRequest
						_memoryLimit:     comp.memoryLimit
					}]
				}
			}
		}
	}
}
