//! Criterion driver + **`--json-smoke`** for LSP / CI snapshots.

use criterion::Criterion;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.iter().any(|a| a == "--json-smoke") {
        println!("{}", bench::run_smoke_json());
        return;
    }

    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let mut c = Criterion::default().configure_from_args();
    bench::calc::register(&mut c);
    bench::contracts::register(&mut c);
    bench::rice_mint::register(&mut c);
    bench::policies::register(&mut c);
    bench::private::register(&mut c);
    bench::security::register(&mut c);
    bench::util_smoke::register(&mut c);
    c.final_summary();
}
