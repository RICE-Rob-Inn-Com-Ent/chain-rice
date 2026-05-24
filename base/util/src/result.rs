//! Fluent “synapse” helpers for [`crate::error::Result`] and related types — small, inlined adapters that
//! encode CLERK reflexes: attach context, classify failures, guard options, and emit structured
//! traces without allocating on the happy path.

use std::fmt::Display;

use tracing::Level;

use crate::error::Error;

// ---------------------------------------------------------------------------
// std::result::Result → crate::error::Result
// ---------------------------------------------------------------------------

/// Extension for any [`std::result::Result`] whose error type converts into [`Error`].
///
/// **Reflex:** Downstream code speaks one dialect ([`crate::error::Result`]); these methods normalize foreign
/// errors at the boundary and preserve classification for retries and observability.
pub trait ResultExt<T, E> {
    /// Eagerly wrap a failure in [`Error::Context`], retaining the inner error as
    /// [`std::error::Error::source`].
    ///
    /// **Reflex:** `msg` is turned into a [`String`] only when this arm fires — the [`Ok`] path
    /// does not touch `msg`.
    fn context(self, msg: impl Into<String>) -> crate::error::Result<T>
    where
        E: Into<Error>;

    /// Lazily build context only if this [`std::result::Result`] is [`Err`].
    ///
    /// **Reflex:** `f` runs exclusively inside `map_err`; expensive diagnostics (IDs, counters)
    /// stay off the hot success path.
    fn with_context<F, M>(self, f: F) -> crate::error::Result<T>
    where
        E: Into<Error>,
        F: FnOnce() -> M,
        M: Into<String>;

    /// Map [`Err`] to [`Error::InvalidArgument`], preserving the original [`Display`] text.
    ///
    /// **Reflex:** Validation and shape errors stay typed as arguments while still carrying the
    /// upstream message for debugging.
    fn or_invalid_arg(self, msg: impl Into<String>) -> crate::error::Result<T>
    where
        E: Display;

    /// Map [`Err`] to [`Error::Policy`], preserving the original [`Display`] text.
    ///
    /// **Reflex:** The conscience layer receives a veto with both operator context (`msg`) and the
    /// underlying reason (`E`).
    fn or_policy(self, msg: impl Into<String>) -> crate::error::Result<T>
    where
        E: Display;

    /// Map [`Err`] to [`Error::Protocol`], preserving the original [`Display`] text.
    ///
    /// **Reflex:** Session or messaging rules failed; the error is labeled for transport-level
    /// handling distinct from raw I/O.
    fn or_protocol(self, msg: impl Into<String>) -> crate::error::Result<T>
    where
        E: Display;

    /// Log the error at `level` with `note`, then return the same [`Error`] unchanged.
    ///
    /// **Reflex:** Observability fires before the error propagates; structured logging keeps spans
    /// and field keys consistent across CLERK crates.
    fn log_err(self, level: Level, note: impl AsRef<str>) -> crate::error::Result<T>
    where
        E: Into<Error>;
}

impl<T, E> ResultExt<T, E> for std::result::Result<T, E> {
    #[inline]
    fn context(self, msg: impl Into<String>) -> crate::error::Result<T>
    where
        E: Into<Error>,
    {
        self.map_err(|e| Into::<Error>::into(e).context(msg.into()))
    }

    #[inline]
    fn with_context<F, M>(self, f: F) -> crate::error::Result<T>
    where
        E: Into<Error>,
        F: FnOnce() -> M,
        M: Into<String>,
    {
        self.map_err(|e| Into::<Error>::into(e).context(f()))
    }

    #[inline]
    fn or_invalid_arg(self, msg: impl Into<String>) -> crate::error::Result<T>
    where
        E: Display,
    {
        let head = msg.into();
        self.map_err(|e| Error::invalid_argument(format!("{head}: {e}")))
    }

    #[inline]
    fn or_policy(self, msg: impl Into<String>) -> crate::error::Result<T>
    where
        E: Display,
    {
        let head = msg.into();
        self.map_err(|e| Error::policy(format!("{head}: {e}")))
    }

    #[inline]
    fn or_protocol(self, msg: impl Into<String>) -> crate::error::Result<T>
    where
        E: Display,
    {
        let head = msg.into();
        self.map_err(|e| Error::protocol(format!("{head}: {e}")))
    }

    #[inline]
    fn log_err(self, level: Level, note: impl AsRef<str>) -> crate::error::Result<T>
    where
        E: Into<Error>,
    {
        match self {
            Ok(v) => Ok(v),
            Err(e) => {
                let err = Into::<Error>::into(e);
                log_err(level, note.as_ref(), &err);
                Err(err)
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Option → crate::error::Result
// ---------------------------------------------------------------------------

/// Extension for [`Option`] values that must become definite [`crate::error::Result`] outcomes.
///
/// **Reflex:** `None` is not silent — it becomes a typed CLERK error so callers never unwrap.
pub trait OptionExt<T> {
    /// Turn [`None`] into [`Error::InvalidArgument`] with `msg`.
    ///
    /// **Reflex:** Missing configuration or malformed optional input stops before crypto or finance.
    fn ok_or_invalid_arg(self, msg: impl Into<String>) -> crate::error::Result<T>;

    /// Turn [`None`] into [`Error::Policy`] with `msg`.
    ///
    /// **Reflex:** The rule set expected a value that was absent — treat as conscience refusal.
    fn ok_or_policy(self, msg: impl Into<String>) -> crate::error::Result<T>;

    /// Turn [`None`] into [`Error::Finance`] with `msg`.
    ///
    /// **Reflex:** Balances, postings, or mint paths found nothing where something material must
    /// exist.
    fn ok_or_finance(self, msg: impl Into<String>) -> crate::error::Result<T>;
}

impl<T> OptionExt<T> for Option<T> {
    #[inline]
    fn ok_or_invalid_arg(self, msg: impl Into<String>) -> crate::error::Result<T> {
        self.ok_or_else(|| Error::invalid_argument(msg.into()))
    }

    #[inline]
    fn ok_or_policy(self, msg: impl Into<String>) -> crate::error::Result<T> {
        self.ok_or_else(|| Error::policy(msg.into()))
    }

    #[inline]
    fn ok_or_finance(self, msg: impl Into<String>) -> crate::error::Result<T> {
        self.ok_or_else(|| Error::finance(msg.into()))
    }
}

// ---------------------------------------------------------------------------
// Boolean guards
// ---------------------------------------------------------------------------

/// Boolean precondition checks that return [`std::result::Result::Ok`] or a typed [`Error`].
///
/// **Reflex:** Invariants are expressed as predicates without macros; failures stay explicit.
pub trait BoolExt {
    /// [`Ok`]`(())` if `self` is true; otherwise [`Error::Policy`].
    ///
    /// **Reflex:** Business or compliance guards surface as policy vetoes, not generic messages.
    fn ensure_or_policy(self, msg: impl Into<String>) -> crate::error::Result<()>;

    /// [`Ok`]`(())` if `self` is true; otherwise [`Error::InvalidArgument`].
    ///
    /// **Reflex:** Caller-side mistakes (ranges, empty handles) are invalid arguments, not policy.
    fn ensure_or_invalid(self, msg: impl Into<String>) -> crate::error::Result<()>;
}

impl BoolExt for bool {
    #[inline]
    fn ensure_or_policy(self, msg: impl Into<String>) -> crate::error::Result<()> {
        if self {
            Ok(())
        } else {
            Err(Error::policy(msg.into()))
        }
    }

    #[inline]
    fn ensure_or_invalid(self, msg: impl Into<String>) -> crate::error::Result<()> {
        if self {
            Ok(())
        } else {
            Err(Error::invalid_argument(msg.into()))
        }
    }
}

#[inline]
fn log_err(level: Level, note: &str, err: &Error) {
    match level {
        Level::ERROR => tracing::error!(error = %err, "{note}"),
        Level::WARN => tracing::warn!(error = %err, "{note}"),
        Level::INFO => tracing::info!(error = %err, "{note}"),
        Level::DEBUG => tracing::debug!(error = %err, "{note}"),
        Level::TRACE => tracing::trace!(error = %err, "{note}"),
    }
}
