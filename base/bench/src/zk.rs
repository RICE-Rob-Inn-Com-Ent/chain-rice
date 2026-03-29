//! Groth16 / BN254 — setup, prove, verify (dominant cost is proving).
use ark_bn254::Bn254;
use ark_ff::UniformRand;
use criterion::{black_box, Criterion};
use rice_private::field::FrBn254;
use rice_private::prove::prove_mul;
use rice_private::setup::trusted_setup;
use rice_private::verify::verify_mul;
use rand::rngs::StdRng;
use rand::SeedableRng;

pub fn register(c: &mut Criterion) {
    let mut rng = StdRng::from_seed([11u8; 32]);
    let (pk, vk) = trusted_setup::<Bn254, _>(&mut rng).expect("zk setup");
    let a = FrBn254::rand(&mut rng);
    let b = FrBn254::rand(&mut rng);
    let mut public = a;
    public *= b;
    let proof = prove_mul(&pk, a, b, &mut rng).expect("prove");

    let mut g = c.benchmark_group("zk");
    g.bench_function("groth16_setup_bn254", |b| {
        let mut seed: u64 = 0;
        b.iter(|| {
            seed = seed.wrapping_add(1);
            let mut r = StdRng::seed_from_u64(seed);
            tracing::info_span!("zk.setup").in_scope(|| trusted_setup::<Bn254, _>(&mut r).unwrap())
        })
    });
    g.bench_function("groth16_prove_mul", |b| {
        let mut r = StdRng::from_seed([33u8; 32]);
        b.iter(|| {
            let a = FrBn254::rand(&mut r);
            let b = FrBn254::rand(&mut r);
            tracing::info_span!("zk.prove").in_scope(|| {
                prove_mul(black_box(&pk), a, b, &mut r).unwrap()
            })
        })
    });
    g.bench_function("groth16_verify_mul", |b| {
        b.iter(|| {
            tracing::info_span!("zk.verify").in_scope(|| {
                verify_mul(black_box(&vk), public, black_box(&proof)).unwrap()
            })
        })
    });
    g.finish();
}
