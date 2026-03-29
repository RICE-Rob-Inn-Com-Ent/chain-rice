//! Criterion entry point — configures sample size, measurement window, and HTML reports (`cargo bench`).
//!
//! Tracing is initialized once; each module registers a benchmark group.

use std::time::Duration;

use criterion::Criterion;

mod compiler;
mod contracts;
mod crypto;
mod policies;
mod zk;

fn main() {
    let _ = tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .try_init();

    let mut c = Criterion::default()
        .sample_size(50)
        .warm_up_time(Duration::from_secs(1))
        .measurement_time(Duration::from_secs(5))
        .configure_from_args();

    contracts::register(&mut c);
    zk::register(&mut c);
    compiler::register(&mut c);
    policies::register(&mut c);
    crypto::register(&mut c);

    c.final_summary();
}
