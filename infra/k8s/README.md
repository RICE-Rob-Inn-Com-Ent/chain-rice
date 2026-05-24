# MASON Kubernetes (`infra/k8s`)

CUE generates GitOps manifests under `.k8s/` from **MASON skeleton** + **CHIEF** `bowl` + `infra/k8s.rice`.

CHIEF contract: `bowl` `[package] infra = ""` → `use infra as k8s` → `rc k8s let { … }` (schema: `infra/proto/cue/infra.cue`).

## Layout

| File | Role |
|------|------|
| [`_tool.cue`](_tool.cue) | `cue cmd genK8s` (writes `.k8s/`) |
| [`cue/pack.cue`](cue/pack.cue) | Output **paths** + `allGeneratedFiles` roll-up |
| [`cue/defaults.cue`](cue/defaults.cue) | `_masonDefaults`, stack catalog, `params` merge |
| [`cue/schema.cue`](cue/schema.cue) | Re-export `infra.#K8sParams` |
| [`../proto/cue/infra.cue`](../proto/cue/infra.cue) | Mint/Rice schema (`package infra`) |
| `cue/stack/registry.cue` | Taxonomy A–H component registry |
| `cue/stack/generate.cue` | Params-driven stack ConfigMaps + Helm values |

## Generate

```bash
export CHIEF_PROJECT=egos.app   # or code-rice.com
cargo +nightly run --manifest-path base/Cargo.toml -p mint --bin mint_overlay_check -- --apply-k8s
shopt -s globstar nullglob
files=(./infra/k8s/_tool.cue ./infra/k8s/cue/**/*.cue ./infra/gen/chief/k8s_project.cue)
cue vet "${files[@]}"
cue cmd genK8s "${files[@]}"
```

Or: `cue cmd gen ./infra/_tool.cue` (docker + k8s + folder sync).

Unset fields in `k8s.rice` fall back to MASON `_masonDefaults` / Mint defaults.

## Taxonomy coverage matrix

| Component | Tier | Generated under | Deploy method | CHIEF params |
|-----------|------|-----------------|---------------|--------------|
| argocd | A | `.k8s/stack/argocd/` | Helm values in ConfigMap | `stack.components.argocd`, `helm.versions.argocd` |
| dagger | A | `.k8s/stack/dagger/` | Helm values | `stack.enabled` |
| crossplane | A | `.k8s/stack/crossplane/` | Helm values | `stack.enabled` |
| velero | A | `.k8s/stack/velero/` | Helm values | `stack.enabled` |
| cilium | B | `.k8s/stack/cilium/` | Helm values | `stack.components.cilium` |
| gateway | B | `.k8s/stack/gateway/` | Helm / Gateway API | `stack.enabled` |
| karpenter | C | `.k8s/stack/karpenter/` | OCI Helm | `helm.versions.karpenter` |
