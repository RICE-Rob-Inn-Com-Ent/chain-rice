//! [`RiceResult`] helpers — extension traits for attaching context to failures.
use std::fmt::Display;

use crate::error::{RiceError, RiceResult};

/// Extension trait for [`RiceResult`] — map errors while preserving [`RiceError`] wrapping.
pub trait ResultExt<T> {
    /// Map the error with a prefix context string.
    fn with_context<C: Display>(self, ctx: C) -> RiceResult<T>;
}

impl<T> ResultExt<T> for RiceResult<T> {
    fn with_context<C: Display>(self, ctx: C) -> RiceResult<T> {
        self.map_err(|e| RiceError::message(format!("{ctx}: {e}")))
    }
}
