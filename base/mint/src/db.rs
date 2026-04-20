//! Incremental compiler database — `salsa` storage and [`salsa::Database`] impl.

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
// [ ] https://docs.rs/salsa/
// [ ] inputs SourceFile; tracked parse/check/lower/codegen; file watch; parallel queries

/// Super-trait for all `.rice` compiler databases (inputs + tracked queries).
#[salsa::db]
pub trait Db: salsa::Database {}

#[salsa::db]
#[derive(Clone, Default)]
pub struct RiceDatabase {
    storage: salsa::Storage<Self>,
}

#[salsa::db]
impl salsa::Database for RiceDatabase {
    fn salsa_event(&self, _event: &dyn Fn() -> salsa::Event) {}
}

#[salsa::db]
impl Db for RiceDatabase {}
