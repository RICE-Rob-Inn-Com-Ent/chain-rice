//! CEL compile + evaluate ([`policies::engine`]).

use criterion::{Criterion, black_box};

use crate::{BenchRow, smoke_ns};

const CEL: &str = "1 + 2 * 3";

pub fn smoke_rows() -> Vec<BenchRow> {
    let mut rows = Vec::new();
    let ns_compile = smoke_ns(|| {
        let _ = black_box(policies::engine::compile(CEL));
    });
    let prog = policies::engine::compile(CEL).expect("cel");
    let ns_eval = smoke_ns(|| {
        let ctx = policies::engine::root_context();
        let _ = black_box(policies::engine::evaluate(&prog, &ctx));
    });
    rows.push(BenchRow {
        module: "policies/engine",
        scenario: "compile",
        ns: ns_compile,
        notes: format!("expr_len={}", CEL.len()),
    });
    rows.push(BenchRow {
        module: "policies/engine",
        scenario: "evaluate",
        ns: ns_eval,
        notes: "root_context + evaluate".into(),
    });
    rows
}

pub fn register(c: &mut Criterion) {
    let mut g = c.benchmark_group("policies");
    g.bench_function("cel_compile", |b| {
        b.iter(|| black_box(policies::engine::compile(black_box(CEL)).unwrap()));
    });
    let prog = policies::engine::compile(CEL).unwrap();
    g.bench_function("cel_evaluate", |b| {
        b.iter(|| {
            let ctx = policies::engine::root_context();
            let _ = black_box(policies::engine::evaluate(black_box(&prog), &ctx));
        });
    });
    g.finish();
}
