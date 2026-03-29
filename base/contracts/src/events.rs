//! Typed CosmWasm events for indexers — keep attribute keys stable.

use cosmwasm_std::{Attribute, Response};

/// Namespace prefix for this contract's events.
pub const EVENT_NAMESPACE: &str = "rice/contract";

/// Example: emit after successful instantiate.
pub fn emit_instantiated(response: Response, admin: Option<&str>) -> Response {
    let mut attrs = vec![Attribute::new("action", format!("{EVENT_NAMESPACE}/instantiated"))];
    if let Some(a) = admin {
        attrs.push(Attribute::new("admin", a));
    }
    response.add_event(cosmwasm_std::Event::new("wasm-rice-contract").add_attributes(attrs))
}
