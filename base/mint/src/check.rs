//! Semantic analysis — type checking and name resolution (incremental via salsa).

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use crate::query::SourceFile;

// [ ] — proto/base/gen validation, petgraph imports, SMITH/SAGE/MASON role checks, Vec<Diagnostic>

pub fn check_file(db: &dyn crate::db::Db, file: SourceFile) -> Result<(), crate::error::TypeError> {
    let _ = crate::query::token_count(db, file);
    Ok(())
}
