from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

class InvoiceItem(BaseModel):
    id: Optional[str] = None
    name: str
    description: Optional[str] = None
    quantity: int = 1
    unit_price: float
    total_price: float
    tax_rate: float = 0.23
    category: Optional[str] = None

class Invoice(BaseModel):
    id: Optional[str] = None
    invoice_number: str
    vendor_name: str
    vendor_tax_id: Optional[str] = None
    vendor_address: Optional[str] = None
    date: datetime = datetime.now()
    due_date: Optional[datetime] = None
    total_amount: float
    tax_amount: float
    net_amount: float
    currency: str = "PLN"
    description: Optional[str] = None
    category: str = "Офісні витрати"
    status: str = "pending"  # pending, paid, overdue, cancelled
    items: List[InvoiceItem] = []
    receipt_image_path: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
