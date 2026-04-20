//! Source → token stream with byte spans (for diagnostics and parser).

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use logos::Logos;

use crate::token::Token;

// [ ] https://docs.rs/logos/
// [ ] full .rice token set; extras line/col; error recovery; zero-copy slices

/// Lex full source into `(token, byte range)` pairs.
pub fn lex_all(src: &str) -> Vec<(Token, std::ops::Range<usize>)> {
    let mut lexer = Token::lexer(src);
    let mut out = Vec::new();
    while let Some(res) = lexer.next() {
        let span = lexer.span();
        let tok = match res {
            Ok(t) => t,
            Err(()) => Token::Error,
        };
        out.push((tok, span));
    }
    out
}
