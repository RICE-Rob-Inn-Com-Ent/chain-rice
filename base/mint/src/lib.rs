//! RICE `.rice` compiler — lexer (`logos`), parser (`chumsky`), CST (`rowan`), incremental queries (`salsa`).

// [ ] https://docs.rs/logos/ https://docs.rs/chumsky/ https://docs.rs/rowan/ https://docs.rs/salsa/
// [ ] pub mod lexer..lsp, error; export Lexer, Parser, AstNode, Codegen, Database; features lsp, parallel

pub mod ast;
pub mod check;
pub mod codegen;
pub mod db;
pub mod diagnostic;
pub mod error;
pub mod graph;
pub mod lexer;
pub mod lower;
pub mod lsp;
pub mod parser;
pub mod query;
pub mod syntax;
pub mod token;

pub use db::{Db, RiceDatabase};

#[cfg(test)]
mod tests {
    use crate::ast::root_node;
    use crate::codegen::render_role_stub;
    use crate::graph::{has_cycle, ModuleGraph};
    use crate::parser::parse_idents;
    use crate::syntax::green_minimal_root;

    #[test]
    fn lexer_and_salsa_smoke() {
        let db = crate::RiceDatabase::default();
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
}
