//! `.rice` compiler — lexer + salsa query (same shape as [`mint`] tests).

use criterion::{Criterion, black_box};

use crate::{BenchRow, smoke_ns};

pub fn smoke_rows() -> Vec<BenchRow> {
    let ns = smoke_ns(|| {
        let db = mint::RiceDatabase::default();
        let file = mint::query::SourceFile::new(&db, "bench.rice".to_string(), "fn main {}".to_string());
        let _ = black_box(mint::query::token_count(&db, file));
    });
    vec![BenchRow {
        module: "mint",
        scenario: "token_count_smoke",
        ns,
        notes: "RiceDatabase + SourceFile + query::token_count".into(),
    }]
}

pub fn register(c: &mut Criterion) {
    let mut g = c.benchmark_group("mint");
    g.bench_function("token_count", |b| {
        b.iter(|| {
            let db = mint::RiceDatabase::default();
            let file = mint::query::SourceFile::new(&db, "bench.rice".to_string(), black_box("fn main {}".to_string()));
            black_box(mint::query::token_count(&db, file));
        });
    });
    g.finish();
}
