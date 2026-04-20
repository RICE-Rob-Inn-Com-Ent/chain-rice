//! Central error surface for the CLERK / `base/` layer of `.rice` OS.
//!
//! [`RiceError`] is the typed boundary for failures that cross crate lines: contracts, ZK private
//! modules, mint, policies, and transport. Callers use [`RiceResult`] with `?` thanks to narrow
//! [`From`] impls; domain code constructs variants through the associated constructors so intent
//! stays explicit without resorting to unstructured logs.

use std::io::ErrorKind;

/// Unified failure type for cryptography, policy, contracts, finance, wire protocols, and I/O.
///
/// Each variant captures *where* the organism felt pain: verification refused to proceed, a rule
/// vetoed an action, the chain rejected execution, arithmetic could not close, or the network
/// disagreed on ordering. Keeping these labels stable lets operators and higher layers map errors
/// to retries, alerts, or user-visible messages without parsing ad-hoc strings.
#[derive(Debug, thiserror::Error)]
pub enum RiceError {
    /// Caller supplied a value outside accepted domains — wrong length, range, or shape.
    ///
    /// **Pain:** The system refuses to guess; bad inputs stop here so invariants downstream (keys,
    /// amounts, circuit layouts) never see corrupted state.
    #[error("invalid argument: {0}")]
    InvalidArgument(String),

    /// Byte sequence is not valid UTF-8 when a text contract required Unicode.
    ///
    /// **Pain:** Human-readable fields, identifiers, or JSON interop hit bytes that cannot decode;
    /// proceeding would mis-display or mis-parse security-sensitive strings.
    #[error("invalid utf-8")]
    InvalidUtf8,

    /// Hex text could not be decoded (odd length, non-hex digit, etc.).
    ///
    /// **Pain:** External encodings of digests or keys failed structural validation before any
    /// cryptographic use — the wire format itself is wrong.
    #[error("hex decode: {0}")]
    Hex(#[from] hex::FromHexError),

    /// Protobuf payload could not be decoded into the expected generated type.
    ///
    /// **Pain:** MASON-generated schemas and the runtime disagree on field layout or length —
    /// usually version skew, truncation, or a hostile frame.
    #[error("protobuf decode: {0}")]
    ProtoDecode(#[from] prost::DecodeError),

    /// Protobuf encoding failed (e.g. required field missing, size limit exceeded).
    ///
    /// **Pain:** Outbound messages cannot be serialized for transport; the logical object violates
    /// encoding rules rather than the byte stream being corrupt on read.
    #[error("protobuf encode: {0}")]
    ProtoEncode(String),

    /// Underlying OS or standard I/O operation failed.
    ///
    /// **Pain:** Disks, sockets, or pipes refused the operation — often transient (timeouts) but
    /// sometimes permanent permission or format errors. See [`RiceError::is_retryable`].
    #[error("io: {0}")]
    Io(#[from] std::io::Error),

    /// Cryptographic verification or construction failed — bad signature, wrong curve point,
    /// proof rejected, key material mismatch.
    ///
    /// **Pain:** The trust anchor did not close; an adversary or bug produced data that cannot be
    /// accepted without breaking soundness. Retrying the same bytes will not help.
    #[error("crypto: {0}")]
    Crypto(String),

    /// Declared business or compliance rule blocked the operation (CEL policies, limits, legal).
    ///
    /// **Pain:** The "conscience" layer vetoed the action — not a bug, but a deliberate refusal.
    /// Callers should surface this distinctly from transient faults.
    #[error("policy: {0}")]
    Policy(String),

    /// CosmWasm execution or internal contract semantics failed (storage, API misuse, custom err).
    ///
    /// **Pain:** On-chain or sandboxed logic aborted; state may have rolled back. Diagnosis needs
    /// contract-specific context in the string payload.
    #[error("contract: {0}")]
    Contract(String),

    /// Monetary invariant broken — mint/burn/transfer could not balance, overflow, or violated calc.
    ///
    /// **Pain:** Value conservation failed; this is never a transport glitch. Retries must not run
    /// without revisiting inputs.
    #[error("finance: {0}")]
    Finance(String),

    /// Messaging or state-machine protocol violation — NATS subject mismatch, unexpected phase,
    /// duplicate sequence, framing error at the session layer.
    ///
    /// **Pain:** Peers are out of sync on the conversation grammar. Some failures share symptoms
    /// with I/O; classify here when the bytes were delivered but semantics were wrong.
    #[error("protocol: {0}")]
    Protocol(String),

    /// Generic operational message when no finer variant applies yet.
    ///
    /// **Pain:** Catch-all for early integration or rare paths; prefer domain variants as APIs
    /// mature so metrics and routing stay precise.
    #[error("{0}")]
    Message(String),

    /// Additional context attached while bubbling an error up the stack.
    ///
    /// **Pain:** The original failure is unchanged; this records *where* it was observed (which
    /// subsystem, which step). Preserves [`source`](std::error::Error::source) for tooling.
    #[error("{context}: {source}")]
    Context {
        /// Human-readable breadcrumb (subsystem, operation, correlation id).
        context: String,
        /// Underlying error being wrapped.
        #[source]
        source: Box<RiceError>,
    },
}

/// Standard [`Result`] alias using [`RiceError`].
pub type RiceResult<T> = Result<T, RiceError>;

impl RiceError {
    /// Attach `msg` as outer context, preserving the original error as [`std::error::Error::source`].
    ///
    /// **Why:** Long `format!` chains lose structure; this keeps a chain for observers and
    /// [`is_retryable`](Self::is_retryable) still defers to the inner error when wrapped.
    #[must_use]
    pub fn context(self, msg: impl Into<String>) -> Self {
        Self::Context {
            context: msg.into(),
            source: Box::new(self),
        }
    }

    /// Returns `true` when a reasonable caller might succeed by retrying the same operation
    /// (with backoff), without changing logical inputs.
    ///
    /// **Why:** Workers and clients need a cheap, conservative hint — not a guarantee — to avoid
    /// infinite loops on deterministic failures.
    #[must_use]
    pub fn is_retryable(&self) -> bool {
        match self {
            RiceError::Io(e) => io_error_is_retryable(e),
            RiceError::Context { source, .. } => source.is_retryable(),
            _ => false,
        }
    }

    /// Build a [`RiceError::Message`] with `msg` as the display text.
    #[must_use]
    pub fn message(msg: impl Into<String>) -> Self {
        Self::Message(msg.into())
    }

    /// Build [`RiceError::InvalidArgument`].
    #[must_use]
    pub fn invalid_argument(msg: impl Into<String>) -> Self {
        Self::InvalidArgument(msg.into())
    }

    /// Build [`RiceError::Crypto`].
    #[must_use]
    pub fn crypto(msg: impl Into<String>) -> Self {
        Self::Crypto(msg.into())
    }

    /// Build [`RiceError::Policy`].
    #[must_use]
    pub fn policy(msg: impl Into<String>) -> Self {
        Self::Policy(msg.into())
    }

    /// Build [`RiceError::Contract`].
    #[must_use]
    pub fn contract(msg: impl Into<String>) -> Self {
        Self::Contract(msg.into())
    }

    /// Build [`RiceError::Finance`].
    #[must_use]
    pub fn finance(msg: impl Into<String>) -> Self {
        Self::Finance(msg.into())
    }

    /// Build [`RiceError::Protocol`].
    #[must_use]
    pub fn protocol(msg: impl Into<String>) -> Self {
        Self::Protocol(msg.into())
    }

    /// Build [`RiceError::ProtoEncode`].
    #[must_use]
    pub fn proto_encode(msg: impl Into<String>) -> Self {
        Self::ProtoEncode(msg.into())
    }
}

#[inline]
fn io_error_is_retryable(e: &std::io::Error) -> bool {
    matches!(
        e.kind(),
        ErrorKind::Interrupted
            | ErrorKind::WouldBlock
            | ErrorKind::TimedOut
            | ErrorKind::ConnectionReset
            | ErrorKind::ConnectionAborted
    )
}

impl From<std::string::FromUtf8Error> for RiceError {
    fn from(_: std::string::FromUtf8Error) -> Self {
        Self::InvalidUtf8
    }
}

impl From<std::str::Utf8Error> for RiceError {
    fn from(_: std::str::Utf8Error) -> Self {
        Self::InvalidUtf8
    }
}

// The `bytes` crate (workspace `1.10+`) does not define a public `FromUtf8Error`; invalid UTF-8
// from `Vec<u8>` / `String::from_utf8` continues to map through [`std::string::FromUtf8Error`]
// into [`RiceError::InvalidUtf8`] above.
