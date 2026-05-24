package docs

// mkdocs.cue — MkDocs params slice (site files also in infra/docker/cue/docs_gen.cue).

#MkdocsSiteParams: {
	siteName: string | *"Rice MASON Docs"
	theme:    string | *"material"
	nav:      [...string] | *["Home", "Architecture"]
}
