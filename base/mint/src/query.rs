//! Memoized compiler queries — inputs and tracked functions on [`crate::Db`](crate::Db).

// [ ] https://docs.rs/salsa/
// [ ] ParseQuery, CheckQuery, LowerQuery, CodegenQuery; cross-file; LSP queries hover/completion/defs/refs

#[salsa::input]
pub struct SourceFile {
    #[return_ref]
    pub path: String,
    #[return_ref]
    pub text: String,
}

#[salsa::tracked]
pub fn token_count(db: &dyn crate::db::Db, file: SourceFile) -> usize {
    crate::lexer::lex_all(file.text(db)).len()
}
