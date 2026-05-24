package workspace

// Standalone MkDocs tree for product / partner docs (`docs-site/`) + CI template for apex publish.
emitFiles_mkdocs: [...]
emitFiles_mkdocs: [
	{
		path: "docs-site/mkdocs.yml"
		content: #"""
			site_name: Rice MASON docs (template)
			site_url: https://docs.example.invalid/
			site_description: Generated static site — point site_url at your docs apex (CNAME to hosting).
			repo_url: https://github.com/RICE-Rob-Inn-Com-Ent/rice
			theme:
			  name: material
			  palette:
			    - scheme: default
			      primary: indigo
			      toggle:
			        icon: material/brightness-7
			        name: Switch to dark mode
			    - scheme: slate
			      primary: indigo
			      toggle:
			        icon: material/brightness-4
			        name: Switch to light mode
			nav:
			  - Home: index.md
			plugins:
			  - search
			markdown_extensions:
			  - admonition
			  - pymdownx.superfences
			"""#
	},
	{
		path: "docs-site/docs/index.md"
		content: #"""
			# Docs site (MkDocs)

			This tree is emitted by MASON (`infra/out/cue/mkdocs_site.cue`). Override `site_url` in
			`docs-site/mkdocs.yml` after render, or extend CUE to read CHIEF `custom/EgOS/infra/docs.rice`.

			## Commands

			```bash
			pixi run mason-mkdocs-serve   # local
			pixi run mason-mkdocs-build  # static HTML under docs-site/site
			```

			## Publish

			Use `.github/workflows/docs-apex-publish.yml` as a template: build `site/`, then sync to
			your apex (`rsync`, S3, Cloudflare Pages, or GitHub Pages custom domain).
			"""#
	},
	{
		path: ".github/workflows/docs-apex-publish.yml"
		content: #"""
			# Template — wire secrets (e.g. RICE_DOCS_RSYNC_TARGET, SSH key) for your apex host.
			name: docs-apex-publish
			on:
			  workflow_dispatch: {}
			  push:
			    branches: [main]
			    paths:
			      - "docs-site/**"
			      - ".github/workflows/docs-apex-publish.yml"
			concurrency:
			  group: docs-apex
			  cancel-in-progress: true
			jobs:
			  build:
			    runs-on: ubuntu-latest
			    steps:
			      - uses: actions/checkout@v4
			      - uses: actions/setup-python@v5
			        with:
			          python-version: "3.12"
			      - name: Install MkDocs
			        run: pip install mkdocs-material
			      - name: Build static site
			        run: mkdocs build --strict -f docs-site/mkdocs.yml
			      - name: Upload artifact
			        uses: actions/upload-artifact@v4
			        with:
			          name: mkdocs-site
			          path: docs-site/site
			      - name: Publish placeholder
			        run: |
			          echo "Add a publish step: aws s3 sync, rsync, or cloudflare/pages-action with OIDC."
			"""#
	},
]
