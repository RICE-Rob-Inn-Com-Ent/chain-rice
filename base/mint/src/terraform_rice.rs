//! Parse CHIEF `terraform.rice` → `infra/gen/chief/terraform_project.cue` (schema: `infra/proto/cue/infra.cue`).

use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct TerraformDeployment {
    pub cloud: String,
    pub region: String,
    pub vpc_cidr: String,
}

impl TerraformDeployment {
    pub fn key(&self) -> String {
        format!("{}:{}", self.cloud, self.region)
    }
}

#[derive(Debug, Clone)]
pub struct TerraformRiceConfig {
    pub rice_environment: String,
    pub rice_cloud_provider: String,
    pub rice_github_org: String,
    pub rice_github_repo: String,
    pub rice_domain: String,
    pub rice_k8s_cluster_name: String,
    pub rice_db_instance_class: String,
    pub rice_registry: String,
    pub rice_region: String,
    pub rice_availability_zones: Vec<String>,
    pub rice_vpc_cidr: String,
    pub rice_enable_gpu: bool,
    pub rice_gpu_instance_type: String,
    pub rice_aws_region: String,
    pub rice_aws_assume_role_arn: String,
    pub rice_gcp_project_id: String,
    pub rice_gcp_region: String,
    pub rice_azure_subscription_id: String,
    pub rice_azure_tenant_id: String,
    pub rice_tf_backend: String,
    pub rice_kubeconfig_path: String,
    pub rice_enabled_clouds: Vec<String>,
    pub rice_primary_cloud: String,
    pub rice_regions_aws: Vec<String>,
    pub rice_regions_gcp: Vec<String>,
    pub rice_regions_azure: Vec<String>,
    pub rice_deployments: Vec<TerraformDeployment>,
}

impl TerraformRiceConfig {
    pub fn to_bindings(&self) -> Vec<(String, String)> {
        vec![
            ("rice_environment".into(), self.rice_environment.clone()),
            ("rice_cloud_provider".into(), self.rice_cloud_provider.clone()),
            ("rice_github_org".into(), self.rice_github_org.clone()),
            ("rice_github_repo".into(), self.rice_github_repo.clone()),
            ("rice_domain".into(), self.rice_domain.clone()),
            ("rice_k8s_cluster_name".into(), self.rice_k8s_cluster_name.clone()),
            ("rice_db_instance_class".into(), self.rice_db_instance_class.clone()),
            ("rice_registry".into(), self.rice_registry.clone()),
            ("rice_region".into(), self.rice_region.clone()),
            (
                "rice_availability_zones".into(),
                self.rice_availability_zones.join(","),
            ),
            ("rice_vpc_cidr".into(), self.rice_vpc_cidr.clone()),
            (
                "rice_enable_gpu".into(),
                self.rice_enable_gpu.to_string(),
            ),
            (
                "rice_gpu_instance_type".into(),
                self.rice_gpu_instance_type.clone(),
            ),
            ("rice_aws_region".into(), self.rice_aws_region.clone()),
            (
                "rice_aws_assume_role_arn".into(),
                self.rice_aws_assume_role_arn.clone(),
            ),
            ("rice_gcp_project_id".into(), self.rice_gcp_project_id.clone()),
            ("rice_gcp_region".into(), self.rice_gcp_region.clone()),
            (
                "rice_azure_subscription_id".into(),
                self.rice_azure_subscription_id.clone(),
            ),
            (
                "rice_azure_tenant_id".into(),
                self.rice_azure_tenant_id.clone(),
            ),
            ("rice_tf_backend".into(), self.rice_tf_backend.clone()),
            (
                "rice_kubeconfig_path".into(),
                self.rice_kubeconfig_path.clone(),
            ),
            (
                "rice_enabled_clouds".into(),
                self.rice_enabled_clouds.join(","),
            ),
            (
                "rice_primary_cloud".into(),
                self.rice_primary_cloud.clone(),
            ),
            (
                "rice_regions_aws".into(),
                self.rice_regions_aws.join(","),
            ),
            (
                "rice_regions_gcp".into(),
                self.rice_regions_gcp.join(","),
            ),
            (
                "rice_regions_azure".into(),
                self.rice_regions_azure.join(","),
            ),
            (
                "rice_deployments".into(),
                self.rice_deployments
                    .iter()
                    .map(|d| format!("{}|{}|{}", d.cloud, d.region, d.vpc_cidr))
                    .collect::<Vec<_>>()
                    .join(";"),
            ),
        ]
    }
}

pub fn parse_terraform_rice(src: &str) -> Result<TerraformRiceConfig, String> {
    let body = extract_let_body(src)?;
    let blocks = parse_set_blocks(&body)?;

    let env = blocks
        .get("environment")
        .ok_or("missing required block: environment set { ... }")?;
    let github = blocks
        .get("github")
        .ok_or("missing required block: github set { ... }")?;
    let cluster = blocks
        .get("cluster")
        .ok_or("missing required block: cluster set { ... }")?;
    let network = blocks
        .get("network")
        .ok_or("missing required block: network set { ... }")?;

    let aws = blocks.get("aws").cloned().unwrap_or_default();
    let gcp = blocks.get("gcp").cloned().unwrap_or_default();
    let azure = blocks.get("azure").cloned().unwrap_or_default();
    let gpu = blocks.get("gpu").cloned().unwrap_or_default();
    let state = blocks.get("state").cloned().unwrap_or_default();

    let az = network
        .get("availability_zones")
        .map(|raw| parse_name_tuple(raw))
        .transpose()?
        .unwrap_or_else(|| vec!["eu-west-1a".into(), "eu-west-1b".into()]);

    let env_region = optional_field(env, "region", "eu-west-1");
    let env_cloud = require_field(env, "cloud_provider")?;
    let default_vpc = require_field(network, "vpc_cidr")?;

    let clouds = blocks.get("clouds").cloned().unwrap_or_default();
    let regions_blk = blocks.get("regions").cloned().unwrap_or_default();

    let (enabled_clouds, primary_cloud) = if clouds.is_empty() {
        let enabled = if env_cloud == "all" {
            vec!["aws".into(), "gcp".into(), "azure".into()]
        } else {
            vec![env_cloud.clone()]
        };
        (enabled, env_cloud.clone())
    } else {
        let enabled = clouds
            .get("enabled")
            .map(|raw| parse_name_tuple(raw))
            .transpose()?
            .unwrap_or_else(|| vec![env_cloud.clone()]);
        let primary = optional_field(&clouds, "primary", &env_cloud);
        (enabled, primary)
    };

    let mut regions_aws = regions_for_cloud(&regions_blk, "aws", &aws, &env_region);
    let mut regions_gcp = regions_for_cloud(&regions_blk, "gcp", &gcp, "europe-west1");
    let mut regions_azure = regions_for_cloud(&regions_blk, "azure", &azure, "westeurope");

    if regions_blk.is_empty() {
        if regions_aws.is_empty() && enabled_clouds.iter().any(|c| c == "aws") {
            regions_aws = vec![optional_field(&aws, "region", &env_region)];
        }
        if regions_gcp.is_empty() && enabled_clouds.iter().any(|c| c == "gcp") {
            regions_gcp = vec![optional_field(&gcp, "region", "europe-west1")];
        }
        if regions_azure.is_empty() && enabled_clouds.iter().any(|c| c == "azure") {
            regions_azure = vec![optional_field(&azure, "region", "westeurope")];
        }
    }

    let rice_deployments = build_deployments(
        &enabled_clouds,
        &regions_aws,
        &regions_gcp,
        &regions_azure,
        &default_vpc,
        network,
    );

    let rice_cloud_provider = if enabled_clouds.len() > 1 || env_cloud == "all" {
        "all".to_string()
    } else {
        primary_cloud.clone()
    };

    Ok(TerraformRiceConfig {
        rice_environment: require_field(env, "name")?,
        rice_cloud_provider,
        rice_domain: require_field(env, "domain")?,
        rice_region: require_field(env, "region")?,
        rice_github_org: require_field(github, "org")?,
        rice_github_repo: require_field(github, "repo")?,
        rice_k8s_cluster_name: require_field(cluster, "k8s_name")?,
        rice_db_instance_class: require_field(cluster, "db_class")?,
        rice_registry: optional_field(cluster, "registry", "ghcr.io"),
        rice_vpc_cidr: require_field(network, "vpc_cidr")?,
        rice_availability_zones: az,
        rice_enable_gpu: gpu
            .get("enabled")
            .map(|s| parse_bool(s))
            .transpose()?
            .unwrap_or(false),
        rice_gpu_instance_type: optional_field(&gpu, "instance_type", ""),
        rice_aws_region: optional_field(&aws, "region", &env_region),
        rice_aws_assume_role_arn: optional_field(&aws, "assume_role_arn", ""),
        rice_gcp_project_id: optional_field(&gcp, "project_id", "replace-with-gcp-project-id"),
        rice_gcp_region: optional_field(&gcp, "region", "europe-west1"),
        rice_azure_subscription_id: optional_field(&azure, "subscription_id", ""),
        rice_azure_tenant_id: optional_field(&azure, "tenant_id", ""),
        rice_tf_backend: optional_field(&state, "backend", "local"),
        rice_kubeconfig_path: optional_field(&state, "kubeconfig_path", "~/.kube/config"),
        rice_enabled_clouds: enabled_clouds,
        rice_primary_cloud: primary_cloud,
        rice_regions_aws: regions_aws,
        rice_regions_gcp: regions_gcp,
        rice_regions_azure: regions_azure,
        rice_deployments,
    })
}

fn regions_for_cloud(
    regions_blk: &HashMap<String, String>,
    cloud: &str,
    cloud_block: &HashMap<String, String>,
    fallback: &str,
) -> Vec<String> {
    if let Some(raw) = regions_blk.get(cloud) {
        if let Ok(list) = parse_name_tuple(raw) {
            if !list.is_empty() {
                return list;
            }
        }
    }
    let r = optional_field(cloud_block, "region", fallback);
    if r.is_empty() {
        vec![]
    } else {
        vec![r]
    }
}

fn build_deployments(
    enabled_clouds: &[String],
    regions_aws: &[String],
    regions_gcp: &[String],
    regions_azure: &[String],
    default_vpc: &str,
    network: &HashMap<String, String>,
) -> Vec<TerraformDeployment> {
    let mut out = Vec::new();
    for cloud in enabled_clouds {
        let regions: &[String] = match cloud.as_str() {
            "aws" => regions_aws,
            "gcp" => regions_gcp,
            "azure" => regions_azure,
            _ => continue,
        };
        for region in regions {
            let cidr_key = format!("{cloud}.{region}.vpc_cidr");
            let vpc = network
                .get(&cidr_key)
                .map(|s| normalize_atom(s))
                .unwrap_or_else(|| default_vpc.to_string());
            out.push(TerraformDeployment {
                cloud: cloud.clone(),
                region: region.clone(),
                vpc_cidr: vpc,
            });
        }
    }
    if out.is_empty() {
        out.push(TerraformDeployment {
            cloud: "aws".into(),
            region: "eu-west-1".into(),
            vpc_cidr: default_vpc.to_string(),
        });
    }
    out
}

pub fn render_terraform_project_cue(cfg: &TerraformRiceConfig) -> String {
    let lines = vec![
        "package terraform".to_string(),
        String::new(),
        "// Generated — mint_overlay_check --apply-terraform (CHIEF_PROJECT)".to_string(),
        "// Edit custom/*/bowl + custom/*/infra/terraform.rice. Schema: infra/proto/cue/infra.cue"
            .to_string(),
        String::new(),
        "projectParams: #TerraformParams & {".to_string(),
        format!("\trice_environment: {},", cue_quote(&cfg.rice_environment)),
        format!("\trice_cloud_provider: {},", cue_quote(&cfg.rice_cloud_provider)),
        format!("\trice_github_org: {},", cue_quote(&cfg.rice_github_org)),
        format!("\trice_github_repo: {},", cue_quote(&cfg.rice_github_repo)),
        format!("\trice_domain: {},", cue_quote(&cfg.rice_domain)),
        format!(
            "\trice_k8s_cluster_name: {},",
            cue_quote(&cfg.rice_k8s_cluster_name)
        ),
        format!(
            "\trice_db_instance_class: {},",
            cue_quote(&cfg.rice_db_instance_class)
        ),
        format!("\trice_registry: {},", cue_quote(&cfg.rice_registry)),
        format!("\trice_region: {},", cue_quote(&cfg.rice_region)),
        format!(
            "\trice_availability_zones: {},",
            render_string_list(&cfg.rice_availability_zones)
        ),
        format!("\trice_vpc_cidr: {},", cue_quote(&cfg.rice_vpc_cidr)),
        format!("\trice_enable_gpu: {},", cfg.rice_enable_gpu),
        format!(
            "\trice_gpu_instance_type: {},",
            cue_quote(&cfg.rice_gpu_instance_type)
        ),
        format!("\trice_aws_region: {},", cue_quote(&cfg.rice_aws_region)),
        format!(
            "\trice_aws_assume_role_arn: {},",
            cue_quote(&cfg.rice_aws_assume_role_arn)
        ),
        format!("\trice_gcp_project_id: {},", cue_quote(&cfg.rice_gcp_project_id)),
        format!("\trice_gcp_region: {},", cue_quote(&cfg.rice_gcp_region)),
        format!(
            "\trice_azure_subscription_id: {},",
            cue_quote(&cfg.rice_azure_subscription_id)
        ),
        format!(
            "\trice_azure_tenant_id: {},",
            cue_quote(&cfg.rice_azure_tenant_id)
        ),
        format!("\trice_tf_backend: {},", cue_quote(&cfg.rice_tf_backend)),
        format!(
            "\trice_kubeconfig_path: {},",
            cue_quote(&cfg.rice_kubeconfig_path)
        ),
        format!(
            "\trice_enabled_clouds: {},",
            render_string_list(&cfg.rice_enabled_clouds)
        ),
        format!("\trice_primary_cloud: {},", cue_quote(&cfg.rice_primary_cloud)),
        format!(
            "\trice_regions_aws: {},",
            render_string_list(&cfg.rice_regions_aws)
        ),
        format!(
            "\trice_regions_gcp: {},",
            render_string_list(&cfg.rice_regions_gcp)
        ),
        format!(
            "\trice_regions_azure: {},",
            render_string_list(&cfg.rice_regions_azure)
        ),
        format!("\trice_deployments: {}", render_deployments_list(cfg)),
        "}".to_string(),
        String::new(),
    ];
    lines.join("\n")
}

fn render_deployments_list(cfg: &TerraformRiceConfig) -> String {
    if cfg.rice_deployments.is_empty() {
        return "[]".to_string();
    }
    let items: Vec<String> = cfg
        .rice_deployments
        .iter()
        .map(|d| {
            format!(
                "{{cloud: {}, region: {}, vpc_cidr: {}}}",
                cue_quote(&d.cloud),
                cue_quote(&d.region),
                cue_quote(&d.vpc_cidr)
            )
        })
        .collect();
    format!("[{}]", items.join(", "))
}

fn render_string_list(items: &[String]) -> String {
    if items.is_empty() {
        return "[]".to_string();
    }
    let items: Vec<String> = items.iter().map(|l| cue_quote(l)).collect();
    format!("[{}]", items.join(", "))
}

fn cue_quote(s: &str) -> String {
    format!("{:?}", s)
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
            if t.contains("rc terraform let") {
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
        Err("unclosed rc terraform let { ... }".into())
    } else {
        Err("missing `rc terraform let { ... }`".into())
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
        while i < chars.len() && (chars[i].is_alphanumeric() || chars[i] == '_') {
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::PathBuf;

    fn fixture(slug: &str) -> String {
        let mut p = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        p.push("../../custom");
        p.push(slug);
        p.push("infra/terraform.rice");
        fs::read_to_string(p).expect("terraform.rice fixture")
    }

    #[test]
    fn parse_egos_terraform_rice() {
        let cfg = parse_terraform_rice(&fixture("egos.app")).unwrap();
        assert_eq!(cfg.rice_environment, "dev");
        assert_eq!(cfg.rice_domain, "egos.app");
        assert_eq!(cfg.rice_availability_zones.len(), 2);
        assert!(!cfg.rice_enable_gpu);
    }

    #[test]
    fn parse_code_rice_terraform_rice() {
        let cfg = parse_terraform_rice(&fixture("code-rice.com")).unwrap();
        assert_eq!(cfg.rice_domain, "code-rice.com");
        assert_eq!(cfg.rice_vpc_cidr, "10.3.0.0/16");
        assert!(cfg.rice_deployments.len() >= 2);
    }

    #[test]
    fn deployments_have_unique_keys() {
        let cfg = parse_terraform_rice(&fixture("code-rice.com")).unwrap();
        let keys: Vec<_> = cfg.rice_deployments.iter().map(|d| d.key()).collect();
        let set: std::collections::HashSet<_> = keys.iter().collect();
        assert_eq!(keys.len(), set.len());
    }

    #[test]
    fn render_includes_az_list() {
        let cfg = parse_terraform_rice(&fixture("egos.app")).unwrap();
        let out = render_terraform_project_cue(&cfg);
        assert!(out.contains("eu-west-1a"));
    }
}
