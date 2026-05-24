//! Server blocks (`otp`, `rpc`, `agent`, `docs`) inside CHIEF `docker.rice` → `server_project.cue`.

use std::collections::HashMap;

use crate::chief_rice_parse::{
    cue_quote, normalize_atom, optional_field, parse_bool, parse_u32_field,
};

#[derive(Debug, Clone)]
pub struct ServerServiceConfig {
    pub enabled: bool,
    pub port: u32,
    pub memory_limit: String,
}

#[derive(Debug, Clone, Default)]
pub struct ServerRiceConfig {
    pub otp: ServerServiceConfig,
    pub rpc: ServerServiceConfig,
    pub agent: ServerServiceConfig,
    pub docs: ServerServiceConfig,
}

impl Default for ServerServiceConfig {
    fn default() -> Self {
        Self {
            enabled: false,
            port: 0,
            memory_limit: "0".into(),
        }
    }
}

fn parse_service(block: &HashMap<String, String>, default_port: u32) -> Result<ServerServiceConfig, String> {
    let enabled = block
        .get("enabled")
        .map(|s| parse_bool(&normalize_atom(s)))
        .transpose()?
        .unwrap_or(true);
    Ok(ServerServiceConfig {
        enabled,
        port: parse_u32_field(block, "port", default_port)?,
        memory_limit: optional_field(block, "memory", "512M"),
    })
}

/// Parse `otp` / `rpc` / `agent` / `docs` `set { … }` blocks from `docker.rice` body.
pub fn parse_server_from_blocks(
    blocks: &HashMap<String, HashMap<String, String>>,
) -> Result<ServerRiceConfig, String> {
    let mut cfg = ServerRiceConfig::default();
    if let Some(b) = blocks.get("otp") {
        cfg.otp = parse_service(b, 4000)?;
    }
    if let Some(b) = blocks.get("rpc") {
        cfg.rpc = parse_service(b, 50051)?;
    }
    if let Some(b) = blocks.get("agent") {
        cfg.agent = parse_service(b, 8001)?;
    }
    if let Some(b) = blocks.get("docs") {
        cfg.docs = parse_service(b, 8080)?;
    }
    Ok(cfg)
}

pub fn validate_server_rice_profile(_slug: &str, cfg: &ServerRiceConfig) -> Vec<String> {
    let mut errs = Vec::new();
    if cfg.otp.enabled && cfg.otp.port == 0 {
        errs.push("otp set: port required when enabled".into());
    }
    errs
}

pub fn render_disabled_stub() -> String {
    r#"package docker

// Generated — no otp/rpc/agent/docs in docker.rice (server stack disabled)

serverProjectParams: #ServerParams & {
	otp:   { enabled: false, port: 4000, memoryLimit: "0" }
	rpc:   { enabled: false, port: 50051, memoryLimit: "0" }
	agent: { enabled: false, port: 8001, memoryLimit: "0" }
	docs:  { enabled: false, port: 8080, memoryLimit: "0" }
}

serverStackOverlay: {}
"#
    .to_string()
}

pub fn render_project_cue(cfg: &ServerRiceConfig) -> String {
    format!(
        r#"package docker

// Generated — mint_overlay_check --apply-docker (server blocks in docker.rice)

serverProjectParams: #ServerParams & {{
	otp:   {{ enabled: {otp_e}, port: {otp_p}, memoryLimit: {otp_m} }}
	rpc:   {{ enabled: {rpc_e}, port: {rpc_p}, memoryLimit: {rpc_m} }}
	agent: {{ enabled: {agent_e}, port: {agent_p}, memoryLimit: {agent_m} }}
	docs:  {{ enabled: {docs_e}, port: {docs_p}, memoryLimit: {docs_m} }}
}}

serverStackOverlay: {{
	otp:   {{ enabled: {otp_e} }}
	rpc:   {{ enabled: {rpc_e} }}
	agent: {{ enabled: {agent_e} }}
	docs:  {{ enabled: {docs_e} }}
}}
"#,
        otp_e = cfg.otp.enabled,
        otp_p = cfg.otp.port,
        otp_m = cue_quote(&cfg.otp.memory_limit),
        rpc_e = cfg.rpc.enabled,
        rpc_p = cfg.rpc.port,
        rpc_m = cue_quote(&cfg.rpc.memory_limit),
        agent_e = cfg.agent.enabled,
        agent_p = cfg.agent.port,
        agent_m = cue_quote(&cfg.agent.memory_limit),
        docs_e = cfg.docs.enabled,
        docs_p = cfg.docs.port,
        docs_m = cue_quote(&cfg.docs.memory_limit),
    )
}
