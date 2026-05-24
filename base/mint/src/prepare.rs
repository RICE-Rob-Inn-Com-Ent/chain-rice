//! CHIEF project scaffold — `rice prepare <slug>` creates `custom/<slug>/` with standard `.rice` files.

use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Copy)]
pub enum ScaffoldProfile {
    Full,
    Minimal,
}

pub struct PrepareOptions {
    pub slug: String,
    pub profile: ScaffoldProfile,
    pub force: bool,
}

fn write_file(path: &Path, content: &str, force: bool) -> Result<(), String> {
    if path.exists() && !force {
        return Ok(());
    }
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|e| format!("mkdir {}: {e}", parent.display()))?;
    }
    fs::write(path, content).map_err(|e| format!("write {}: {e}", path.display()))
}

fn bowl_content(slug: &str) -> String {
    format!(
        r#"[project]
name = "{slug}"

# Infra Rice syntax package (schema: infra/proto/cue/infra.cue). Empty version = workspace MASON.
[package]
infra = ""
"#
    )
}

fn docker_rice_full(slug: &str) -> String {
    format!(
        r#"use infra as docker

// {slug} — CHIEF docker overlay (edit business settings here).
rc docker let {{
	db set {{
		name = "{slug}"
		user = "{slug}"
		init_sql = (pgcrypto, uuid-ossp)
	}}

	memory set {{
		redis = 512M
		yugabyte = 2G
		qdrant = 1G
		nats = 512M
		temporal = 1G
	}}

	postal set {{
		profile = _disabled
	}}

	mailpit set {{
		profile = mailpit
		max_messages = 500
	}}

	bot set {{
		fallback_chain = (vllm, ollama)
	}}

	otp set {{
		enabled = true
		port = 4000
		memory = 1G
	}}

	docs set {{
		enabled = true
		port = 8080
	}}
}}
"#
    )
}

fn docker_rice_minimal(slug: &str) -> String {
    format!(
        r#"use infra as docker

// {slug} — minimal dev stack.
rc docker let {{
	db set {{
		name = "{slug}"
		user = "app"
	}}

	memory set {{
		redis = 256M
	}}

	mailpit set {{
		profile = mailpit
	}}
}}
"#
    )
}

fn k8s_rice(slug: &str) -> String {
    format!(
        r#"use infra as k8s

// {slug} — k8s overlay (local/gitops).
rc k8s let {{
	profile set {{
		name = local
	}}

	gitops set {{
		repoURL = "https://github.com/REPLACE_ORG/{slug}.git"
		targetRevision = HEAD
	}}

	stack set {{
		enabled = (argocd, cert-manager)
	}}
}}
"#
    )
}

fn terraform_rice(slug: &str) -> String {
    format!(
        r#"use infra as terraform

// {slug} — terraform overlay.
rc terraform let {{
	environment set {{
		name = dev
	}}

	github set {{
		owner = REPLACE_ORG
		repo = {slug}
	}}

	cluster set {{
		name = {slug}-dev
		version = 1.32
	}}
}}
"#
    )
}

fn docs_rice(slug: &str) -> String {
    format!(
        r#"use infra as docs

// {slug} — documentation site overlay.
rc docs let {{
	site set {{
		url = "https://docs.{slug}.invalid"
	}}

	mkdocs set {{
		site_name = "{slug} Docs"
		theme = material
		nav = (Home, API)
	}}
}}
"#
    )
}

fn site_rice(slug: &str) -> String {
    crate::mirror::mirror_rice_body(slug, "frontend/site.rice")
}

fn proto_rice(slug: &str) -> String {
    format!(
        r#"# CHIEF — {slug} protobuf overlay (MASON buf root: infra/proto).
"#
    )
}

fn base_contract_rice() -> &'static str {
    r#"// CHIEF — CLERK contract hooks (configure business rules).
fn hook_contract_instantiate {}
fn hook_contract_execute {}
fn hook_contract_query {}
"#
}

fn base_calc_rice() -> &'static str {
    r#"// CHIEF — CLERK calc hooks.
fn hook_calc_eval {}
"#
}

fn base_policies_rice() -> &'static str {
    r#"// CHIEF — policy hooks.
fn hook_policy_check {}
"#
}

fn base_security_rice() -> &'static str {
    r#"// CHIEF — security hooks.
fn hook_security_audit {}
"#
}

fn base_private_rice() -> &'static str {
    r#"// CHIEF — private data hooks.
fn hook_private_vault {}
"#
}

fn service_auth_rice(slug: &str) -> String {
    format!(
        r#"# CHIEF — {slug} SMITH auth overlay.
fn hook_auth_session {{}}
"#
    )
}

fn frontend_pubspec_stub(slug: &str) -> String {
    format!(
        r#"name: {slug}_frontend
description: CHIEF Flutter shell for {slug}
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
"#
    )
}

fn frontend_main_dart() -> &'static str {
    r#"import 'package:flutter/material.dart';

void main() {
  runApp(const RiceChiefApp());
}

class RiceChiefApp extends StatelessWidget {
  const RiceChiefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rice CHIEF',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2D6A4F)),
      home: const Scaffold(
        body: Center(child: Text('rice cook — hot reload ready')),
      ),
    );
  }
}
"#
}

/// Scaffold `custom/<slug>/` with standard CHIEF `.rice` files.
pub fn prepare_project(repo_root: &Path, opts: &PrepareOptions) -> Result<PathBuf, String> {
    let slug = opts.slug.trim();
    if slug.is_empty() || slug.contains('/') || slug.contains("..") {
        return Err("invalid project slug".into());
    }
    let project_dir = repo_root.join("custom").join(slug);
    if project_dir.exists() && !opts.force {
        return Err(format!(
            "{} already exists — use --force to overwrite new files only",
            project_dir.display()
        ));
    }

    let docker = match opts.profile {
        ScaffoldProfile::Full => docker_rice_full(slug),
        ScaffoldProfile::Minimal => docker_rice_minimal(slug),
    };

    let files: Vec<(&str, String)> = vec![
        ("bowl", bowl_content(slug)),
        ("infra/docker.rice", docker),
        ("infra/k8s.rice", k8s_rice(slug)),
        ("infra/terraform.rice", terraform_rice(slug)),
        ("infra/docs.rice", docs_rice(slug)),
        ("infra/proto.rice", proto_rice(slug)),
        ("base/contract.rice", base_contract_rice().into()),
        ("base/calc.rice", base_calc_rice().into()),
        ("base/policies.rice", base_policies_rice().into()),
        ("base/security.rice", base_security_rice().into()),
        ("base/private.rice", base_private_rice().into()),
        ("service/auth.rice", service_auth_rice(slug)),
        ("frontend/site.rice", site_rice(slug)),
        ("frontend/pubspec.yaml", frontend_pubspec_stub(slug)),
        ("frontend/lib/main.dart", frontend_main_dart().into()),
    ];

    for (rel, body) in files {
        write_file(&project_dir.join(rel), &body, opts.force)?;
    }

    let mirror_written =
        crate::mirror::scaffold_mirror_stack(&project_dir, slug, opts.force)?;
    eprintln!(
        "mirror stack: {} .rice files written/updated under {}",
        mirror_written,
        project_dir.display()
    );

    Ok(project_dir)
}
