//! MASON workspace paths — Mint bridges CHIEF `custom/*/infra` to generated infra (see [`crate::overlay`] for `let rice_*` validation).

/// Generated cluster stack + helm catalog.
pub const K8S_STACK_ROOT: &str = ".k8s/stack";
/// OpenTofu root emitted from `infra/terraform/cue`.
pub const OPENTOFU_ROOT: &str = ".opentofu";
/// Buf module for `rice/v1` protos.
pub const INFRA_SCHEMAS: &str = "infra/schemas";
/// CHIEF infra overlays live under `custom/<project>/infra/`.
pub const CUSTOM_INFRA_GLOB: &str = "custom/*/infra";
