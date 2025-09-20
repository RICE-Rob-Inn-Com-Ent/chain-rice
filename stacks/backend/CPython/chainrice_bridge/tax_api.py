"""
Tax API client for ChainRice services.
"""

from typing import Dict, Any, List, Optional
import httpx
from .exceptions import APIError


class TaxApiClient:
    """
    Client for ChainRice Tax API operations.
    """

    def __init__(
        self,
        http_client: httpx.AsyncClient,
        base_url: str,
        api_key: Optional[str] = None,
    ):
        self.http_client = http_client
        self.base_url = base_url
        self.api_key = api_key

    async def calculate_tax(self, tax_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Calculate tax for given amount and tax type.

        Args:
            tax_data: Tax calculation data

        Returns:
            Tax calculation result
        """
        try:
            response = await self.http_client.post(
                f"{self.base_url}/api/v1/tax/calculate", json=tax_data
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to calculate tax: {str(e)}")

    async def get_tax_rates(self) -> Dict[str, Any]:
        """
        Get tax rates for different categories.

        Returns:
            Tax rates data
        """
        try:
            response = await self.http_client.get(f"{self.base_url}/api/v1/tax/rates")
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to get tax rates: {str(e)}")

    async def create_contractor(
        self, contractor_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Create a new contractor.

        Args:
            contractor_data: Contractor data dictionary

        Returns:
            Created contractor data
        """
        try:
            response = await self.http_client.post(
                f"{self.base_url}/api/v1/contractors", json=contractor_data
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to create contractor: {str(e)}")

    async def get_contractor(self, contractor_id: str) -> Dict[str, Any]:
        """
        Get contractor by ID.

        Args:
            contractor_id: Contractor ID

        Returns:
            Contractor data
        """
        try:
            response = await self.http_client.get(
                f"{self.base_url}/api/v1/contractors/{contractor_id}"
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to get contractor {contractor_id}: {str(e)}")

    async def list_contractors(
        self, page: int = 1, page_size: int = 10
    ) -> Dict[str, Any]:
        """
        List contractors with pagination.

        Args:
            page: Page number
            page_size: Number of items per page

        Returns:
            List of contractors with pagination info
        """
        try:
            response = await self.http_client.get(
                f"{self.base_url}/api/v1/contractors",
                params={"page": page, "pageSize": page_size},
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to list contractors: {str(e)}")

    async def get_calculation_history(
        self, page: int = 1, page_size: int = 10
    ) -> Dict[str, Any]:
        """
        Get calculation history.

        Args:
            page: Page number
            page_size: Number of items per page

        Returns:
            Calculation history with pagination info
        """
        try:
            response = await self.http_client.get(
                f"{self.base_url}/api/v1/calculations/history",
                params={"page": page, "pageSize": page_size},
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to get calculation history: {str(e)}")

    async def health_check(self) -> bool:
        """
        Health check for tax API.

        Returns:
            True if healthy
        """
        try:
            response = await self.http_client.get(f"{self.base_url}/health")
            return response.status_code == 200
        except:
            return False
