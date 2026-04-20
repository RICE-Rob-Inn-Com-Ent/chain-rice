//! CALC / Haskell path — [`util::calc`] behind **`calc-bench`**.

use criterion::{Criterion, black_box};

use crate::BenchRow;
#[cfg(all(feature = "calc-bench", unix))]
use crate::smoke_ns;

pub fn smoke_rows() -> Vec<BenchRow> {
    let mut rows = Vec::new();
    #[cfg(all(feature = "calc-bench", unix))]
    {
        let ns = smoke_ns(|| {
            let _ = black_box(util::calc::basis_points_fee_minor_units("1000", 100));
        });
        let notes = match util::calc::basis_points_fee_minor_units("1000", 100) {
            Ok(fee) => format!("ok fee_len={}", fee.len()),
            Err(e) => format!("skip: {e}"),
        };
        rows.push(BenchRow {
            module: "util/calc",
            scenario: "basis_points_fee_minor_units",
            ns,
            notes,
        });
        let _ = util::calc::shutdown();
    }
    #[cfg(not(all(feature = "calc-bench", unix)))]
    {
        rows.push(BenchRow {
            module: "util/calc",
            scenario: "basis_points_fee_minor_units",
            ns: 0,
            notes: "skipped: build with --features calc-bench on unix + RICE_CALC_LIB".into(),
        });
    }
    rows
}

pub fn register(c: &mut Criterion) {
    let mut g = c.benchmark_group("calc");
    #[cfg(all(feature = "calc-bench", unix))]
    g.bench_function("calc_bps_fee_json", |b| {
        b.iter(|| {
            let _ = black_box(util::calc::basis_points_fee_minor_units("1000", black_box(100)));
        });
    });
    #[cfg(not(all(feature = "calc-bench", unix)))]
    g.bench_function("calc_bps_fee_json", |b| b.iter(|| black_box(0u64)));
    g.finish();
}
