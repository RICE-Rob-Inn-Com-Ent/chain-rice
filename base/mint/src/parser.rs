//! `chumsky` parser — builds a flat list of identifiers (placeholder until CST bridge).

// TODO(mint):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use chumsky::prelude::*;

// [ ] https://docs.rs/chumsky/
// [ ] full .rice grammar; recovery; pratt; spans for miette

/// Parse whitespace-separated identifiers until end of input.
/// Smoke: tokenize overlay line `let rice_x = "y"` (logos + extended tokens).
pub fn tokenize_overlay_line(src: &str) -> Vec<crate::token::Token> {
    use crate::token::Token;
    use logos::Logos;
    Token::lexer(src)
        .filter_map(|t| t.ok())
        .collect()
}

pub fn parse_idents(src: &str) -> Result<Vec<String>, String> {
    let p = text::ident::<&str, extra::Default>()
        .separated_by(just::<_, _, extra::Default>(' '))
        .allow_trailing()
        .collect::<Vec<_>>()
        .then_ignore(end());
    p.parse(src)
        .into_result()
        .map(|v| v.into_iter().map(|s| s.to_string()).collect())
        .map_err(|e| format!("{e:?}"))
}
