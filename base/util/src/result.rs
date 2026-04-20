//! Fluent “synapse” helpers for [`RiceResult`] and related types — small, inlined adapters that
//! encode CLERK reflexes: attach context, classify failures, guard options, and emit structured
//! traces without allocating on the happy path.

use std::fmt::Display;

use tracing::Level;

use crate::error::{RiceError, RiceResult};

// ---------------------------------------------------------------------------
// Result → RiceResult
// ---------------------------------------------------------------------------

/// Extension for any [`Result`] whose error type converts into [`RiceError`].
///
/// **Reflex:** Downstream code speaks one dialect (`RiceResult`); these methods normalize foreign
/// errors at the boundary and preserve classification for retries and observability.
pub trait RiceResultExt<T, E> {
    /// Eagerly wrap a failure in [`RiceError::Context`], retaining the inner error as
    /// [`std::error::Error::source`].
    ///
    /// **Reflex:** `msg` is turned into a [`String`] only when this arm fires — the [`Ok`] path
    /// does not touch `msg`.
    fn context(self, msg: impl Into<String>) -> RiceResult<T>
    where
        E: Into<RiceError>;

    /// Lazily build context only if this [`Result`] is [`Err`].
    ///
    /// **Reflex:** `f` runs exclusively inside `map_err`; expensive diagnostics (IDs, counters)
    /// stay off the hot success path.
    fn with_context<F, M>(self, f: F) -> RiceResult<T>
    where
        E: Into<RiceError>,
        F: FnOnce() -> M,
        M: Into<String>;

    /// Map [`Err`] to [`RiceError::InvalidArgument`], preserving the original [`Display`] text.
    ///
    /// **Reflex:** Validation and shape errors stay typed as arguments while still carrying the
    /// upstream message for debugging.
    fn or_invalid_arg(self, msg: impl Into<String>) -> RiceResult<T>
    where
        E: Display;

    /// Map [`Err`] to [`RiceError::Policy`], preserving the original [`Display`] text.
    ///
    /// **Reflex:** The conscience layer receives a veto with both operator context (`msg`) and the
    /// underlying reason (`E`).
    fn or_policy(self, msg: impl Into<String>) -> RiceResult<T>
    where
        E: Display;

    /// Map [`Err`] to [`RiceError::Protocol`], preserving the original [`Display`] text.
    ///
    /// **Reflex:** Session or messaging rules failed; the error is labeled for transport-level
    /// handling distinct from raw I/O.
    fn or_protocol(self, msg: impl Into<String>) -> RiceResult<T>
    where
        E: Display;

    /// Log the error at `level` with `note`, then return the same [`RiceError`] unchanged.
    ///
    /// **Reflex:** Observability fires before the error propagates; structured logging keeps spans
    /// and field keys consistent across CLERK crates.
    fn log_err(self, level: Level, note: impl AsRef<str>) -> RiceResult<T>
    where
        E: Into<RiceError>;
}

impl<T, E> RiceResultExt<T, E> for Result<T, E> {
    #[inline]
    fn context(self, msg: impl Into<String>) -> RiceResult<T>
    where
        E: Into<RiceError>,
    {
        self.map_err(|e| Into::<RiceError>::into(e).context(msg.into()))
    }

    #[inline]
    fn with_context<F, M>(self, f: F) -> RiceResult<T>
    where
        E: Into<RiceError>,
        F: FnOnce() -> M,
        M: Into<String>,
    {
        self.map_err(|e| Into::<RiceError>::into(e).context(f()))
    }

    #[inline]
    fn or_invalid_arg(self, msg: impl Into<String>) -> RiceResult<T>
    where
        E: Display,
    {
        let head = msg.into();
        self.map_err(|e| RiceError::invalid_argument(format!("{head}: {e}")))
    }

    #[inline]
    fn or_policy(self, msg: impl Into<String>) -> RiceResult<T>
    where
        E: Display,
    {
        let head = msg.into();
        self.map_err(|e| RiceError::policy(format!("{head}: {e}")))
    }

    #[inline]
    fn or_protocol(self, msg: impl Into<String>) -> RiceResult<T>
    where
        E: Display,
    {
        let head = msg.into();
        self.map_err(|e| RiceError::protocol(format!("{head}: {e}")))
    }

    #[inline]
    fn log_err(self, level: Level, note: impl AsRef<str>) -> RiceResult<T>
    where
        E: Into<RiceError>,
    {
        match self {
            Ok(v) => Ok(v),
            Err(e) => {
                let err = Into::<RiceError>::into(e);
                log_rice(level, note.as_ref(), &err);
                Err(err)
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Option → RiceResult
// ---------------------------------------------------------------------------

/// Extension for [`Option`] values that must become definite [`RiceResult`] outcomes.
///
/// **Reflex:** `None` is not silent — it becomes a typed CLERK error so callers never unwrap.
pub trait RiceOptionExt<T> {
    /// Turn [`None`] into [`RiceError::InvalidArgument`] with `msg`.
    ///
    /// **Reflex:** Missing configuration or malformed optional input stops before crypto or finance.
    fn ok_or_invalid_arg(self, msg: impl Into<String>) -> RiceResult<T>;

    /// Turn [`None`] into [`RiceError::Policy`] with `msg`.
    ///
    /// **Reflex:** The rule set expected a value that was absent — treat as conscience refusal.
    fn ok_or_policy(self, msg: impl Into<String>) -> RiceResult<T>;

    /// Turn [`None`] into [`RiceError::Finance`] with `msg`.
    ///
    /// **Reflex:** Balances, postings, or mint paths found nothing where something material must
    /// exist.
    fn ok_or_finance(self, msg: impl Into<String>) -> RiceResult<T>;
}

impl<T> RiceOptionExt<T> for Option<T> {
    #[inline]
    fn ok_or_invalid_arg(self, msg: impl Into<String>) -> RiceResult<T> {
        self.ok_or_else(|| RiceError::invalid_argument(msg.into()))
    }

    #[inline]
    fn ok_or_policy(self, msg: impl Into<String>) -> RiceResult<T> {
        self.ok_or_else(|| RiceError::policy(msg.into()))
    }

    #[inline]
    fn ok_or_finance(self, msg: impl Into<String>) -> RiceResult<T> {
        self.ok_or_else(|| RiceError::finance(msg.into()))
    }
}

// ---------------------------------------------------------------------------
// Boolean guards
// ---------------------------------------------------------------------------

/// Boolean precondition checks that return [`RiceResult::Ok`] or a typed [`RiceError`].
///
/// **Reflex:** Invariants are expressed as predicates without macros; failures stay explicit.
pub trait RiceBoolExt {
    /// [`Ok`]`(())` if `self` is true; otherwise [`RiceError::Policy`].
    ///
    /// **Reflex:** Business or compliance guards surface as policy vetoes, not generic messages.
    fn ensure_or_policy(self, msg: impl Into<String>) -> RiceResult<()>;

    /// [`Ok`]`(())` if `self` is true; otherwise [`RiceError::InvalidArgument`].
    ///
    /// **Reflex:** Caller-side mistakes (ranges, empty handles) are invalid arguments, not policy.
    fn ensure_or_invalid(self, msg: impl Into<String>) -> RiceResult<()>;
}

impl RiceBoolExt for bool {
    #[inline]
    fn ensure_or_policy(self, msg: impl Into<String>) -> RiceResult<()> {
        if self {
            Ok(())
        } else {
            Err(RiceError::policy(msg.into()))
        }
    }

    #[inline]
    fn ensure_or_invalid(self, msg: impl Into<String>) -> RiceResult<()> {
        if self {
            Ok(())
        } else {
            Err(RiceError::invalid_argument(msg.into()))
        }
    }
}

#[inline]
fn log_rice(level: Level, note: &str, err: &RiceError) {
    match level {
        Level::ERROR => tracing::error!(error = %err, "{note}"),
        Level::WARN => tracing::warn!(error = %err, "{note}"),
        Level::INFO => tracing::info!(error = %err, "{note}"),
        Level::DEBUG => tracing::debug!(error = %err, "{note}"),
        Level::TRACE => tracing::trace!(error = %err, "{note}"),
    }
}
