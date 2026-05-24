//! Stack mirror — `custom/<slug>/` tree mirrors monorepo roles (base/, service/, function/, frontend/, infra/).

use std::fs;
use std::path::Path;

/// Relative paths under `custom/<slug>/` for CHIEF business + infra overlays.
pub const MIRROR_RICE_PATHS: &[&str] = &[
    "infra/docker.rice",
    "infra/k8s.rice",
    "infra/terraform.rice",
    "infra/docs.rice",
    "infra/proto.rice",
    "base/contract.rice",
    "base/calc.rice",
    "base/policies.rice",
    "base/security.rice",
    "base/private.rice",
    "service/auth.rice",
    "service/bench.rice",
    "service/connection.rice",
    "service/core.rice",
    "service/database.rice",
    "service/guard.rice",
    "service/messages.rice",
    "service/pipeline.rice",
    "service/queue.rice",
    "service/token.rice",
    "service/web.rice",
    "function/agent.rice",
    "function/job.rice",
    "function/simulation.rice",
    "function/vector.rice",
    "frontend/site.rice",
    "frontend/browser.rice",
    "frontend/client.rice",
    "frontend/content.rice",
    "frontend/inventory.rice",
    "frontend/lang.rice",
    "frontend/model.rice",
    "frontend/rule.rice",
    "frontend/vendor.rice",
    "frontend/video.rice",
    "frontend/audio.rice",
];

fn hook_name_from_path(rel: &str) -> String {
    rel.replace('/', "_").replace(".rice", "")
}

pub fn mirror_rice_body(slug: &str, rel: &str) -> String {
    let hook = hook_name_from_path(rel);
    if rel.starts_with("infra/") {
        let facet = rel.strip_prefix("infra/").unwrap().replace(".rice", "");
        return format!(
            r#"use infra as {facet}

// {slug} — CHIEF infra/{facet} (MASON + Mint on cook). Edit business settings below.
rc {facet} let {{
	profile set {{
		project = "{slug}"
	}}
}}
"#
        );
    }
    if rel == "frontend/site.rice" {
        let title = slug.replace('-', " ").replace('.', " ");
        return format!(
            r#"use infra as frontend

// {slug} — BARD site shell (Mint → frontend_project.cue on cook).
rc frontend let {{
	site set {{
		title = "{title}"
		api_base_url = "http://127.0.0.1:4000"
		seed_color = "0xFF2D6A4F"
	}}

	modules set {{
		client = true
		browser = true
		content = true
		lang = true
		rule = false
		model = false
	}}
}}
"#
        );
    }
    if rel.starts_with("frontend/") {
        let module = rel.strip_prefix("frontend/").unwrap().replace(".rice", "");
        return format!(
            r#"// {slug} — BARD frontend/{module} business overlay (extend site.rice modules).
rc frontend let {{
	{module} set {{
		enabled = true
	}}
}}

fn hook_{hook}_init {{}}
fn hook_{hook}_configure {{}}
"#
        );
    }
    if rel.starts_with("base/") {
        let facet = rel.strip_prefix("base/").unwrap().replace(".rice", "");
        return format!(
            r#"// {slug} — CLERK base/{facet} business hooks (Rice → Rust/Haskell/Zig at build).
rc clerk let {{
	{facet} set {{
		enabled = true
	}}
}}

fn hook_{facet}_init {{}}
fn hook_{facet}_configure {{}}
"#
        );
    }
    if rel.starts_with("service/") {
        let svc = rel.strip_prefix("service/").unwrap().replace(".rice", "");
        return format!(
            r#"// {slug} — SMITH service/{svc} business overlay.
rc smith let {{
	{svc} set {{
		enabled = true
	}}
}}

fn hook_{svc}_init {{}}
fn hook_{svc}_handler {{}}
"#
        );
    }
    if rel.starts_with("function/") {
        let facet = rel.strip_prefix("function/").unwrap().replace(".rice", "");
        return format!(
            r#"// {slug} — SAGE function/{facet} business overlay.
rc sage let {{
	{facet} set {{
		enabled = true
	}}
}}

fn hook_{facet}_run {{}}
fn hook_{facet}_configure {{}}
"#
        );
    }
    format!("// {slug} — {rel}\n")
}

/// Create missing or empty `.rice` mirror files; never overwrites non-empty files unless `force`.
pub fn scaffold_mirror_stack(
    project_dir: &Path,
    slug: &str,
    force: bool,
) -> Result<usize, String> {
    let mut written = 0usize;
    for rel in MIRROR_RICE_PATHS {
        let path = project_dir.join(rel);
        if path.exists() {
            if let Ok(meta) = fs::metadata(&path) {
                if meta.len() > 0 && !force {
                    continue;
                }
            }
        }
        let body = mirror_rice_body(slug, rel);
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .map_err(|e| format!("mkdir {}: {e}", parent.display()))?;
        }
        fs::write(&path, &body).map_err(|e| format!("write {}: {e}", path.display()))?;
        written += 1;
    }
    Ok(written)
}
