//! Typed AST views — thin wrappers over `rowan` cursors.

use rowan::{SyntaxNode, SyntaxToken};

use crate::syntax::RiceLanguage;

pub type RiceNode = SyntaxNode<RiceLanguage>;
pub type RiceToken = SyntaxToken<RiceLanguage>;

/// Build a syntax tree root from a finished green node.
pub fn root_node(green: rowan::GreenNode) -> RiceNode {
    SyntaxNode::new_root(green)
}
