package terraform

// pack.cue — params, paths, roll-up → .opentofu/

params: #TerraformParams & projectParams

paths: {
	opentofuRoot: ".opentofu"
}

_prefixed: [string]: string
_prefixed: {
	for path, body in rootStaticFiles {
		"\(paths.opentofuRoot)/\(path)": body
	}
}

_modulePrefixed: [string]: string
_modulePrefixed: {
	for path, body in moduleFiles {
		"\(paths.opentofuRoot)/\(path)": body
	}
}

_environmentPrefixed: [string]: string
_environmentPrefixed: {
	for path, body in environmentFiles {
		"\(paths.opentofuRoot)/\(path)": body
	}
}

_providerPrefixed: [string]: string
_providerPrefixed: {
	for path, body in providerFiles {
		"\(paths.opentofuRoot)/\(path)": body
	}
}

allFiles: [string]: string
allFiles: _prefixed & _modulePrefixed & _environmentPrefixed & _providerPrefixed & rootTfvarsFile
