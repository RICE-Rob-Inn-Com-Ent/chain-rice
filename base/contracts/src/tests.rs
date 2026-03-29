//! Chain simulation tests — extend with `cw-multi-test` + `sylvia::multitest` per Sylvia book.

// [ ] https://docs.cosmwasm.com/ — cw-multi-test, sylvia multitest
// [ ] App::new, store_code, instantiate — full happy paths
// [ ] transfer, mint, burn, policy, proof, query pagination, migrate, pause, pq feature-gated tests
// [ ] property tests — amounts, unauthorized paths

#[test]
fn types_helpers_smoke() {
    let _ = crate::types::big_zero();
    assert_eq!(crate::crypto::sha256_digest(b"rice").len(), 32);
}
