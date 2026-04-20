//! **`.rice` runtime** — sovereign, intent-based CosmWasm virtual machine.
//!
//! This crate is the core library for the `.rice` language runtime: a contract shell that accepts
//! signed intents, records proof traces, administers balances, and exposes configuration with
//! optional **zero-knowledge (ZK)** and **post-quantum (PQ)** capability flags for policy and
//! verification pipelines.
//!
//! ## Layout
//!
//! | Module | Role |
//! |--------|------|
//! | [`contract`] | Sylvia contract type and generated entry messages |
//! | [`execute`] | Instantiate, intent execution, balance, config mutations |
//! | [`query`] | Read-only config, balances, trace status |
//! | [`migration`] | Versioned schema / cw2 evolution |
//! | [`msg`] | Public wire API (re-exports generated `*Msg` types) |
//! | [`state`] | Storage keys and maps |
//! | `r#type` | Domain types (`ContractConfig`, principals, amounts, proof status); the `type` keyword is escaped as `r#type` in Rust source |
//! | [`crypto`] | Hashing, signatures, optional PQ hooks |
//! | [`event`] | Typed CosmWasm events for indexers |
//! | [`error`] | [`ContractError`] for all handler surfaces |
//!
//! Integration tests and `cw-multi-test` simulation live in the `test` module (`src/test.rs`, `cfg(test)` only).

#[cfg(target_arch = "wasm32")]
mod wasm_getrandom {
    use getrandom::{register_custom_getrandom, Error};

    fn custom_getrandom(_buf: &mut [u8]) -> Result<(), Error> {
        Err(Error::UNSUPPORTED)
    }

    register_custom_getrandom!(custom_getrandom);
}

pub mod contract;
pub mod crypto;
pub mod error;
pub mod event;
pub mod execute;
pub mod migration;
pub mod msg;
pub mod query;
pub mod state;
pub mod r#type;

#[cfg(test)]
mod test;

pub use contract::Contract;
pub use error::ContractError;
