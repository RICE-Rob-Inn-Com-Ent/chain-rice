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
