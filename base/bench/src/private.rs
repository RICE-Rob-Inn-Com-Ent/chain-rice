//! ZK public surface — env + field ops (no full Groth16 in smoke).

use criterion::{Criterion, black_box};

use crate::{BenchRow, smoke_ns};

pub fn smoke_rows() -> Vec<BenchRow> {
    let ns_env = smoke_ns(|| {
        let _ = black_box(private::rice_zk_environment());
    });
    let ns_field = smoke_ns(|| {
        let x = private::FrBn254::from(42u64);
        let _ = black_box(x);
    });
    vec![
        BenchRow {
            module: "private",
            scenario: "rice_zk_environment",
            ns: ns_env,
            notes: "RiceZkEnvironment probe".into(),
        },
        BenchRow {
            module: "private",
            scenario: "FrBn254_from_u64",
            ns: ns_field,
            notes: "field scalar construction".into(),
        },
    ]
}

pub fn register(c: &mut Criterion) {
    let mut g = c.benchmark_group("private");
    g.bench_function("rice_zk_environment", |b| {
        b.iter(|| black_box(private::rice_zk_environment()));
    });
    g.bench_function("FrBn254_from_u64", |b| {
        b.iter(|| black_box(private::FrBn254::from(black_box(42u64))));
    });
    g.finish();
}
