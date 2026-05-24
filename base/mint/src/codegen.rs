//! Code generation — `minijinja` templates for multi-target / role-specific emission.

// TODO(mint):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use minijinja::Environment;

// [ ] https://docs.rs/minijinja/ — targets Go, Rust, TS, Dart, Python, CUE, Proto from CLERK_CODEGEN_TEMPLATES_DIR

pub fn render_role_stub(role: &str) -> Result<String, minijinja::Error> {
    let mut env = Environment::new();
    env.add_template("role", "role={{ role }}")?;
    env.get_template("role")?
        .render(minijinja::context! { role => role })
}
