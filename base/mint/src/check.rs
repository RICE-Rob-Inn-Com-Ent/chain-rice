//! Semantic analysis — type checking and name resolution (incremental via salsa).

use crate::query::SourceFile;

// [ ] — proto/base/gen validation, petgraph imports, SMITH/SAGE/MASON role checks, Vec<Diagnostic>

pub fn check_file(db: &dyn crate::db::Db, file: SourceFile) -> Result<(), crate::error::TypeError> {
    let _ = crate::query::token_count(db, file);
    Ok(())
}
