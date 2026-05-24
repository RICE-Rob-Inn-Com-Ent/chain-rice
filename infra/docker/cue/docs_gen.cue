package docker

import "strings"

// docs_gen.cue — static docs site inputs for Dockerfile.docs (from #DocsParams).

_mkdocsYml: """
site_name: \(docs.mkdocs.siteName)
site_url: \(docs.siteUrl)
theme:
  name: \(docs.mkdocs.theme)
nav:
\(strings.Join([for n in docs.mkdocs.nav {"  - \(n)"}], "\n"))
"""

_docsIndex: """
# \(docs.mkdocs.siteName)

Generated documentation for **\(params.compose.projectName)**.

- OpenAPI: `\(docs.openapi.path)`
- PlantUML diagrams: `infra/gen/chief/docs/*.puml`

See [architecture](diagrams/architecture.puml) when present.
"""

_openapiStub: """
openapi: 3.1.0
info:
  title: \(docs.mkdocs.siteName) API
  version: "0.1.0"
paths: {}
"""

docsGenFiles: {
	if stack.docs.enabled {
		".docker/server/docs/mkdocs.yml":           _mkdocsYml
		".docker/server/docs/docs/index.md":      _docsIndex
		".docker/server/docs/docs/api/openapi.yaml": _openapiStub
	}
}
