//! Minimal formatter for CHIEF infra `.rice` (tabs inside `set { }`, trim, final newline).

/// Format CHIEF infra rice source (docker/k8s/terraform.rice).
pub fn format_rice_infra(src: &str) -> String {
    let mut out = String::new();
    let mut depth = 0u32;
    for line in src.lines() {
        let trimmed = line.trim_end();
        if trimmed.is_empty() {
            out.push('\n');
            continue;
        }
        let t = trimmed.trim();
        let close_braces = t.chars().filter(|&c| c == '}').count() as u32;
        let open_braces = t.chars().filter(|&c| c == '{').count() as u32;
        if close_braces > 0 && open_braces == 0 {
            depth = depth.saturating_sub(close_braces);
        }
        let indent = "\t".repeat(depth as usize);
        out.push_str(&indent);
        out.push_str(t);
        out.push('\n');
        if open_braces > 0 {
            depth += open_braces;
            if close_braces > 0 {
                depth = depth.saturating_sub(close_braces);
            }
        }
    }
    let result = out.trim_end().to_string();
    if result.is_empty() {
        return String::new();
    }
    format!("{result}\n")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn indents_set_block() {
        let src = "rc terraform let {\nenvironment set {\nname = dev\n}\n}\n";
        let fmt = format_rice_infra(src);
        assert!(fmt.contains("\tenvironment set {"));
        assert!(fmt.contains("\t\tname = dev"));
    }
}
