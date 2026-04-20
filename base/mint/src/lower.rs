//! AST → HIR lowering — desugaring and normalization (tracked for reuse).

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use crate::query::SourceFile;

// [ ] https://docs.rs/salsa/
// [ ] AST→IR; validation; symbol resolution

#[salsa::tracked]
pub fn lower_stub(db: &dyn crate::db::Db, file: SourceFile) -> String {
    format!("hir_tokens={}", crate::query::token_count(db, file))
}
