//! Source → token stream with byte spans (for diagnostics and parser).

use logos::Logos;

use crate::token::Token;

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
