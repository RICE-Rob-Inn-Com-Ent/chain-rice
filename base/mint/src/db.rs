//! Incremental compiler database — `salsa` storage and [`salsa::Database`] impl.

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
