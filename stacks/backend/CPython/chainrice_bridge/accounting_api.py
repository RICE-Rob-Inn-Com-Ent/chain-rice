"""
Accounting API client for ChainRice services.
"""

from typing import Dict, Any, List, Optional
import httpx
from .exceptions import APIError


class AccountingApiClient:
    """
    Client for ChainRice Accounting API operations.
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

    async def create_invoice(self, invoice_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new invoice.

        Args:
            invoice_data: Invoice data dictionary

        Returns:
            Created invoice data
        """
        try:
            response = await self.http_client.post(
                f"{self.base_url}/api/v1/invoices", json=invoice_data
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to create invoice: {str(e)}")

    async def get_invoice(self, invoice_id: str) -> Dict[str, Any]:
        """
        Get invoice by ID.

        Args:
            invoice_id: Invoice ID

        Returns:
            Invoice data
        """
        try:
            response = await self.http_client.get(
                f"{self.base_url}/api/v1/invoices/{invoice_id}"
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to get invoice {invoice_id}: {str(e)}")

    async def list_invoices(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        List invoices with pagination.

        Args:
            page: Page number
            page_size: Number of items per page

        Returns:
            List of invoices with pagination info
        """
        try:
            response = await self.http_client.get(
                f"{self.base_url}/api/v1/invoices",
                params={"page": page, "pageSize": page_size},
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to list invoices: {str(e)}")

    async def update_invoice(
        self, invoice_id: str, invoice_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Update an existing invoice.

        Args:
            invoice_id: Invoice ID
            invoice_data: Updated invoice data

        Returns:
            Updated invoice data
        """
        try:
            response = await self.http_client.put(
                f"{self.base_url}/api/v1/invoices/{invoice_id}", json=invoice_data
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to update invoice {invoice_id}: {str(e)}")

    async def delete_invoice(self, invoice_id: str) -> bool:
        """
        Delete an invoice.

        Args:
            invoice_id: Invoice ID

        Returns:
            True if successful
        """
        try:
            response = await self.http_client.delete(
                f"{self.base_url}/api/v1/invoices/{invoice_id}"
            )
            return response.status_code == 200
        except httpx.HTTPError as e:
            raise APIError(f"Failed to delete invoice {invoice_id}: {str(e)}")

    async def get_dashboard_stats(self) -> Dict[str, Any]:
        """
        Get dashboard statistics.

        Returns:
            Dashboard statistics
        """
        try:
            response = await self.http_client.get(
                f"{self.base_url}/api/v1/dashboard/stats"
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise APIError(f"Failed to get dashboard stats: {str(e)}")

    async def health_check(self) -> bool:
        """
        Health check for accounting API.

        Returns:
            True if healthy
        """
        try:
            response = await self.http_client.get(f"{self.base_url}/health")
            return response.status_code == 200
        except:
            return False
