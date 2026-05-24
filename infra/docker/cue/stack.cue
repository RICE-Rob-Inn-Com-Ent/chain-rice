package docker

import infra "github.com/rice-rob-inn-com-ent/rice/infra/proto/cue:infra"

#StackParams: infra.#StackParams
#ServerParams: infra.#ServerParams
#DocsParams:   infra.#DocsParams
#FrontendParams: infra.#FrontendParams

// Merge CHIEF docker.rice (dockerStack + server blocks) + docs.rice overlay.
stack: #StackParams & {
	ollama:  { enabled: bool | *false }
	vllm:    { enabled: bool | *false }
	postal:  { enabled: bool | *false }
	mailpit: { enabled: bool | *true }
	otp:     { enabled: bool | *false }
	rpc:     { enabled: bool | *false }
	agent:   { enabled: bool | *false }
	docs:    { enabled: bool | *false }
} & dockerStack & serverStackOverlay & docsStackOverlay
