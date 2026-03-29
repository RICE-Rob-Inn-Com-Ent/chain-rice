//! AST → HIR lowering — desugaring and normalization (tracked for reuse).

use crate::query::SourceFile;

#[salsa::tracked]
pub fn lower_stub(db: &dyn crate::db::Db, file: SourceFile) -> String {
    format!("hir_tokens={}", crate::query::token_count(db, file))
}
