"""
Custom exceptions for ChainRice Bridge.
"""


class ChainRiceError(Exception):
    """Base exception for ChainRice Bridge."""

    pass


class APIError(ChainRiceError):
    """Exception raised for API-related errors."""

    pass


class BlockchainError(ChainRiceError):
    """Exception raised for blockchain-related errors."""

    pass


class ConfigurationError(ChainRiceError):
    """Exception raised for configuration-related errors."""

    pass


class AuthenticationError(ChainRiceError):
    """Exception raised for authentication-related errors."""

    pass


class ValidationError(ChainRiceError):
    """Exception raised for validation-related errors."""

    pass
