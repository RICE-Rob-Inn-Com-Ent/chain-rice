#![deny(missing_docs)]
//! # CLERK `util` — peripheral nervous system of `.rice` `base/`
//!
//! ## Biological abstract
//!
//! This crate is the **gateway** through which other `base/` organs (contracts, private, mint,
//! policies) share a single dialect for buffers, wire encoding, failure taxonomy, and ergonomic
//! control flow. Think of it as **connective tissue**: it does not own domain law, but every
//! message that hurts should be felt the same way everywhere.
//!
//! ## How the modules relate
//!
//! - **[`bytes`] — circulation.** Raw octets move: hex transcription, [`Bytes`] views, padding and
//!   chunking for ZK-aligned layouts. Clean buffers feed the encoders and keep allocations honest.
//! - **[`proto`] — DNA sequencing.** [`prost::Message`] values become length-delimited **organism
//!   signals** for streaming (NATS, multiplexed readers). It consumes the byte vocabulary from
//!   [`bytes`] and returns [`Result`](crate::error::Result) when the genome does not parse.
//! - **[`error`] — pain.** [`Error`](crate::error::Error) is the shared nerve signal: crypto, policy, contract,
//!   finance, protocol, I/O, and context chains. Every variant documents *what went wrong* so
//!   operators route retries and alerts without guessing.
//! - **[`result`] — synapses.** Extension traits ([`ResultExt`], [`OptionExt`],
//!   [`BoolExt`]) attach context, classify failures, and guard options/bools without boilerplate
//!   `match`es everywhere. They translate foreign [`std::result::Result`]s into [`Result`](crate::error::Result) at crate boundaries.
//! - **[`prop`] — immune stress tests (optional).** [`proptest`] strategies and invariants live
//!   here when the **`test-utils`** feature is enabled (see below). They randomly probe [`bytes`]
//!   and [`proto`] so regressions surface before production load.
//!
//! ## Crate name and imports
//!
//! The package is named **`util`** in `Cargo.toml`. Downstream code typically uses
//! `use util::{Error, Result, ResultExt, …}` or a glob:
//!
//! ```rust,ignore
//! use util::{Error, Result, ResultExt, OptionExt, BoolExt};
//! ```
//!
//! A glob import pulls in the **reflex** traits so `.context()`, `.ok_or_policy()`, and friends
//! resolve on [`Result`](crate::error::Result) and [`Option`] without extra prelude boilerplate.
//!
//! ## Feature: `test-utils`
//!
//! **Why:** Property-based helpers pull in [`proptest`]. Embedders that only need errors, bytes, and
//! proto in **no_std-friendly or minimal dependency** graphs can disable default features.
//! **How:** Depend with `default-features = false` and omit `test-utils`. To reuse strategies from
//! sibling crates (e.g. `contract` tests), add:
//!
//! ```toml
//! [dev-dependencies]
//! util = { path = "../util", features = ["test-utils"] }
//! ```
//!
//! Then `use util::prop::{vec_bytes, arb_bytes, …}` inside `#[cfg(test)]` modules or integration
//! tests.
//!
//! ## Feature: `calc-bridge` (Unix native only)
//!
//! Optional **Haskell CALC** FFI: dlopens `libcalc_ffi.so` (path from `CLERK_CALC_LIB`), exposes
//! [`calc`](crate::calc) (in [`bridge`](crate::bridge)) for policy math on **native** targets. **Not for wasm32** — contracts keep
//! `Uint128` and pre-attested deltas. Initialise the RTS once per process; see [`calc`] module docs.
//!
//! ## Feature: `zig-warden` (Unix native only)
//!
//! Links the Zig static library **`libclerk-security.a`** from [`base/zig-out/lib/`](../zig-out/lib/)
//! after `zig build` in **`base/`**. [`warden`](crate::warden) and [`stress`](crate::stress) live under [`bridge`](crate::bridge)
//! (`warden_*` in [`security/src/warden.zig`](../../security/src/warden.zig); `security_stress_test` in
//! [`security/src/chaos.zig`](../../security/src/chaos.zig)).
//! Combine with **`calc-bridge`** to run warden checks and buffer wipe around Haskell CALC FFI.
//! See **`base/ZIG_WARDEN.md`** for CI.
//!
//! ## Public surface
//!
//! Prefer **`use util::{Error, Result, …}`** from this crate root. Core modules are `bytes` and `proto`;
//! native FFI (`calc`, `warden`, `stress`) is under [`bridge`](crate::bridge) and re-exported when features are on.

pub mod bytes;
/// Haskell CALC (`calc-bridge`) and Zig `clerk-security` (`zig-warden`) FFI — see submodules `calc`, `warden`, `stress`.
pub mod bridge;
#[cfg(all(feature = "calc-bridge", unix))]
pub use bridge::calc;
#[cfg(all(feature = "zig-warden", unix))]
pub use bridge::warden;
#[cfg(all(feature = "zig-warden", unix))]
pub use bridge::stress;
pub mod error;
pub mod proto;
pub mod result;

#[cfg(feature = "test-utils")]
pub mod prop;

pub use error::{Error, Result};
pub use result::{BoolExt, OptionExt, ResultExt};

// Re-export `bytes` crate types at `util` root so embedders use `util::Bytes` (not a second `bytes` dep).
pub use ::bytes::{Buf, BufMut, Bytes, BytesMut};

/// Return [`Err`](std::result::Result::Err) with [`Error::message`](Error::message) from the enclosing function.
///
/// **Why:** Early exit with a typed, displayable error without `?` on `Option` or manual `return Err`.
#[macro_export]
macro_rules! bail {
    ($($arg:tt)*) => {
        return Err($crate::error::Error::message(format!($($arg)*)))
    };
}

/// Return [`Err`](std::result::Result::Err) with [`Error::message`](Error::message) if the condition is false.
///
/// **Why:** Invariant checks read like guards; failures stay in the `Message` channel for generic preconditions.
#[macro_export]
macro_rules! ensure {
    ($cond:expr, $($arg:tt)*) => {
        if !$cond {
            return Err($crate::error::Error::message(format!($($arg)*)));
        }
    };
}
