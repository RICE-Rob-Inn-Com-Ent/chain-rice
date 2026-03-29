//! Shared helpers for `base/` crates — errors, protobuf (`prost`), property testing, byte views.
//!
//! Wire `gen/` protobuf types from MASON through [`proto`] helpers; use [`prop`] for strategies
//! aligned with domain types in contracts, private, mint, and policies.

pub mod bytes;
pub mod error;
pub mod prop;
pub mod proto;
pub mod result;

pub use error::{RiceError, RiceResult};
pub use result::ResultExt;

/// Return [`Err(RiceError::Message)`](RiceError::Message) from the surrounding function.
#[macro_export]
macro_rules! bail {
    ($($arg:tt)*) => {
        return Err($crate::error::RiceError::message(format!($($arg)*)))
    };
}

/// Return [`Err`] if the condition is false.
#[macro_export]
macro_rules! ensure {
    ($cond:expr, $($arg:tt)*) => {
        if !$cond {
            return Err($crate::error::RiceError::message(format!($($arg)*)));
        }
    };
}
