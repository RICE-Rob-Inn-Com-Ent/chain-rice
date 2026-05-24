package docs

// Roll-up for cue cmd genDocs (chief docs assets under infra/gen/chief/docs/).
docsTemplateFiles: [string]: string

docsTemplateFiles: {
	for name in plantumlParams.diagrams {
		"infra/gen/chief/docs/\(name).puml": """
			@startuml
			title \(name) — MASON docs
			note right: CHIEF cook fills via Mint
			@enduml
			"""
	}
}

plantumlParams: #PlantUMLParams & {diagrams: ["architecture"]}
mkdocsParams:   #MkdocsSiteParams
openapiParams:  #OpenAPIParams

allFiles: docsTemplateFiles
