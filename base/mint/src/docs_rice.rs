//! Parse CHIEF `docs.rice` → `infra/gen/chief/docs_project.cue` + PlantUML files.

use std::path::Path;

use crate::chief_rice_parse::{cue_quote, extract_rc_let_body, normalize_atom, parse_name_tuple, parse_set_blocks};

#[derive(Debug, Clone)]
pub struct PlantumlDiagram {
    pub name: String,
    pub lines: Vec<String>,
}

#[derive(Debug, Clone, Default)]
pub struct DocsRiceConfig {
    pub site_url: String,
    pub mkdocs_site_name: String,
    pub mkdocs_theme: String,
    pub mkdocs_nav: Vec<String>,
    pub openapi_path: String,
    pub plantuml_theme: String,
    pub diagrams: Vec<PlantumlDiagram>,
}

pub fn parse_docs_rice(src: &str) -> Result<DocsRiceConfig, String> {
    let body = extract_rc_let_body(src, "rc docs let")?;
    let mut cfg = DocsRiceConfig::default();
    cfg.diagrams = parse_plantuml_diagrams(&body)?;
    cfg.site_url = "https://code-rice.com".into();
    cfg.mkdocs_site_name = "Docs".into();
    cfg.mkdocs_theme = "material".into();
    cfg.openapi_path = "api/openapi.yaml".into();
    cfg.plantuml_theme = "plain".into();

    for line in body.lines() {
        let t = line.trim();
        if t.is_empty() || t.starts_with("//") || t.starts_with('#') {
            continue;
        }
        if let Some(rest) = t.strip_prefix("site_url") {
            if let Some(v) = rest.strip_prefix('=') {
                cfg.site_url = normalize_atom(v.trim());
            }
            continue;
        }
        if let Some(rest) = t.strip_prefix("mkdocs") {
            let rest = rest.trim();
            if let Some(rest) = rest.strip_prefix("site_name") {
                if let Some(v) = rest.strip_prefix('=') {
                    cfg.mkdocs_site_name = normalize_atom(v.trim());
                }
            } else if let Some(rest) = rest.strip_prefix("theme") {
                if let Some(v) = rest.strip_prefix('=') {
                    cfg.mkdocs_theme = normalize_atom(v.trim());
                }
            } else if let Some(rest) = rest.strip_prefix("nav") {
                if let Some(v) = rest.strip_prefix('=') {
                    cfg.mkdocs_nav = parse_name_tuple(v.trim())?;
                }
            }
            continue;
        }
        if let Some(rest) = t.strip_prefix("openapi") {
            if let Some(rest) = rest.strip_prefix("path") {
                if let Some(v) = rest.strip_prefix('=') {
                    cfg.openapi_path = normalize_atom(v.trim());
                }
            }
            continue;
        }
        if let Some(rest) = t.strip_prefix("plantuml") {
            if rest.starts_with("theme") {
                if let Some(v) = rest.split('=').nth(1) {
                    cfg.plantuml_theme = normalize_atom(v.trim());
                }
            }
            continue;
        }
    }

    let blocks = parse_set_blocks(&body).ok();
    if let Some(blocks) = blocks {
        if let Some(m) = blocks.get("mkdocs") {
            if let Some(v) = m.get("site_name") {
                cfg.mkdocs_site_name = normalize_atom(v);
            }
            if let Some(v) = m.get("theme") {
                cfg.mkdocs_theme = normalize_atom(v);
            }
            if let Some(v) = m.get("nav") {
                cfg.mkdocs_nav = parse_name_tuple(v)?;
            }
        }
        if let Some(o) = blocks.get("openapi") {
            if let Some(v) = o.get("path") {
                cfg.openapi_path = normalize_atom(v);
            }
        }
    }

    Ok(cfg)
}

fn parse_plantuml_diagrams(body: &str) -> Result<Vec<PlantumlDiagram>, String> {
    let mut out = Vec::new();
    let marker = "plantuml diagram ";
    let mut search_from = 0;
    while let Some(pos) = body[search_from..].find(marker) {
        let start = search_from + pos;
        let rest = &body[start + marker.len()..];
        let name_end = rest
            .find('{')
            .ok_or("plantuml diagram: missing `{`")?;
        let name = rest[..name_end].trim().to_string();
        if name.is_empty() {
            return Err("plantuml diagram: empty name".into());
        }
        let inner = &rest[name_end + 1..];
        let mut depth = 1i32;
        let mut end = 0;
        for (i, ch) in inner.chars().enumerate() {
            if ch == '{' {
                depth += 1;
            } else if ch == '}' {
                depth -= 1;
                if depth == 0 {
                    end = i;
                    break;
                }
            }
        }
        if depth != 0 {
            return Err(format!("plantuml diagram `{name}`: unclosed `{{`"));
        }
        let block = &inner[..end];
        let mut lines = Vec::new();
        for line in block.lines() {
            let t = line.trim();
            if t.is_empty() {
                continue;
            }
            lines.push(plantuml_line_to_puml(t));
        }
        out.push(PlantumlDiagram { name, lines });
        search_from = start + marker.len() + name_end + 1 + end + 1;
    }
    Ok(out)
}

fn parse_plantuml_diagram_line(rest: &str) -> Option<PlantumlDiagram> {
    let rest = rest.strip_prefix("diagram")?.trim();
    let mut parts = rest.splitn(2, '{');
    let header = parts.next()?.trim();
    let body = parts.next()?;
    let name = header.split_whitespace().next()?.to_string();
    let mut lines = Vec::new();
    for line in body.lines() {
        let t = line.trim().trim_end_matches('}').trim();
        if t.is_empty() {
            continue;
        }
        lines.push(plantuml_line_to_puml(t));
    }
    Some(PlantumlDiagram { name, lines })
}

fn plantuml_line_to_puml(t: &str) -> String {
    if t.contains("-->") {
        let parts: Vec<&str> = t.split("-->").map(str::trim).collect();
        if parts.len() == 2 {
            return format!("{} --> {}", parts[0], parts[1]);
        }
    }
    if let Some(rest) = t.strip_prefix("component") {
        let rest = rest.trim();
        if let Some((id, label)) = rest.split_once(" as ") {
            let label = normalize_atom(label.trim());
            return format!("component \"{label}\" as {id}");
        }
        return format!("component {}", rest);
    }
    if let Some(rest) = t.strip_prefix("actor") {
        let rest = rest.trim();
        if let Some((id, label)) = rest.split_once(" as ") {
            let label = normalize_atom(label.trim());
            return format!("actor \"{label}\" as {id}");
        }
        return format!("actor {}", rest);
    }
    t.to_string()
}

pub fn render_plantuml(diagram: &PlantumlDiagram, theme: &str) -> String {
    let mut out = String::from("@startuml\n");
    out.push_str(&format!("!theme {}\n", theme));
    for line in &diagram.lines {
        out.push_str(line);
        out.push('\n');
    }
    out.push_str("@enduml\n");
    out
}

pub fn write_diagram_assets(repo_root: &Path, cfg: &DocsRiceConfig) -> Result<(), String> {
    let dir = repo_root.join("infra/gen/chief/docs");
    std::fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    for d in &cfg.diagrams {
        let puml = render_plantuml(d, &cfg.plantuml_theme);
        let path = dir.join(format!("{}.puml", d.name));
        std::fs::write(&path, puml).map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn render_disabled_stub() -> String {
    r#"package docker

docsProjectParams: #DocsParams & {
	siteUrl: "https://localhost"
	mkdocs: { siteName: "Docs", theme: "material", nav: ["Home"] }
	openapi: { path: "api/openapi.yaml" }
	plantuml: { theme: "plain", diagrams: [] }
}

docsStackOverlay: {}
"#
    .to_string()
}

pub fn render_project_cue(cfg: &DocsRiceConfig) -> String {
    let nav = if cfg.mkdocs_nav.is_empty() {
        "[\"Home\"]".to_string()
    } else {
        let items: Vec<String> = cfg
            .mkdocs_nav
            .iter()
            .map(|n| cue_quote(n))
            .collect();
        format!("[{}]", items.join(", "))
    };
    let mut diagrams_cue = String::from("[\n");
    for d in &cfg.diagrams {
        let content = d.lines.join("\n");
        diagrams_cue.push_str(&format!(
            "\t\t{{ name: {}, content: {} }},\n",
            cue_quote(&d.name),
            cue_quote(&content),
        ));
    }
    diagrams_cue.push_str("\t]");
    if cfg.diagrams.is_empty() {
        diagrams_cue = "[]".to_string();
    }

    format!(
        r#"package docker

// Generated — mint_overlay_check --apply-docs (CHIEF_PROJECT)

docsProjectParams: #DocsParams & {{
	siteUrl: {site}
	mkdocs: {{
		siteName: {mk_name}
		theme:    {mk_theme}
		nav:      {nav}
	}}
	openapi: {{
		path: {openapi}
	}}
	plantuml: {{
		theme:    {puml_theme}
		diagrams: {diagrams}
	}}
}}

docsStackOverlay: {{
	docs: {{ enabled: true }}
}}
"#,
        site = cue_quote(&cfg.site_url),
        mk_name = cue_quote(&cfg.mkdocs_site_name),
        mk_theme = cue_quote(&cfg.mkdocs_theme),
        nav = nav,
        openapi = cue_quote(&cfg.openapi_path),
        puml_theme = cue_quote(&cfg.plantuml_theme),
        diagrams = diagrams_cue,
    )
}
