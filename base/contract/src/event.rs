//! Typed CosmWasm events for `.rice` runtime telemetry — stable **`snake_case`** attribute keys for indexers.
//!
//! Builders return [`Event`] values only; handlers attach them to [`Response`] in `execute.rs` / `migration.rs`.

use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Attribute, Event, Response, Uint128};

use crate::r#type::IdentityPrincipal;

/// Namespace prefix for `action` attributes (`{EVENT_NAMESPACE}/…`).
pub const EVENT_NAMESPACE: &str = "rice/contract";

/// Wasm event type — single CosmWasm event name; discrimination via `action` attribute.
pub const WASM_EVENT_TYPE: &str = "wasm-rice-contract";

// --- Intent telemetry ----------------------------------------------------------

/// High-level outcome of an intent execution (wire / indexer vocabulary).
#[cw_serde]
pub enum IntentStatus {
    #[serde(rename = "success")]
    Success,
    #[serde(rename = "failure")]
    Failure,
}

impl IntentStatus {
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Success => "success",
            Self::Failure => "failure",
        }
    }
}

/// Payload for an intent lifecycle signal (`action`: `{EVENT_NAMESPACE}/intent`).
#[derive(Debug, Clone)]
pub struct EventIntent {
    pub trace_id: String,
    pub actor: IdentityPrincipal,
    pub status: IntentStatus,
    pub gas_used: u64,
}

impl EventIntent {
    /// Build the CosmWasm [`Event`] (does not mutate [`Response`]).
    #[must_use]
    pub fn into_event(self) -> Event {
        Event::new(WASM_EVENT_TYPE).add_attributes([
            Attribute::new("action", format!("{EVENT_NAMESPACE}/intent")),
            Attribute::new("trace_id", self.trace_id),
            Attribute::new("actor", identity_principal_wire(&self.actor)),
            Attribute::new("status", self.status.as_str()),
            Attribute::new("gas_used", self.gas_used.to_string()),
        ])
    }
}

// --- Config telemetry ----------------------------------------------------------

/// Payload for configuration-related signals (`action`: `{EVENT_NAMESPACE}/config`).
#[derive(Debug, Clone)]
pub struct EventConfig {
    pub admin: String,
    /// Policy engine address, or empty string when unset.
    pub policy_engine: String,
    /// Comma-separated feature tags (e.g. `zk`, `pq`, `pause`) for indexers.
    pub features_active: String,
}

impl EventConfig {
    #[must_use]
    pub fn into_event(self) -> Event {
        Event::new(WASM_EVENT_TYPE).add_attributes([
            Attribute::new("action", format!("{EVENT_NAMESPACE}/config")),
            Attribute::new("admin", self.admin),
            Attribute::new("policy_engine", self.policy_engine),
            Attribute::new("features_active", self.features_active),
        ])
    }
}

// --- Balance telemetry ---------------------------------------------------------

/// Ledger adjustment direction (matches execute `manage_balance` vocabulary).
#[cw_serde]
pub enum BalanceDirection {
    #[serde(rename = "credit")]
    Credit,
    #[serde(rename = "debit")]
    Debit,
}

impl BalanceDirection {
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Credit => "credit",
            Self::Debit => "debit",
        }
    }
}

/// Payload for balance adjustments (`action`: `{EVENT_NAMESPACE}/balance`).
#[derive(Debug, Clone)]
pub struct EventBalance {
    pub principal: IdentityPrincipal,
    pub amount_change: Uint128,
    pub direction: BalanceDirection,
}

impl EventBalance {
    #[must_use]
    pub fn into_event(self) -> Event {
        Event::new(WASM_EVENT_TYPE).add_attributes([
            Attribute::new("action", format!("{EVENT_NAMESPACE}/balance")),
            Attribute::new("principal", identity_principal_wire(&self.principal)),
            Attribute::new("amount_change", self.amount_change.to_string()),
            Attribute::new("direction", self.direction.as_str()),
        ])
    }
}

// --- Wire helpers (no storage, no handler side effects) ------------------------

fn identity_principal_wire(p: &IdentityPrincipal) -> String {
    serde_json::to_string(p).unwrap_or_else(|_| "{}".to_string())
}

// --- Migration telemetry -------------------------------------------------------

/// Successful schema / cw2 evolution (`action`: `{EVENT_NAMESPACE}/migrated`).
#[must_use]
pub fn migrated_event(schema_version: u64) -> Event {
    Event::new(WASM_EVENT_TYPE).add_attributes([
        Attribute::new("action", format!("{EVENT_NAMESPACE}/migrated")),
        Attribute::new("schema_version", schema_version.to_string()),
        Attribute::new("cw2_version", env!("CARGO_PKG_VERSION")),
    ])
}

// --- Legacy / bootstrap -------------------------------------------------------

/// Attach an `instantiated` action (minimal bootstrap; prefer [`EventConfig`] for full config dumps).
pub fn emit_instantiated(response: Response, admin: Option<&str>) -> Response {
    let mut e = Event::new(WASM_EVENT_TYPE).add_attribute("action", format!("{EVENT_NAMESPACE}/instantiated"));
    if let Some(a) = admin {
        e = e.add_attribute("admin", a);
    }
    response.add_event(e)
}
