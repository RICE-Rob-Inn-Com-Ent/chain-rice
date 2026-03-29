//! Chain simulation tests — extend with `cw-multi-test` + `sylvia::multitest` per Sylvia book.

#[test]
fn types_helpers_smoke() {
    let _ = crate::types::big_zero();
    assert_eq!(crate::crypto::sha256_digest(b"rice").len(), 32);
}
