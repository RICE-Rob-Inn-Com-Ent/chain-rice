"""
ChainRice Bridge - Python client for connecting to ChainRice Go services.

This package provides a unified interface to access:
- Accounting API for invoice and financial operations
- Tax API for tax calculations and contractor management
- Blockchain client for Cosmos SDK operations
"""

from .client import ChainRiceClient
from .accounting_api import AccountingApiClient
from .tax_api import TaxApiClient
from .blockchain_client import BlockchainClient
from .exceptions import ChainRiceError, APIError, BlockchainError

__version__ = "1.0.0"
__author__ = "ChainRice Team"
__email__ = "dev@chain-rice.com"

__all__ = [
    "ChainRiceClient",
    "AccountingApiClient",
    "TaxApiClient",
    "BlockchainClient",
    "ChainRiceError",
    "APIError",
    "BlockchainError",
]
