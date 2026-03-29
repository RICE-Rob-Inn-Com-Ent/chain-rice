//! `.rice` compiler passes — lexer, parser, codegen, incremental Salsa query.
use criterion::{black_box, Criterion};
use rice_mint::codegen::render_role_stub;
use rice_mint::lexer::lex_all;
use rice_mint::parser::parse_idents;
use rice_mint::query::{token_count, SourceFile};
use rice_mint::RiceDatabase;

// [ ] https://docs.rs/criterion/ — logos, chumsky, salsa
// [ ] lex, parse, check, lower, codegen targets; incremental salsa

pub fn register(c: &mut Criterion) {
    let src: String = "fn main { a b c } x ".repeat(64);
    let db = RiceDatabase::default();
    let file = SourceFile::new(&db, "bench.rice".into(), src.clone());

    let mut g = c.benchmark_group("compiler");
    g.bench_function("lexer_lex_all", |b| {
        b.iter(|| lex_all(black_box(src.as_str())))
    });
    g.bench_function("parser_parse_idents", |b| {
        b.iter(|| parse_idents(black_box("a b c d e f g h i j")))
    });
    g.bench_function("codegen_render_role_stub", |b| {
        b.iter(|| render_role_stub(black_box("CLERK")).unwrap())
    });
    g.bench_function("salsa_token_count", |b| {
        b.iter(|| token_count(&db, file))
    });
    g.finish();
}
