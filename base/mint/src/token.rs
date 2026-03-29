//! Token kinds for `.rice` — `logos` lexer.

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
