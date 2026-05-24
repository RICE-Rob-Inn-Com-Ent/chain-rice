//! Parse CHIEF `frontend/site.rice` → `frontend_project.cue` + `lib/generated/rice_config.dart`.

use std::collections::HashMap;
use std::path::Path;

use crate::chief_rice_parse::{
    cue_quote, extract_rc_let_body, normalize_atom, parse_bool, parse_set_blocks,
};

#[derive(Debug, Clone, Default)]
pub struct FrontendRiceConfig {
    pub site_title: String,
    pub api_base_url: String,
    pub seed_color: String,
    pub client: bool,
    pub browser: bool,
    pub content: bool,
    pub lang: bool,
    pub rule: bool,
    pub model: bool,
}

pub fn parse_frontend_rice(src: &str) -> Result<FrontendRiceConfig, String> {
    let body = extract_rc_let_body(src, "rc frontend let")?;
    let blocks = parse_set_blocks(&body)?;
    let mut cfg = FrontendRiceConfig::default();
    cfg.site_title = ".rice".into();
    cfg.api_base_url = "http://127.0.0.1:4000".into();
    cfg.seed_color = "0xFF2D6A4F".into();
    cfg.client = true;
    cfg.browser = true;
    cfg.content = true;
    cfg.lang = true;

    if let Some(s) = blocks.get("site") {
        if let Some(v) = s.get("title") {
            cfg.site_title = normalize_atom(v);
        }
        if let Some(v) = s.get("api_base_url") {
            cfg.api_base_url = normalize_atom(v);
        }
        if let Some(v) = s.get("seed_color") {
            cfg.seed_color = normalize_atom(v);
        }
    }

    if let Some(m) = blocks.get("modules") {
        cfg.client = parse_module_flag(m, "client", true)?;
        cfg.browser = parse_module_flag(m, "browser", true)?;
        cfg.content = parse_module_flag(m, "content", true)?;
        cfg.lang = parse_module_flag(m, "lang", true)?;
        cfg.rule = parse_module_flag(m, "rule", false)?;
        cfg.model = parse_module_flag(m, "model", false)?;
    }

    Ok(cfg)
}

fn parse_module_flag(
    m: &HashMap<String, String>,
    key: &str,
    default: bool,
) -> Result<bool, String> {
    match m.get(key) {
        None => Ok(default),
        Some(v) => parse_bool(&normalize_atom(v)),
    }
}

pub fn render_disabled_stub() -> String {
    r#"package docker

frontendProjectParams: #FrontendParams & {
	siteTitle:  ".rice"
	apiBaseUrl: "http://127.0.0.1:4000"
	seedColor:  "0xFF2D6A4F"
	modules: { client: true, browser: false, content: false, lang: false, rule: false, model: false }
}
"#
    .to_string()
}

pub fn render_project_cue(cfg: &FrontendRiceConfig) -> String {
    format!(
        r#"package docker

// Generated — mint_overlay_check --apply-frontend (CHIEF_PROJECT)

frontendProjectParams: #FrontendParams & {{
	siteTitle:  {title}
	apiBaseUrl: {api}
	seedColor:  {color}
	modules: {{
		client:  {client}
		browser: {browser}
		content: {content}
		lang:    {lang}
		rule:    {rule}
		model:   {model}
	}}
}}
"#,
        title = cue_quote(&cfg.site_title),
        api = cue_quote(&cfg.api_base_url),
        color = cue_quote(&cfg.seed_color),
        client = cfg.client,
        browser = cfg.browser,
        content = cfg.content,
        lang = cfg.lang,
        rule = cfg.rule,
        model = cfg.model,
    )
}

pub fn render_dart_config(cfg: &FrontendRiceConfig) -> String {
    format!(
        r#"// Generated — mint_overlay_check --apply-frontend. Do not edit.

class RiceSiteConfig {{
  static const String siteTitle = {title};
  static const String apiBaseUrl = {api};
  static const int seedColor = {color};
  static const bool moduleClient = {client};
  static const bool moduleBrowser = {browser};
  static const bool moduleContent = {content};
  static const bool moduleLang = {lang};
  static const bool moduleRule = {rule};
  static const bool moduleModel = {model};
}}
"#,
        title = cue_quote(&cfg.site_title),
        api = cue_quote(&cfg.api_base_url),
        color = cfg.seed_color,
        client = cfg.client,
        browser = cfg.browser,
        content = cfg.content,
        lang = cfg.lang,
        rule = cfg.rule,
        model = cfg.model,
    )
}

pub fn write_dart_config(project_dir: &Path, cfg: &FrontendRiceConfig) -> Result<(), String> {
    let gen_dir = project_dir.join("frontend/lib/generated");
    std::fs::create_dir_all(&gen_dir).map_err(|e| e.to_string())?;
    let path = gen_dir.join("rice_config.dart");
    std::fs::write(&path, render_dart_config(cfg)).map_err(|e| e.to_string())?;
    Ok(())
}
