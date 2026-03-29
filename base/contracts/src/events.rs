//! Typed CosmWasm events for indexers — keep attribute keys stable.

use cosmwasm_std::{Attribute, Response};

// [ ] https://docs.cosmwasm.com/
// [ ] constructors: transfer, mint, burn, policy_set, proof_verified, proof_failed — event type keys from consts / cue
// [ ] attributes: block_height, contract_addr, timestamp via Env
// [ ] stable event names for indexers — no inline string duplication

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
