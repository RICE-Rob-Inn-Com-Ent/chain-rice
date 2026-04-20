//! Typed AST views — thin wrappers over `rowan` cursors.

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use rowan::{SyntaxNode, SyntaxToken};

use crate::syntax::RiceLanguage;

// [ ] https://docs.rs/rowan/
// [ ] AST nodes for all constructs; visitor; pretty print; salsa hash

pub type RiceNode = SyntaxNode<RiceLanguage>;
pub type RiceToken = SyntaxToken<RiceLanguage>;

/// Build a syntax tree root from a finished green node.
pub fn root_node(green: rowan::GreenNode) -> RiceNode {
    SyntaxNode::new_root(green)
}
