//! Lossless syntax layer — `rowan` [`Language`], [`SyntaxKind`](rowan::SyntaxKind) mapping, green tree builders.

use rowan::{GreenNode, GreenNodeBuilder, Language, SyntaxKind};

/// `.rice` language marker for typed [`rowan::SyntaxNode`] / [`rowan::SyntaxToken`].
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct RiceLanguage;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
#[repr(u16)]
pub enum RiceSyntaxKind {
    Root = 0,
    SourceFile = 1,
    Whitespace = 2,
    FnKw = 3,
    Ident = 4,
    Error = 5,
}

impl From<RiceSyntaxKind> for SyntaxKind {
    fn from(k: RiceSyntaxKind) -> SyntaxKind {
        SyntaxKind(k as u16)
    }
}

impl Language for RiceLanguage {
    type Kind = RiceSyntaxKind;

    fn kind_from_raw(raw: SyntaxKind) -> Self::Kind {
        match raw.0 {
            0 => RiceSyntaxKind::Root,
            1 => RiceSyntaxKind::SourceFile,
            2 => RiceSyntaxKind::Whitespace,
            3 => RiceSyntaxKind::FnKw,
            4 => RiceSyntaxKind::Ident,
            _ => RiceSyntaxKind::Error,
        }
    }

    fn kind_to_raw(kind: Self::Kind) -> SyntaxKind {
        SyntaxKind(kind as u16)
    }
}

/// Minimal green tree for plumbing tests — extend with real CST from `parser`.
pub fn green_minimal_root() -> GreenNode {
    let mut b = GreenNodeBuilder::new();
    b.start_node(RiceSyntaxKind::Root.into());
    b.token(RiceSyntaxKind::Ident.into(), "placeholder");
    b.finish_node();
    b.finish()
}
