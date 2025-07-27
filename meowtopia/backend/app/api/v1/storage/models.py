from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class StorageItem(BaseModel):
    """Storage Item Model"""
    id: Optional[int] = None
    name: str
    description: Optional[str] = None
    category: str
    quantity: int
    unit_price: float
    supplier: Optional[str] = None
    expiry_date: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class CreateStorageItem(BaseModel):
    """Create Storage Item Request"""
    name: str
    description: Optional[str] = None
    category: str
    quantity: int
    unit_price: float
    supplier: Optional[str] = None
    expiry_date: Optional[datetime] = None

class UpdateStorageItem(BaseModel):
    """Update Storage Item Request"""
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    quantity: Optional[int] = None
    unit_price: Optional[float] = None
    supplier: Optional[str] = None
    expiry_date: Optional[datetime] = None

class StorageItemResponse(BaseModel):
    """Storage Item Response"""
    items: List[StorageItem]
    total: int
    page: int
    per_page: int

class InventoryStats(BaseModel):
    """Inventory Statistics"""
    total_items: int
    total_value: float
    low_stock_items: int
    expired_items: int
    categories: List[str]
