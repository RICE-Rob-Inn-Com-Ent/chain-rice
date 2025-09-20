"""
Main ChainRice client for connecting to Go services.
"""

import asyncio
from typing import Dict, Any, Optional
import httpx
import grpc
from .accounting_api import AccountingApiClient
from .tax_api import TaxApiClient
from .blockchain_client import BlockchainClient
from .exceptions import ChainRiceError


class ChainRiceClient:
    """
    Main client for connecting to ChainRice Go services.
    """

    def __init__(
        self,
        accounting_api_url: str = "http://localhost:8080",
        tax_api_url: str = "http://localhost:8081",
        blockchain_url: str = "http://localhost:26657",
        api_key: Optional[str] = None,
        timeout: int = 30,
    ):
        self.accounting_api_url = accounting_api_url
        self.tax_api_url = tax_api_url
        self.blockchain_url = blockchain_url
        self.api_key = api_key
        self.timeout = timeout

        # Initialize HTTP client
        self._http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(timeout), headers=self._get_headers()
        )

        # Initialize gRPC channel
        self._grpc_channel = grpc.aio.insecure_channel(blockchain_url)

        # Initialize API clients
        self.accounting = AccountingApiClient(
            self._http_client, accounting_api_url, api_key
        )
        self.tax = TaxApiClient(self._http_client, tax_api_url, api_key)
        self.blockchain = BlockchainClient(self._grpc_channel, blockchain_url)

    def _get_headers(self) -> Dict[str, str]:
        """Get default headers for HTTP requests."""
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        return headers

    async def health_check(self) -> Dict[str, Any]:
        """
        Check health of all ChainRice services.

        Returns:
            Dict containing health status of all services
        """
        try:
            # Check Accounting API
            accounting_health = await self.accounting.health_check()

            # Check Tax API
            tax_health = await self.tax.health_check()

            # Check Blockchain
            blockchain_health = await self.blockchain.health_check()

            overall_health = accounting_health and tax_health and blockchain_health

            return {
                "overall": overall_health,
                "accounting_api": accounting_health,
                "tax_api": tax_health,
                "blockchain": blockchain_health,
            }
        except Exception as e:
            raise ChainRiceError(f"Health check failed: {str(e)}")

    async def close(self):
        """Close all connections."""
        await self._http_client.aclose()
        await self._grpc_channel.close()

    async def __aenter__(self):
        """Async context manager entry."""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.close()


class ChainRiceOptions:
    """Configuration options for ChainRice client."""

    def __init__(
        self,
        accounting_api_url: str = "http://localhost:8080",
        tax_api_url: str = "http://localhost:8081",
        blockchain_url: str = "http://localhost:26657",
        api_key: Optional[str] = None,
        timeout: int = 30,
    ):
        self.accounting_api_url = accounting_api_url
        self.tax_api_url = tax_api_url
        self.blockchain_url = blockchain_url
        self.api_key = api_key
        self.timeout = timeout
