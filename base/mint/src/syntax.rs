//! Lossless syntax layer — `rowan` [`RowanLanguage`], [`RowanSyntaxKind`](rowan::SyntaxKind) mapping, green tree builders.

// TODO(mint):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use rowan::{
    GreenNode, GreenNodeBuilder, Language as RowanLanguage, SyntaxKind as RowanSyntaxKind,
};

// [ ] https://docs.rs/rowan/
// [ ] typed SyntaxNode wrappers; incremental reparsing; lossless round-trip

/// `.rice` language marker for typed [`rowan::SyntaxNode`] / [`rowan::SyntaxToken`].
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct CstLanguage;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
#[repr(u16)]
pub enum CstSyntaxKind {
    Root = 0,
    SourceFile = 1,
    Whitespace = 2,
    FnKw = 3,
    Ident = 4,
    Error = 5,
}

impl From<CstSyntaxKind> for RowanSyntaxKind {
    fn from(kind: CstSyntaxKind) -> Self {
        RowanSyntaxKind(kind as u16)
    }
}

impl RowanLanguage for CstLanguage {
    type Kind = CstSyntaxKind;

    fn kind_from_raw(raw: RowanSyntaxKind) -> Self::Kind {
        match raw.0 {
            0 => CstSyntaxKind::Root,
            1 => CstSyntaxKind::SourceFile,
            2 => CstSyntaxKind::Whitespace,
            3 => CstSyntaxKind::FnKw,
            4 => CstSyntaxKind::Ident,
            _ => CstSyntaxKind::Error,
        }
    }

    fn kind_to_raw(kind: Self::Kind) -> RowanSyntaxKind {
        RowanSyntaxKind(kind as u16)
    }
}

/// Minimal green tree for plumbing tests — extend with real CST from `parser`.
pub fn green_minimal_root() -> GreenNode {
    let mut b = GreenNodeBuilder::new();
    b.start_node(CstSyntaxKind::Root.into());
    b.token(CstSyntaxKind::Ident.into(), "placeholder");
    b.finish_node();
    b.finish()
}
