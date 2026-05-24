//! CHIEF infra Rice validation for LSP and `mint_overlay_check`.

use std::collections::HashSet;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DiagnosticSeverity {
    Error,
    Warning,
}

#[derive(Debug, Clone)]
pub struct RiceDiagnostic {
    pub line: u32,
    pub col: u32,
    pub message: String,
    pub severity: DiagnosticSeverity,
}

impl RiceDiagnostic {
    pub fn error(line: u32, col: u32, message: impl Into<String>) -> Self {
        Self {
            line,
            col,
            message: message.into(),
            severity: DiagnosticSeverity::Error,
        }
    }

    pub fn error_at(message: impl Into<String>) -> Self {
        Self::error(0, 0, message)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChiefRiceKind {
    Bowl,
    Docker,
    K8s,
    Terraform,
    Docs,
    Frontend,
}

/// Classify CHIEF infra file from path.
pub fn classify_chief_path(path: &Path) -> Option<ChiefRiceKind> {
    let name = path.file_name()?.to_str()?;
    if name == "bowl" {
        return Some(ChiefRiceKind::Bowl);
    }
    if name.ends_with(".rice") {
        if path.parent()?.file_name()?.to_str()? == "infra" {
            return match name {
                "docker.rice" => Some(ChiefRiceKind::Docker),
                "k8s.rice" => Some(ChiefRiceKind::K8s),
                "terraform.rice" => Some(ChiefRiceKind::Terraform),
                "docs.rice" => Some(ChiefRiceKind::Docs),
                _ => None,
            };
        }
        if path.parent()?.file_name()?.to_str()? == "frontend" && name == "site.rice" {
            return Some(ChiefRiceKind::Frontend);
        }
    }
    None
}

/// Project slug from `custom/{slug}/...`.
pub fn chief_slug_from_path(path: &Path) -> Option<String> {
    let mut cur = path.parent()?;
    if path.file_name().and_then(|s| s.to_str()) == Some("site.rice") {
        if cur.file_name().and_then(|s| s.to_str()) != Some("frontend") {
            return None;
        }
        cur = cur.parent()?;
    } else if path.file_name().and_then(|s| s.to_str()) != Some("bowl") {
        if cur.file_name().and_then(|s| s.to_str()) != Some("infra") {
            return None;
        }
        cur = cur.parent()?;
    }
    if cur.parent()?.file_name().and_then(|s| s.to_str()) != Some("custom") {
        return None;
    }
    cur.file_name()
        .and_then(|s| s.to_str())
        .map(str::to_string)
}

fn chief_project_dir(path: &Path) -> PathBuf {
    if path.file_name().and_then(|s| s.to_str()) == Some("bowl") {
        path.parent().unwrap_or(path).to_path_buf()
    } else {
        path.parent()
            .and_then(|p| p.parent())
            .unwrap_or(path)
            .to_path_buf()
    }
}

fn validate_bowl_import(
    project_dir: &Path,
    facet: &str,
    diags: &mut Vec<RiceDiagnostic>,
) {
    let bowl_path = project_dir.join("bowl");
    let rice_name = match facet {
        crate::infra_rice::FACET_DOCKER => "docker.rice",
        crate::infra_rice::FACET_K8S => "k8s.rice",
        crate::infra_rice::FACET_TERRAFORM => "terraform.rice",
        crate::infra_rice::FACET_DOCS => "docs.rice",
        crate::infra_rice::FACET_FRONTEND => "site.rice",
        _ => return,
    };
    let rice_path = if facet == crate::infra_rice::FACET_FRONTEND {
        project_dir.join("frontend").join(rice_name)
    } else {
        project_dir.join("infra").join(rice_name)
    };
    let Ok(rice_src) = std::fs::read_to_string(&rice_path) else {
        return;
    };
    let Ok(import) = crate::infra_rice::parse_infra_use_line(&rice_src) else {
        return;
    };
    let Ok(bowl_src) = std::fs::read_to_string(&bowl_path) else {
        return;
    };
    let Ok(bowl_infra) = crate::infra_rice::parse_bowl_infra_package(&bowl_src) else {
        return;
    };
    if let Err(e) = crate::infra_rice::validate_infra_rice_import(&bowl_infra, &import, facet) {
        diags.push(RiceDiagnostic::error_at(e));
    }
}

/// Validate one CHIEF infra file.
pub fn validate_chief_rice(
    path: &Path,
    src: &str,
    allowed_tf: &HashSet<String>,
) -> Vec<RiceDiagnostic> {
    let Some(kind) = classify_chief_path(path) else {
        return Vec::new();
    };
    let slug = chief_slug_from_path(path).unwrap_or_default();
    let project_dir = chief_project_dir(path);

    match kind {
        ChiefRiceKind::Bowl => validate_bowl(src),
        ChiefRiceKind::Docker => {
            let mut diags = validate_facet_use(src, &project_dir, crate::infra_rice::FACET_DOCKER);
            match crate::docker_rice::parse_docker_rice(src) {
                Ok(cfg) => {
                    for e in crate::docker_rice::validate_docker_rice_profile(&slug, &cfg) {
                        diags.push(RiceDiagnostic::error_at(e));
                    }
                }
                Err(e) => diags.push(RiceDiagnostic::error_at(e)),
            }
            diags
        }
        ChiefRiceKind::K8s => {
            let mut diags = validate_facet_use(src, &project_dir, crate::infra_rice::FACET_K8S);
            match crate::k8s_rice::parse_k8s_rice(src) {
                Ok(cfg) => {
                    for e in crate::k8s_rice::validate_k8s_rice_profile(&slug, &cfg) {
                        diags.push(RiceDiagnostic::error_at(e));
                    }
                }
                Err(e) => diags.push(RiceDiagnostic::error_at(e)),
            }
            diags
        }
        ChiefRiceKind::Terraform => {
            let mut diags =
                validate_facet_use(src, &project_dir, crate::infra_rice::FACET_TERRAFORM);
            match crate::terraform_rice::parse_terraform_rice(src) {
                Ok(cfg) => {
                    let bindings = cfg.to_bindings();
                    for e in crate::overlay::validate_terraform_overlay(&bindings, allowed_tf) {
                        diags.push(RiceDiagnostic::error_at(e));
                    }
                }
                Err(e) => diags.push(RiceDiagnostic::error_at(e)),
            }
            diags
        }
        ChiefRiceKind::Docs => {
            let mut diags = validate_facet_use(src, &project_dir, crate::infra_rice::FACET_DOCS);
            if let Err(e) = crate::docs_rice::parse_docs_rice(src) {
                diags.push(RiceDiagnostic::error_at(e));
            }
            diags
        }
        ChiefRiceKind::Frontend => {
            let mut diags =
                validate_facet_use(src, &project_dir, crate::infra_rice::FACET_FRONTEND);
            if let Err(e) = crate::frontend_rice::parse_frontend_rice(src) {
                diags.push(RiceDiagnostic::error_at(e));
            }
            diags
        }
    }
}

fn validate_facet_use(
    src: &str,
    project_dir: &Path,
    facet: &str,
) -> Vec<RiceDiagnostic> {
    let mut diags = Vec::new();
    if let Err(e) = crate::infra_rice::parse_infra_use_line(src) {
        diags.push(RiceDiagnostic::error_at(e));
        return diags;
    }
    validate_bowl_import(project_dir, facet, &mut diags);
    diags
}

fn validate_bowl(src: &str) -> Vec<RiceDiagnostic> {
    let mut diags = Vec::new();
    if let Err(e) = crate::overlay::parse_bowl_name(src) {
        diags.push(RiceDiagnostic::error_at(format!("bowl: {e}")));
    }
    if let Err(e) = crate::infra_rice::parse_bowl_infra_package(src) {
        diags.push(RiceDiagnostic::error_at(e));
    }
    diags
}

/// Validate CHIEF projects under `custom/` (only `CHIEF_PROJECT` when set).
pub fn validate_custom_tree(
    root: &Path,
    allowed_tf: &HashSet<String>,
) -> Vec<(PathBuf, Vec<RiceDiagnostic>)> {
    let mut out = Vec::new();
    let custom = root.join("custom");
    let Ok(entries) = std::fs::read_dir(&custom) else {
        return out;
    };
    let active = std::env::var("CHIEF_PROJECT")
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty());
    for ent in entries.flatten() {
        let p = ent.path();
        if !p.is_dir() {
            continue;
        }
        if let Some(ref slug) = active {
            if p.file_name().and_then(|s| s.to_str()) != Some(slug.as_str()) {
                continue;
            }
        }
        for rel in [
            "bowl",
            "infra/docker.rice",
            "infra/k8s.rice",
            "infra/terraform.rice",
            "infra/docs.rice",
            "frontend/site.rice",
        ] {
            let f = p.join(rel);
            if !f.is_file() {
                continue;
            }
            let Ok(src) = std::fs::read_to_string(&f) else {
                continue;
            };
            let diags = validate_chief_rice(&f, &src, allowed_tf);
            if !diags.is_empty() {
                out.push((f, diags));
            }
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fixture_root() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../../custom")
    }

    #[test]
    fn classify_terraform_rice() {
        let p = fixture_root().join("code-rice.com/infra/terraform.rice");
        assert_eq!(
            classify_chief_path(&p),
            Some(ChiefRiceKind::Terraform)
        );
    }

    #[test]
    fn validate_code_rice_terraform_ok() {
        let p = fixture_root().join("code-rice.com/infra/terraform.rice");
        let src = std::fs::read_to_string(&p).unwrap();
        let allowed: HashSet<String> = crate::overlay::terraform_rice_variable_names()
            .into_iter()
            .collect();
        let diags = validate_chief_rice(&p, &src, &allowed);
        assert!(diags.is_empty(), "{diags:?}");
    }
}
