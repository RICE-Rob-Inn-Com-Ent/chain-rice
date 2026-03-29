//! RICE CosmWasm contract — Sylvia entry points, cw-storage-plus, domain modules.
//!
//! Layout: `contract` wires Sylvia; `execute` / `query` / `migration` hold logic; `msg` exposes
//! generated API + response DTOs; `state` / `types` / `crypto` / `events` / `error` are support layers.

// [ ] https://docs.cosmwasm.com/ — https://cosmwasm.github.io/sylvia/
// [ ] pub mod for contract, crypto, error, events, execute, migration, msg, query, state, tests, types
// [ ] cosmwasm_std::entry_point — instantiate, execute, query, migrate, sudo when not feature "library"
// [ ] export public API for rlib: CONTRACT_NAME, types::*, msg::* — names from env/cargo, not literals in code

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
pub mod events;
pub mod execute;
pub mod migration;
pub mod msg;
pub mod query;
pub mod state;
#[cfg(test)]
mod tests;
pub mod types;

pub use contract::Contract;
