//! Code generation — `minijinja` templates for multi-target / role-specific emission.

use minijinja::Environment;

// [ ] https://docs.rs/minijinja/ — targets Go, Rust, TS, Dart, Python, CUE, Proto from RICE_CODEGEN_TEMPLATES_DIR

pub fn render_role_stub(role: &str) -> Result<String, minijinja::Error> {
    let mut env = Environment::new();
    env.add_template("role", "role={{ role }}")?;
    env.get_template("role")?
        .render(minijinja::context! { role => role })
}
