//! AST → HIR lowering — desugaring and normalization (tracked for reuse).

use crate::query::SourceFile;

// [ ] https://docs.rs/salsa/
// [ ] AST→IR; validation; symbol resolution

#[salsa::tracked]
pub fn lower_stub(db: &dyn crate::db::Db, file: SourceFile) -> String {
    format!("hir_tokens={}", crate::query::token_count(db, file))
}
