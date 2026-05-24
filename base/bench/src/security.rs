//! Rust security hooks in [`util`] (`zig-warden`) + optional Zig subprocess.

use criterion::{Criterion, black_box};

use crate::BenchRow;
#[cfg(all(feature = "zig-security-bench", unix))]
use crate::smoke_ns;

pub fn smoke_rows() -> Vec<BenchRow> {
    let mut rows = Vec::new();
    #[cfg(all(feature = "zig-security-bench", unix))]
    {
        let ns = smoke_ns(|| {
            let _ = black_box(util::warden::check_leverage_limit(10, 4096, 100, 1_000_000));
        });
        rows.push(BenchRow {
            module: "util/warden",
            scenario: "check_leverage_limit",
            ns,
            notes: format!("ok={}", util::warden::check_leverage_limit(10, 4096, 100, 1_000_000)),
        });
        let ns_stress = smoke_ns(|| {
            let _ = black_box(util::stress::run_security_stress_test());
        });
        rows.push(BenchRow {
            module: "util/stress",
            scenario: "run_security_stress_test",
            ns: ns_stress,
            notes: "Zig security_stress_test (0=pass)".into(),
        });
    }
    #[cfg(not(all(feature = "zig-security-bench", unix)))]
    {
        rows.push(BenchRow {
            module: "util/security",
            scenario: "warden_stress",
            ns: 0,
            notes: "skipped: --features zig-security-bench + libclerk-security.a (see base/ZIG_WARDEN.md)".into(),
        });
    }
    let zig_ns = smoke_zig_smoke();
    rows.push(BenchRow {
        module: "security/zig",
        scenario: "zig_build_knobs",
        ns: zig_ns.0,
        notes: zig_ns.1,
    });
    rows
}

fn smoke_zig_smoke() -> (u64, String) {
    if std::env::var("CLERK_BENCH_RUN_ZIG").ok().as_deref() != Some("1") {
        return (
            0,
            "skip: set CLERK_BENCH_RUN_ZIG=1 to run `zig build test` from base/ (slow)".into(),
        );
    }
    let root = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("..");
    let zig_dir = root.join("security");
    if !zig_dir.join("src/root.zig").exists() {
        return (0, "skip: base/security not present".into());
    }
    let t = std::time::Instant::now();
    let out = std::process::Command::new("zig")
        .args(["build", "test", "-Doptimize=Debug"])
        .current_dir(&root)
        .output();
    let ns = t.elapsed().as_nanos() as u64;
    match out {
        Ok(o) if o.status.success() => (ns, "zig build test ok (full security suite)".into()),
        Ok(o) => (ns, format!("zig failed status={}; stderr_len={}", o.status, o.stderr.len())),
        Err(e) => (ns, format!("zig spawn skipped: {e}")),
    }
}

pub fn register(c: &mut Criterion) {
    let mut g = c.benchmark_group("security");
    #[cfg(all(feature = "zig-security-bench", unix))]
    g.bench_function("warden_check", |b| {
        b.iter(|| {
            black_box(util::warden::check_leverage_limit(
                black_box(10usize),
                4096,
                black_box(100i64),
                1_000_000,
            ));
        });
    });
    #[cfg(not(all(feature = "zig-security-bench", unix)))]
    g.bench_function("warden_check", |b| b.iter(|| black_box(false)));
    g.finish();
}
