//! CHIEF `bowl` [package] infra + `.rice` `use infra as <facet>` contract (MASON `infra/proto/cue/infra.cue`).

/// `bowl` `[package]` — infra syntax package (empty version = workspace MASON schema).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BowlInfraPackage {
    /// `""` → monorepo `infra/proto/cue/infra.cue`; future: pinned published grammar version.
    pub version: String,
}

/// First-line import in `docker.rice` / `k8s.rice`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RiceInfraImport {
    pub package: String,
    pub facet: String,
}

pub const INFRA_PACKAGE_NAME: &str = "infra";
pub const FACET_DOCKER: &str = "docker";
pub const FACET_K8S: &str = "k8s";
pub const FACET_TERRAFORM: &str = "terraform";
pub const FACET_DOCS: &str = "docs";
pub const FACET_FRONTEND: &str = "frontend";

pub const INFRA_FACETS: &[&str] = &[
    FACET_DOCKER,
    FACET_K8S,
    FACET_TERRAFORM,
    FACET_DOCS,
    FACET_FRONTEND,
];

/// Parse `[package] infra = "..."` from CHIEF `bowl` (required for infra overlays).
pub fn parse_bowl_infra_package(bowl_src: &str) -> Result<BowlInfraPackage, String> {
    let mut in_package = false;
    let mut found = false;
    let mut version = String::new();
    for line in bowl_src.lines() {
        let t = line.trim();
        if t.starts_with('#') || t.is_empty() {
            continue;
        }
        if t.starts_with('[') && t.ends_with(']') {
            in_package = t == "[package]";
            continue;
        }
        if !in_package {
            continue;
        }
        if let Some(rest) = t.strip_prefix("infra") {
            let rest = rest.trim();
            if let Some(rest) = rest.strip_prefix('=') {
                let rest = rest.trim();
                version = parse_bowl_string_value(rest)?;
                found = true;
                break;
            }
        }
    }
    if !found {
        return Err(
            "missing required `[package] infra = \"...\"` in bowl (empty \"\" = workspace MASON infra schema)".into(),
        );
    }
    Ok(BowlInfraPackage { version })
}

fn parse_bowl_string_value(rhs: &str) -> Result<String, String> {
    let rhs = rhs.strip_suffix(';').unwrap_or(rhs).trim();
    if rhs == "\"\"" || rhs == "''" {
        return Ok(String::new());
    }
    if let Some(inner) = rhs.strip_prefix('"').and_then(|s| s.strip_suffix('"')) {
        return Ok(inner.to_string());
    }
    if rhs.is_empty() {
        return Ok(String::new());
    }
    Err(format!(
        "expected `[package] infra = \"\"` or quoted version, got {:?}",
        rhs
    ))
}

/// Parse `use infra as docker` / `use infra as k8s` (first non-comment, non-empty line).
pub fn parse_infra_use_line(src: &str) -> Result<RiceInfraImport, String> {
    for line in src.lines() {
        let t = line.trim();
        if t.is_empty() || t.starts_with("//") || t.starts_with('#') {
            continue;
        }
        return parse_use_line(t);
    }
    Err("missing `use infra as <facet>` (docker | k8s | terraform | docs | frontend)".into())
}

fn parse_use_line(t: &str) -> Result<RiceInfraImport, String> {
    let Some(rest) = t.strip_prefix("use ") else {
        return Err(format!(
            "expected `use infra as <facet>`, got {:?} (declare bowl [package] infra, then import facet)",
            t
        ));
    };
    let rest = rest.trim();
    let Some((pkg, facet)) = rest.split_once(" as ") else {
        if rest == "docker" || rest == "k8s" {
            return Err(format!(
                "legacy `use {rest}` — use `use infra as {rest}` (infra package from bowl [package] infra)"
            ));
        }
        return Err(format!("expected `use infra as <facet>`, got {:?}", t));
    };
    let package = pkg.trim().to_string();
    let facet = facet.trim().trim_end_matches(';').to_string();
    if package.is_empty() || facet.is_empty() {
        return Err(format!("invalid use line {:?}", t));
    }
    Ok(RiceInfraImport { package, facet })
}

/// Ensure `.rice` imports the infra package declared in `bowl` and targets the expected facet.
pub fn validate_infra_rice_import(
    bowl: &BowlInfraPackage,
    import: &RiceInfraImport,
    expected_facet: &str,
) -> Result<(), String> {
    if import.package != INFRA_PACKAGE_NAME {
        return Err(format!(
            "rice imports package {:?}, but bowl declares [package] infra = {:?}",
            import.package, bowl.version
        ));
    }
    if import.facet != expected_facet {
        return Err(format!(
            "expected `use infra as {expected_facet}`, got `use infra as {}`",
            import.facet
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_bowl_infra_empty_version() {
        let s = "[project]\nname = \"egos.app\"\n\n[package]\ninfra = \"\"\n";
        let p = parse_bowl_infra_package(s).unwrap();
        assert_eq!(p.version, "");
    }

    #[test]
    fn parse_use_infra_as_docker() {
        let s = "use infra as docker\n\nrc docker let {\n}\n";
        let u = parse_infra_use_line(s).unwrap();
        assert_eq!(u.package, "infra");
        assert_eq!(u.facet, "docker");
    }

    #[test]
    fn reject_legacy_use_docker() {
        let err = parse_infra_use_line("use docker\n").unwrap_err();
        assert!(err.contains("legacy"));
    }

    #[test]
    fn validate_facet_mismatch() {
        let bowl = BowlInfraPackage {
            version: String::new(),
        };
        let import = RiceInfraImport {
            package: "infra".into(),
            facet: "k8s".into(),
        };
        assert!(validate_infra_rice_import(&bowl, &import, FACET_DOCKER).is_err());
    }
}
