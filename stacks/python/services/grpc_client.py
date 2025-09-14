import grpc
import asyncio
from typing import Dict, Any, Optional
from datetime import datetime

# Import generated protobuf classes (will be generated from proto files)
try:
    from accounting_proto import accounting_pb2_grpc, accounting_pb2
except ImportError:
    # Mock classes for development
    class MockStub:
        def __init__(self, *args, **kwargs):
            pass
        
        def CreateInvoice(self, request, timeout=None):
            return MockResponse()
        
        def GetDashboardStats(self, request, timeout=None):
            return MockResponse()
    
    class MockResponse:
        def __init__(self):
            self.success = True
            self.message = "Mock response"
            self.invoice = None
            self.stats = None
    
    accounting_pb2_grpc = type('Module', (), {'AccountingServiceStub': MockStub})()
    accounting_pb2 = type('Module', (), {
        'CreateInvoiceRequest': type('MockRequest', (), {}),
        'GetDashboardStatsRequest': type('MockRequest', (), {}),
    })()

from models.invoice import Invoice

class AccountingGRPCClient:
    def __init__(self, host: str = "localhost", port: int = 9090):
        self.host = host
        self.port = port
        self.channel = None
        self.stub = None
    
    async def connect(self):
        """Connect to gRPC server"""
        try:
            self.channel = grpc.aio.insecure_channel(f"{self.host}:{self.port}")
            self.stub = accounting_pb2_grpc.AccountingServiceStub(self.channel)
            return True
        except Exception as e:
            print(f"Failed to connect to gRPC server: {e}")
            return False
    
    async def disconnect(self):
        """Disconnect from gRPC server"""
        if self.channel:
            await self.channel.close()
    
    async def create_invoice(self, invoice: Invoice) -> Dict[str, Any]:
        """Create invoice via gRPC"""
        try:
            if not self.stub:
                await self.connect()
            
            # Convert Invoice to protobuf message
            request = accounting_pb2.CreateInvoiceRequest()
            
            # For now, return mock response
            return {
                "success": True,
                "message": "Invoice created successfully (mock)",
                "invoice": {
                    "id": invoice.id,
                    "invoice_number": invoice.invoice_number,
                    "vendor_name": invoice.vendor_name,
                    "total_amount": invoice.total_amount,
                    "status": invoice.status
                }
            }
            
        except Exception as e:
            return {
                "success": False,
                "message": f"Failed to create invoice: {e}",
                "invoice": None
            }
    
    async def get_dashboard_stats(self) -> Dict[str, Any]:
        """Get dashboard statistics via gRPC"""
        try:
            if not self.stub:
                await self.connect()
            
            # For now, return mock response
            return {
                "total_revenue": 50000.0,
                "total_expenses": 35000.0,
                "net_profit": 15000.0,
                "total_invoices": 150,
                "pending_invoices": 12,
                "overdue_invoices": 3,
                "monthly_revenue": 8500.0,
                "monthly_expenses": 6200.0,
                "monthly_data": [
                    {"month": "2024-01", "revenue": 8000.0, "expenses": 6000.0, "profit": 2000.0},
                    {"month": "2024-02", "revenue": 8500.0, "expenses": 6200.0, "profit": 2300.0},
                    {"month": "2024-03", "revenue": 9200.0, "expenses": 5800.0, "profit": 3400.0},
                ],
                "category_expenses": [
                    {"category": "Офісні витрати", "amount": 12000.0, "percentage": 34.3},
                    {"category": "Програмне забезпечення", "amount": 8000.0, "percentage": 22.9},
                    {"category": "Обладнання", "amount": 6000.0, "percentage": 17.1},
                    {"category": "Маркетинг", "amount": 5000.0, "percentage": 14.3},
                    {"category": "Подорожі", "amount": 3000.0, "percentage": 8.6},
                    {"category": "Харчування", "amount": 1000.0, "percentage": 2.8},
                ]
            }
            
        except Exception as e:
            return {
                "success": False,
                "message": f"Failed to get dashboard stats: {e}",
                "stats": None
            }
