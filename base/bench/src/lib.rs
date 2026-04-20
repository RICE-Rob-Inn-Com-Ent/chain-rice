//! CLERK **`bench`** — Criterion harness + **JSON smoke** timings for `.rice` / LSP (`--json-smoke`).
//!
//! Run full Criterion: `cargo bench -p bench`. Quick snapshot: `cargo run -p bench -- --json-smoke`.
//! Optional native stacks: `--features full-native-benches` (Haskell CALC + Zig static lib paths).
//!
//! **`rice-lsp` (feature `lsp-perf`)** runs this binary with `--json-smoke` (subprocess). Set **`RICE_BENCH_BIN`**
//! to the `bench` executable, or build with `cargo build -p bench` so **`target/{debug,release}/bench`**
//! exists under a workspace ancestor. Optional save refresh: env **`RICE_LSP_PERF=1`**, command **`rice.refreshBasePerf`**.

use serde::Serialize;

#[path = "mint.rs"]
pub mod rice_mint;

pub mod calc;
pub mod contracts;
pub mod policies;
pub mod private;
pub mod security;
#[path = "util.rs"]
pub mod util_smoke;

/// One measured scenario (nanoseconds per iteration for smoke; Criterion reports separately).
#[derive(Clone, Serialize)]
pub struct BenchRow {
    pub module: &'static str,
    pub scenario: &'static str,
    pub ns: u64,
    pub notes: String,
}

/// Aggregate JSON for LSP / tooling (`rice-lsp` subprocess).
#[derive(Serialize)]
pub struct BenchSnapshot {
    pub rows: Vec<BenchRow>,
}

fn time_ns(f: impl FnOnce()) -> u64 {
    let t = std::time::Instant::now();
    f();
    t.elapsed().as_nanos() as u64
}

/// Fast smoke timings across `base/` crates (no Criterion harness overhead).
pub fn run_smoke_json() -> String {
    let mut rows: Vec<BenchRow> = Vec::new();
    rows.extend(calc::smoke_rows());
    rows.extend(contracts::smoke_rows());
    rows.extend(rice_mint::smoke_rows());
    rows.extend(policies::smoke_rows());
    rows.extend(private::smoke_rows());
    rows.extend(security::smoke_rows());
    rows.extend(util_smoke::smoke_rows());
    serde_json::to_string_pretty(&BenchSnapshot { rows }).unwrap_or_else(|_| "{}".to_string())
}

/// Nanoseconds for a single smoke closure (for tests / embedding).
pub fn smoke_ns(f: impl FnOnce()) -> u64 {
    time_ns(f)
}
