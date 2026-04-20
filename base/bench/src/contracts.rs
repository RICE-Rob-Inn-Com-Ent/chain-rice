//! CosmWasm [`contract::crypto`] hot paths.

use criterion::{Criterion, black_box};

use crate::{BenchRow, smoke_ns};

pub fn smoke_rows() -> Vec<BenchRow> {
    let data = b"rice-clerk-contract-smoke";
    let ns = smoke_ns(|| {
        let _ = black_box(contract::crypto::sha256_digest(data));
    });
    let digest = contract::crypto::sha256_digest(data);
    vec![BenchRow {
        module: "contract/crypto",
        scenario: "sha256_digest",
        ns,
        notes: format!("digest0={:02x}", digest[0]),
    }]
}

pub fn register(c: &mut Criterion) {
    let mut g = c.benchmark_group("contracts");
    let data = b"rice-clerk-contract-bench";
    g.bench_function("sha256_digest", |b| {
        b.iter(|| black_box(contract::crypto::sha256_digest(black_box(data))));
    });
    g.finish();
}
