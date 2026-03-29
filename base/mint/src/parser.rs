//! `chumsky` parser — builds a flat list of identifiers (placeholder until CST bridge).

use chumsky::prelude::*;

/// Parse whitespace-separated identifiers until end of input.
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
