//! Parse CHIEF `k8s.rice` → `infra/gen/chief/k8s_project.cue` (schema: `infra/proto/cue/infra.cue`).

use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct K8sBotRole {
    pub mem_request: String,
    pub mem_limit: String,
    pub cpu_request: String,
    pub cpu_limit: String,
    pub concurrency: u32,
    pub target_util_pct: String,
    pub scale_max: String,
    pub timeout_seconds: u32,
    pub port: u32,
}

impl Default for K8sBotRole {
    fn default() -> Self {
        Self {
            mem_request: "256Mi".into(),
            mem_limit: "1Gi".into(),
            cpu_request: "100m".into(),
            cpu_limit: "1000m".into(),
            concurrency: 80,
            target_util_pct: "80".into(),
            scale_max: "10".into(),
            timeout_seconds: 300,
            port: 8080,
        }
    }
}

#[derive(Debug, Clone)]
pub struct ObsConfig {
    pub profile: String,
    pub tempo_enabled: bool,
    pub otel_enabled: bool,
}

pub struct PolicyConfig {
    pub kyverno_digest_required: bool,
}

pub struct K8sRiceConfig {
    pub profile: String,
    pub gitops: GitopsConfig,
    pub helm_versions: HashMap<String, String>,
    pub gpu: GpuConfig,
    pub bots: BotsConfig,
    pub cluster_slices: Vec<String>,
    pub obs: ObsConfig,
    pub policy: PolicyConfig,
}

#[derive(Debug, Clone)]
pub struct GitopsConfig {
    pub repo_url: String,
    pub target_revision: String,
    pub cluster_server: String,
    pub argocd_namespace: String,
    pub root_app_name: String,
}

#[derive(Debug, Clone)]
pub struct GpuConfig {
    pub enabled: bool,
    pub namespace: String,
    pub operator_chart_version: String,
    pub mig_strategy: String,
    pub time_slice_replicas: String,
    pub dcgm_exporter_version: String,
}

#[derive(Debug, Clone)]
pub struct BotsConfig {
    pub image_registry: String,
    pub image_org: String,
    pub image_tag: String,
    pub namespace: String,
    pub roles: HashMap<String, K8sBotRole>,
}

const DEFAULT_HELM: &[(&str, &str)] = &[
    ("argocd", "6.7.14"),
    ("dagger", "0.18.0"),
    ("crossplane", "1.16.0"),
    ("velero", "8.0.0"),
    ("cilium", "1.16.1"),
    ("gateway", "1.1.0"),
    ("karpenter", "1.0.6"),
    ("external-secrets", "0.10.5"),
    ("kyverno", "3.2.6"),
    ("falco", "4.11.0"),
    ("harbor", "1.15.0"),
    ("cert-manager", "v1.15.0"),
    ("keda", "2.14.0"),
    ("knative", "1.22.0"),
    ("knative-bootstrap", "1.22.0"),
    ("alertmanager", "1.11.0"),
    ("grafana", "8.5.0"),
    ("loki", "6.6.0"),
    ("tempo", "1.10.0"),
    ("victoria-metrics", "0.14.0"),
    ("otel-operator", "0.62.0"),
];

const DEFAULT_BOT_NAMES: &[&str] = &[
    "king", "mason", "chief", "clerk", "bard", "sage", "smith",
];

pub fn parse_k8s_rice(src: &str) -> Result<K8sRiceConfig, String> {
    let body = extract_let_body(src)?;
    let blocks = parse_set_blocks(&body)?;

    let profile = blocks
        .get("profile")
        .map(|p| optional_field(p, "name", "local"))
        .unwrap_or_else(|| "local".into());

    let git = blocks
        .get("gitops")
        .ok_or("missing required block: gitops set { ... }")?;
    let gitops = GitopsConfig {
        repo_url: require_field(git, "repo_url")?,
        target_revision: optional_field(git, "target_revision", "HEAD"),
        cluster_server: optional_field(
            git,
            "cluster_server",
            "https://kubernetes.default.svc",
        ),
        argocd_namespace: optional_field(git, "argocd_namespace", "argocd"),
        root_app_name: optional_field(git, "root_app_name", "gitops-root"),
    };

    let mut helm_versions: HashMap<String, String> = DEFAULT_HELM
        .iter()
        .map(|(k, v)| (k.to_string(), v.to_string()))
        .collect();
    if let Some(helm) = blocks.get("helm") {
        for (key, val) in helm {
            if let Some((chart, field)) = key.split_once('.') {
                if field == "version" {
                    helm_versions.insert(chart.to_string(), normalize_atom(val));
                }
            }
        }
    }

    let gpu = if let Some(g) = blocks.get("gpu") {
        GpuConfig {
            enabled: parse_bool(&optional_field(g, "enabled", "true"))?,
            namespace: optional_field(g, "namespace", "gpu-system"),
            operator_chart_version: optional_field(g, "operator_chart_version", "v24.9.1"),
            mig_strategy: optional_field(g, "mig_strategy", "single"),
            time_slice_replicas: optional_field(g, "time_slice_replicas", "4"),
            dcgm_exporter_version: optional_field(
                g,
                "dcgm_exporter_version",
                "3.3.6-3.4.0-ubuntu22.04",
            ),
        }
    } else {
        GpuConfig {
            enabled: true,
            namespace: "gpu-system".into(),
            operator_chart_version: "v24.9.1".into(),
            mig_strategy: "single".into(),
            time_slice_replicas: "4".into(),
            dcgm_exporter_version: "3.3.6-3.4.0-ubuntu22.04".into(),
        }
    };

    let bots_block = blocks
        .get("bots")
        .ok_or("missing required block: bots set { ... }")?;
    let mut roles: HashMap<String, K8sBotRole> = HashMap::new();
    if let Some(raw) = bots_block.get("roles") {
        for name in parse_name_tuple(raw)? {
            roles.insert(name.clone(), K8sBotRole::default());
        }
    } else {
        for name in DEFAULT_BOT_NAMES {
            roles.insert((*name).to_string(), K8sBotRole::default());
        }
    }
    apply_bot_overrides(&mut roles, bots_block);
    apply_heavy_bot_defaults(&mut roles);

    let bots = BotsConfig {
        image_registry: optional_field(bots_block, "image_registry", "ghcr.io"),
        image_org: require_field(bots_block, "image_org")?,
        image_tag: require_field(bots_block, "image_tag")?,
        namespace: optional_field(bots_block, "namespace", "bots"),
        roles,
    };

    let cluster_slices = if let Some(c) = blocks.get("cluster") {
        c.get("slices")
            .map(|raw| parse_name_tuple(raw))
            .transpose()?
            .ok_or("cluster set: missing slices = (...)")?
    } else {
        vec![
            "platform".into(),
            "gpu".into(),
            "knative".into(),
            "data".into(),
            "workflow".into(),
            "bots".into(),
            "obs".into(),
        ]
    };

    if gpu.enabled == false {
        // slices list is authoritative; gpu.enabled is metadata for CHIEF docs
    }

    let obs = if let Some(o) = blocks.get("obs") {
        ObsConfig {
            profile: optional_field(o, "profile", "standard"),
            tempo_enabled: o
                .get("tempo.enabled")
                .map(|v| parse_bool(&normalize_atom(v)))
                .transpose()?
                .unwrap_or(profile == "prod"),
            otel_enabled: o
                .get("otelOperator.enabled")
                .map(|v| parse_bool(&normalize_atom(v)))
                .transpose()?
                .unwrap_or(profile == "prod"),
        }
    } else {
        ObsConfig {
            profile: if profile == "prod" {
                "full".into()
            } else {
                "standard".into()
            },
            tempo_enabled: profile == "prod",
            otel_enabled: profile == "prod",
        }
    };

    let policy = if let Some(p) = blocks.get("policy") {
        PolicyConfig {
            kyverno_digest_required: parse_bool(&optional_field(
                p,
                "kyverno_digest_required",
                "false",
            ))?,
        }
    } else {
        PolicyConfig {
            kyverno_digest_required: profile == "prod",
        }
    };

    Ok(K8sRiceConfig {
        profile,
        gitops,
        helm_versions,
        gpu,
        bots,
        cluster_slices,
        obs,
        policy,
    })
}

fn apply_heavy_bot_defaults(roles: &mut HashMap<String, K8sBotRole>) {
    for name in ["sage", "smith"] {
        if let Some(r) = roles.get_mut(name) {
            if r.mem_request == "256Mi" {
                r.mem_request = "512Mi".into();
            }
            if r.mem_limit == "1Gi" {
                r.mem_limit = "2Gi".into();
            }
            if r.cpu_request == "100m" {
                r.cpu_request = "200m".into();
            }
            if r.cpu_limit == "1000m" {
                r.cpu_limit = "2000m".into();
            }
            if r.concurrency == 80 {
                r.concurrency = 40;
            }
        }
    }
}

fn apply_bot_overrides(roles: &mut HashMap<String, K8sBotRole>, bots: &HashMap<String, String>) {
    for (key, val) in bots {
        let Some((role, field)) = key.split_once('.') else {
            continue;
        };
        if !roles.contains_key(role) {
            roles.insert(role.to_string(), K8sBotRole::default());
        }
        let entry = roles.get_mut(role).unwrap();
        let v = normalize_atom(val);
        match field {
            "mem_request" => entry.mem_request = v,
            "mem_limit" => entry.mem_limit = v,
            "cpu_request" => entry.cpu_request = v,
            "cpu_limit" => entry.cpu_limit = v,
            "concurrency" => {
                if let Ok(n) = v.parse() {
                    entry.concurrency = n;
                }
            }
            "target_util_pct" => entry.target_util_pct = v,
            "scale_max" => entry.scale_max = v,
            "timeout_seconds" => {
                if let Ok(n) = v.parse() {
                    entry.timeout_seconds = n;
                }
            }
            "port" => {
                if let Ok(n) = v.parse() {
                    entry.port = n;
                }
            }
            _ => {}
        }
    }
}

pub fn validate_k8s_rice_profile(slug: &str, cfg: &K8sRiceConfig) -> Vec<String> {
    let mut errs = Vec::new();
    if slug == "egos.app" && cfg.profile != "local" {
        errs.push(format!(
            "egos.app: expected profile local, got {:?}",
            cfg.profile
        ));
    }
    if slug == "code-rice.com" && cfg.profile != "prod" {
        errs.push(format!(
            "code-rice.com: expected profile prod, got {:?}",
            cfg.profile
        ));
    }
    if cfg.bots.roles.is_empty() {
        errs.push("bots.roles must not be empty".into());
    }
    if cfg.cluster_slices.is_empty() {
        errs.push("cluster.slices must not be empty".into());
    }
    errs
}

fn stack_enabled_list(profile: &str) -> Vec<String> {
    if profile == "local" {
        vec![
            "argocd", "cilium", "external-secrets", "kyverno", "cert-manager", "knative-bootstrap",
            "helm-catalog", "grafana", "loki", "victoria-metrics", "alertmanager",
        ]
        .into_iter()
        .map(String::from)
        .collect()
    } else {
        vec![
            "argocd", "dagger", "crossplane", "velero", "cilium", "gateway", "karpenter",
            "external-secrets", "kyverno", "falco", "harbor", "cert-manager", "keda", "knative",
            "knative-bootstrap", "alertmanager", "grafana", "loki", "tempo", "victoria-metrics",
            "otel-operator", "helm-catalog",
        ]
        .into_iter()
        .map(String::from)
        .collect()
    }
}

pub fn render_project_cue(_project_name: &str, cfg: &K8sRiceConfig) -> String {
    let helm_versions = render_helm_versions(&cfg.helm_versions);
    let roles = render_bot_roles(&cfg.bots.roles);
    let slices = render_string_list(&cfg.cluster_slices);
    let stack_enabled = render_string_list(&stack_enabled_list(&cfg.profile));
    let obs_profile = cfg.obs.profile.as_str();
    let tempo_enabled = cfg.obs.tempo_enabled;
    let otel_enabled = cfg.obs.otel_enabled;
    let policy_digest = cfg.policy.kyverno_digest_required;

    format!(
        r#"package k8s

// Generated — mint_overlay_check --apply-k8s (CHIEF_PROJECT)
// Edit custom/*/bowl + custom/*/infra/k8s.rice. Schema: infra/proto/cue/infra.cue

projectParams: {{
	profile: {{
		name: {profile}
	}}

	gitops: {{
		repoURL:         {repo_url}
		targetRevision:  {target_revision}
		clusterServer:   {cluster_server}
		argocdNamespace: {argocd_ns}
		rootAppName:     {root_app}
	}}

	helm: {{
		versions: {helm_versions}
	}}

	stack: {{
		enabled: {stack_enabled}
	}}

	serverless: {{
		minScale:               0
		scaleToZeroGracePeriod: "30s"
		idleTimeout:            "60s"
	}}

	gpu: {{
		enabled:              {gpu_enabled}
		namespace:            {gpu_ns}
		operatorChartVersion: {gpu_op}
		migStrategy:          {gpu_mig}
		timeSliceReplicas:    {gpu_ts}
		dcgmExporterVersion:  {gpu_dcgm}
	}}

	bots: {{
		imageRegistry: {img_reg}
		imageOrg:      {img_org}
		imageTag:      {img_tag}
		namespace:     {bots_ns}
		roles:         {roles}
	}}

	obs: {{
		profile: {obs_profile}
		tempo: {{ enabled: {tempo_enabled} }}
		otelOperator: {{ enabled: {otel_enabled} }}
	}}

	policy: {{
		kyvernoDigestRequired: {policy_digest}
	}}

	data: {{
		namespace: "data"
		nats: {{ enabled: true, memory: "1Gi", chartVersion: "1.2.6" }}
		qdrant: {{ enabled: true, memory: "2Gi", chartVersion: "1.11.0" }}
		yugabyte: {{ enabled: true, memory: "4Gi", chartVersion: "2.25.0" }}
		ray: {{ enabled: false, chartVersion: "1.1.0" }}
	}}

	cluster: {{
		slices: {slices}
	}}
}}
"#,
        profile = cue_quote(&cfg.profile),
        repo_url = cue_quote(&cfg.gitops.repo_url),
        target_revision = cue_quote(&cfg.gitops.target_revision),
        cluster_server = cue_quote(&cfg.gitops.cluster_server),
        argocd_ns = cue_quote(&cfg.gitops.argocd_namespace),
        root_app = cue_quote(&cfg.gitops.root_app_name),
        helm_versions = helm_versions,
        gpu_enabled = cfg.gpu.enabled,
        gpu_ns = cue_quote(&cfg.gpu.namespace),
        gpu_op = cue_quote(&cfg.gpu.operator_chart_version),
        gpu_mig = cue_quote(&cfg.gpu.mig_strategy),
        gpu_ts = cue_quote(&cfg.gpu.time_slice_replicas),
        gpu_dcgm = cue_quote(&cfg.gpu.dcgm_exporter_version),
        img_reg = cue_quote(&cfg.bots.image_registry),
        img_org = cue_quote(&cfg.bots.image_org),
        img_tag = cue_quote(&cfg.bots.image_tag),
        bots_ns = cue_quote(&cfg.bots.namespace),
        roles = roles,
        slices = slices,
        stack_enabled = stack_enabled,
        obs_profile = cue_quote(obs_profile),
        tempo_enabled = tempo_enabled,
        otel_enabled = otel_enabled,
        policy_digest = policy_digest,
    )
}

fn cue_field_key(k: &str) -> String {
    if k.chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '_')
    {
        k.to_string()
    } else {
        cue_quote(k)
    }
}

fn render_helm_versions(versions: &HashMap<String, String>) -> String {
    let mut keys: Vec<_> = versions.keys().collect();
    keys.sort();
    let mut lines = vec!["{".to_string()];
    for k in keys {
        lines.push(format!(
            "\t\t\t{}: {},",
            cue_field_key(k),
            cue_quote(versions.get(k.as_str()).unwrap())
        ));
    }
    lines.push("\t\t}".to_string());
    lines.join("\n")
}

fn render_bot_roles(roles: &HashMap<String, K8sBotRole>) -> String {
    let mut keys: Vec<_> = roles.keys().collect();
    keys.sort();
    let mut lines = vec!["[".to_string()];
    for role in keys {
        let r = &roles[role.as_str()];
        lines.push(format!(
            "\t\t\t{{
\t\t\t\tname:           {}
\t\t\t\tmemRequest:     {}
\t\t\t\tmemLimit:       {}
\t\t\t\tcpuRequest:     {}
\t\t\t\tcpuLimit:       {}
\t\t\t\tconcurrency:    {}
\t\t\t\ttargetUtilPct:  {}
\t\t\t\tscaleMax:       {}
\t\t\t\ttimeoutSeconds: {}
\t\t\t\tport:           {}
\t\t\t}},",
            cue_quote(role),
            cue_quote(&r.mem_request),
            cue_quote(&r.mem_limit),
            cue_quote(&r.cpu_request),
            cue_quote(&r.cpu_limit),
            r.concurrency,
            cue_quote(&r.target_util_pct),
            cue_quote(&r.scale_max),
            r.timeout_seconds,
            r.port,
        ));
    }
    lines.push("\t\t]".to_string());
    lines.join("\n")
}

fn render_string_list(items: &[String]) -> String {
    if items.is_empty() {
        return "[]".to_string();
    }
    let items: Vec<String> = items.iter().map(|l| cue_quote(l)).collect();
    format!("[\n\t\t\t{},\n\t\t]", items.join(",\n\t\t\t"))
}

fn cue_quote(s: &str) -> String {
    format!("{:?}", s)
}

fn parse_name_tuple(raw: &str) -> Result<Vec<String>, String> {
    let raw = raw.trim();
    let inner = raw
        .strip_prefix('(')
        .and_then(|s| s.strip_suffix(')'))
        .ok_or("expected tuple: (a, b, ...)")?;
    Ok(split_top_level_commas(inner)
        .into_iter()
        .map(|s| normalize_atom(&s))
        .filter(|s| !s.is_empty())
        .collect())
}

fn optional_field(map: &HashMap<String, String>, key: &str, default: &str) -> String {
    map.get(key)
        .map(|s| normalize_atom(s))
        .unwrap_or_else(|| default.to_string())
}

fn require_field(map: &HashMap<String, String>, key: &str) -> Result<String, String> {
    map.get(key)
        .map(|s| normalize_atom(s))
        .ok_or_else(|| format!("missing field `{key}`"))
}

fn parse_bool(s: &str) -> Result<bool, String> {
    match s.trim().to_lowercase().as_str() {
        "true" | "1" | "yes" => Ok(true),
        "false" | "0" | "no" => Ok(false),
        _ => Err(format!("expected boolean, got {s:?}")),
    }
}

fn normalize_atom(s: &str) -> String {
    let s = s.trim().trim_end_matches(',');
    if (s.starts_with('"') && s.ends_with('"')) || (s.starts_with('\'') && s.ends_with('\'')) {
        s[1..s.len() - 1].to_string()
    } else {
        s.to_string()
    }
}

fn extract_let_body(src: &str) -> Result<String, String> {
    let mut in_let = false;
    let mut depth = 0i32;
    let mut body = String::new();
    for line in src.lines() {
        let t = line.trim();
        if t.is_empty() || t.starts_with("//") {
            continue;
        }
        if !in_let {
            if t.contains("rc k8s let") {
                in_let = true;
                if let Some(pos) = line.find('{') {
                    depth = 1;
                    let rest = &line[pos + 1..];
                    if !rest.trim().is_empty() && !rest.trim().starts_with('}') {
                        body.push_str(rest);
                        body.push('\n');
                    }
                }
            }
            continue;
        }
        for ch in line.chars() {
            if ch == '{' {
                depth += 1;
                if depth > 1 {
                    body.push(ch);
                }
            } else if ch == '}' {
                depth -= 1;
                if depth == 0 {
                    return Ok(body);
                }
                body.push(ch);
            } else if depth >= 1 {
                body.push(ch);
            }
        }
        if depth >= 1 {
            body.push('\n');
        }
    }
    if in_let {
        Err("unclosed rc k8s let { ... }".into())
    } else {
        Err("missing `rc k8s let { ... }`".into())
    }
}

fn parse_set_blocks(body: &str) -> Result<HashMap<String, HashMap<String, String>>, String> {
    let mut blocks = HashMap::new();
    let chars: Vec<char> = body.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        while i < chars.len() && chars[i].is_whitespace() {
            i += 1;
        }
        if i >= chars.len() {
            break;
        }
        let start = i;
        while i < chars.len() && (chars[i].is_alphanumeric() || chars[i] == '_' || chars[i] == '-') {
            i += 1;
        }
        let block_name: String = chars[start..i].iter().collect();
        if block_name.is_empty() {
            return Err(format!("expected block name at offset {start}"));
        }
        while i < chars.len() && chars[i].is_whitespace() {
            i += 1;
        }
        if !starts_with(&chars, i, "set") {
            return Err(format!("expected `set` after `{block_name}`"));
        }
        i += 3;
        while i < chars.len() && chars[i].is_whitespace() {
            i += 1;
        }
        if i >= chars.len() || chars[i] != '{' {
            return Err(format!("expected `{{` after `{block_name} set`"));
        }
        i += 1;
        let inner_start = i;
        let mut depth = 1i32;
        while i < chars.len() && depth > 0 {
            if chars[i] == '{' {
                depth += 1;
            } else if chars[i] == '}' {
                depth -= 1;
            }
            if depth > 0 {
                i += 1;
            }
        }
        let inner: String = chars[inner_start..i].iter().collect();
        i += 1;
        blocks.insert(block_name, parse_block_fields(&inner)?);
    }
    Ok(blocks)
}

fn parse_block_fields(inner: &str) -> Result<HashMap<String, String>, String> {
    let mut out = HashMap::new();
    for part in split_top_level_commas(inner) {
        let part = part.trim();
        if part.is_empty() {
            continue;
        }
        let Some(eq) = part.find('=') else {
            return Err(format!("expected `=` in assignment: {part:?}"));
        };
        let key = part[..eq].trim().to_string();
        let val = part[eq + 1..].trim().trim_end_matches(',').trim();
        if key.is_empty() {
            return Err("empty field name".into());
        }
        out.insert(key, val.to_string());
    }
    Ok(out)
}

fn split_top_level_commas(s: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut cur = String::new();
    let mut depth_paren = 0i32;
    let mut depth_brace = 0i32;
    for ch in s.chars() {
        match ch {
            '(' => {
                depth_paren += 1;
                cur.push(ch);
            }
            ')' => {
                depth_paren -= 1;
                cur.push(ch);
            }
            '{' => {
                depth_brace += 1;
                cur.push(ch);
            }
            '}' => {
                depth_brace -= 1;
                cur.push(ch);
            }
            ',' | '\n' if depth_paren == 0 && depth_brace == 0 => {
                if !cur.trim().is_empty() {
                    parts.push(cur.clone());
                }
                cur.clear();
            }
            _ => cur.push(ch),
        }
    }
    if !cur.trim().is_empty() {
        parts.push(cur);
    }
    parts
}

fn starts_with(chars: &[char], i: usize, word: &str) -> bool {
    let w: Vec<char> = word.chars().collect();
    if i + w.len() > chars.len() {
        return false;
    }
    chars[i..i + w.len()] == w
        && (i + w.len() == chars.len() || !chars[i + w.len()].is_alphanumeric())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn fixture(slug: &str) -> String {
        let root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .parent()
            .unwrap()
            .to_path_buf();
        std::fs::read_to_string(root.join("custom").join(slug).join("infra/k8s.rice"))
            .unwrap()
    }

    #[test]
    fn parse_egos_k8s_rice() {
        let cfg = parse_k8s_rice(&fixture("egos.app")).unwrap();
        assert_eq!(cfg.profile, "local");
        assert!(!cfg.cluster_slices.contains(&"gpu".to_string()));
        assert_eq!(cfg.bots.image_tag, "dev");
    }

    #[test]
    fn parse_code_rice_k8s_rice() {
        let cfg = parse_k8s_rice(&fixture("code-rice.com")).unwrap();
        assert_eq!(cfg.profile, "prod");
        assert!(cfg.cluster_slices.contains(&"gpu".to_string()));
        assert_eq!(cfg.bots.image_tag, "prod");
    }

    #[test]
    fn render_egos_project_cue() {
        let cfg = parse_k8s_rice(&fixture("egos.app")).unwrap();
        let out = render_project_cue("egos.app", &cfg);
        assert!(out.contains("package k8s"));
        assert!(out.contains("profile: local") || out.contains("\"local\""));
    }
}
