//! Token kinds for `.rice` — `logos` lexer.

// TODO(mint):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use logos::Logos;

// [ ] https://docs.rs/logos/ — https://docs.rs/rowan/
// [ ] SyntaxKind for rowan; From for rowan::SyntaxKind; miette Display; keyword set

#[derive(Logos, Debug, Clone, PartialEq, Eq)]
#[logos(skip r"[ \t\n\f]+")]
#[logos(error = ())]
pub enum Token {
    #[token("fn")]
    KwFn,
    #[token("let")]
    KwLet,
    #[regex(r#""[^"]*""#, |lex| lex.slice()[1..lex.slice().len() - 1].to_string())]
    StrLit(String),
    #[token("=")]
    Eq,
    #[token(";")]
    Semi,
    #[regex(r"[a-zA-Z_][a-zA-Z0-9_]*")]
    Ident,
    #[token("(")]
    LParen,
    #[token(")")]
    RParen,
    #[token("{")]
    LBrace,
    #[token("}")]
    RBrace,
    Error,
}
