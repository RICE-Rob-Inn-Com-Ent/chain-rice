//! CosmWasm-facing hot paths: hashing and amount conversions (extend with `cw-multi-test` flows later).
use rice_contract::crypto::sha256_digest;
use rice_contract::types::uint128_to_decimal;
use cosmwasm_std::Uint128;
use criterion::{black_box, Criterion};

// [ ] https://docs.rs/criterion/ — https://docs.cosmwasm.com/
// [ ] transfer, mint, verify_proof, query_balance, query_all_balances, policy in contract

pub fn register(c: &mut Criterion) {
    let mut g = c.benchmark_group("contracts");
    g.bench_function("sha256_digest", |b| {
        b.iter(|| {
            sha256_digest(black_box(
                b"rice benchmark payload - instantiate/execute/query workloads",
            ))
        })
    });
    let amt = Uint128::from(987_654_321u128);
    g.bench_function("uint128_to_decimal", |b| {
        b.iter(|| uint128_to_decimal(black_box(amt)))
    });
    g.finish();
}
