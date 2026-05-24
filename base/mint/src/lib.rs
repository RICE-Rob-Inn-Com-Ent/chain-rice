//! Universal `.rice` language toolkit — lexer (`logos`), parser (`chumsky`), CST (`rowan`), incremental queries (`salsa`).

// TODO(mint):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
// [ ] https://docs.rs/logos/ https://docs.rs/chumsky/ https://docs.rs/rowan/ https://docs.rs/salsa/
// [ ] pub mod lexer..lsp, error; export Lexer, Parser, AstNode, Codegen, Database; features lsp, parallel

pub mod ast;
pub mod base_abi;
pub mod check;
pub mod codegen;
pub mod db;
pub mod diagnostic;
pub mod error;
pub mod graph;
pub mod lexer;
pub mod chief_rice_parse;
pub mod docker_rice;
pub mod docs_rice;
pub mod frontend_rice;
pub mod infra_rice;
pub mod server_rice;
pub mod k8s_rice;
pub mod terraform_rice;
pub mod mason;
pub mod overlay;
pub mod mirror;
pub mod prepare;
pub mod lower;
pub mod lsp;
pub mod rice_infra_fmt;
pub mod rice_lsp;
pub mod parser;
pub mod query;
pub mod syntax;
pub mod token;

pub use db::{Db, Database};

#[cfg(test)]
mod tests {
    use crate::ast::root_node;
    use crate::codegen::render_role_stub;
    use crate::graph::{has_cycle, ModuleGraph};
    use crate::parser::parse_idents;
    use crate::syntax::green_minimal_root;

    #[test]
    fn lexer_and_salsa_smoke() {
        let db = crate::Database::default();
        let file = crate::query::SourceFile::new(
            &db,
            "test.rice".to_string(),
            "fn main {}".to_string(),
        );
        assert!(crate::query::token_count(&db, file) > 0);
        let _ = crate::lower::lower_stub(&db, file);
    }

    #[test]
    fn rowan_green_and_chumsky() {
        let _ = root_node(green_minimal_root());
        assert_eq!(parse_idents("a b c").unwrap(), vec!["a", "b", "c"]);
    }

    #[test]
    fn codegen_and_graph() {
        assert!(render_role_stub("CLERK").unwrap().contains("CLERK"));
        let mut g: ModuleGraph = ModuleGraph::new();
        let a = g.add_node("a".into());
        let b = g.add_node("b".into());
        g.add_edge(a, b, ());
        assert!(!has_cycle(&g));
    }

    #[test]
    fn base_abi_resolve_smoke() {
        assert_eq!(
            crate::base_abi::resolve("Error"),
            Some("util::Error")
        );
        assert_eq!(crate::base_abi::resolve("nope"), None);
    }

    #[test]
    fn overlay_line_tokens_smoke() {
        use crate::parser::tokenize_overlay_line;
        use crate::token::Token;
        let t = tokenize_overlay_line(r#"let rice_domain = "x.y""#);
        assert!(t.iter().any(|x| matches!(x, Token::KwLet)));
        assert!(t.iter().any(|x| matches!(x, Token::Eq)));
        assert!(t.iter().any(|x| matches!(x, Token::StrLit(s) if s == "x.y")));
    }
}
