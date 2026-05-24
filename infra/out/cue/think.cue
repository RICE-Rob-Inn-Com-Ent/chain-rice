package workspace

// Dev model pull policy for rice think (referenced by pour/think scripts).
thinkPolicy: {
	roles: [...string] | *["SAGE", "CLERK", "BARD", "KING"]
	ggufRoot: string | *".rice/models"
	loraRoot: string | *".rice/lora"
	ragBackend: string | *"sqlite"
	pullOnMissing: bool | *true
}
