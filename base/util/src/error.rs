//! Base error surface for `base/` crates — [`RiceError`] aggregates common failures and supports `?` via [`From`].

/// Top-level error type for cross-crate boundaries in `base/` (contracts, private, mint, policies).
#[derive(Debug, thiserror::Error)]
pub enum RiceError {
    #[error("invalid argument: {0}")]
    InvalidArgument(String),

    #[error("invalid utf-8")]
    InvalidUtf8,

    #[error("hex decode: {0}")]
    Hex(#[from] hex::FromHexError),

    #[error("protobuf decode: {0}")]
    ProtoDecode(#[from] prost::DecodeError),

    #[error("protobuf encode: {0}")]
    ProtoEncode(String),

    #[error("io: {0}")]
    Io(#[from] std::io::Error),

    #[error("{0}")]
    Message(String),
}

/// Standard [`Result`] alias using [`RiceError`].
pub type RiceResult<T> = Result<T, RiceError>;

impl RiceError {
    #[must_use]
    pub fn message(msg: impl Into<String>) -> Self {
        Self::Message(msg.into())
    }

    #[must_use]
    pub fn invalid_argument(msg: impl Into<String>) -> Self {
        Self::InvalidArgument(msg.into())
    }
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
