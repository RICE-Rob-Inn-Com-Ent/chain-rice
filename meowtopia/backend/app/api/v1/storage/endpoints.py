from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
from .models import (
    StorageItem, CreateStorageItem, UpdateStorageItem, 
    StorageItemResponse, InventoryStats
)

router = APIRouter(tags=["Storage Management"])

@router.get("/items", response_model=StorageItemResponse)
async def get_storage_items(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(10, ge=1, le=100, description="Items per page"),
    category: Optional[str] = Query(None, description="Filter by category"),
    search: Optional[str] = Query(None, description="Search in item names")
):
    """Get all storage items with pagination and filtering"""
    # Mock data for now
    items = [
        StorageItem(
            id=1,
            name="Premium Cat Food",
            description="High-quality dry cat food",
            category="Food",
            quantity=50,
            unit_price=25.99,
            supplier="PetFood Inc."
        ),
        StorageItem(
            id=2,
            name="Cat Toys Bundle",
            description="Assorted cat toys",
            category="Toys",
            quantity=30,
            unit_price=15.50,
            supplier="ToyMaker Ltd."
        )
    ]
    
    return StorageItemResponse(
        items=items,
        total=len(items),
        page=page,
        per_page=per_page
    )

@router.post("/items", response_model=StorageItem, status_code=status.HTTP_201_CREATED)
async def create_storage_item(item: CreateStorageItem):
    """Add new item to storage"""
    return StorageItem(
        id=999,
        **item.dict()
    )

@router.get("/items/{item_id}", response_model=StorageItem)
async def get_storage_item(item_id: int):
    """Get specific storage item by ID"""
    return StorageItem(
        id=item_id,
        name="Sample Item",
        category="Sample",
        quantity=10,
        unit_price=9.99
    )

@router.put("/items/{item_id}", response_model=StorageItem)
async def update_storage_item(item_id: int, item: UpdateStorageItem):
    """Update existing storage item"""
    return StorageItem(
        id=item_id,
        name=item.name or "Updated Item",
        category=item.category or "Updated",
        quantity=item.quantity or 5,
        unit_price=item.unit_price or 19.99
    )

@router.delete("/items/{item_id}")
async def delete_storage_item(item_id: int):
    """Delete storage item"""
    return {"message": f"Item {item_id} deleted successfully"}

@router.get("/stats", response_model=InventoryStats)
async def get_inventory_statistics():
    """Get inventory statistics and overview"""
    return InventoryStats(
        total_items=150,
        total_value=2500.50,
        low_stock_items=5,
        expired_items=2,
        categories=["Food", "Toys", "Accessories", "Medicine", "Cleaning"]
    )

@router.get("/categories")
async def get_categories():
    """Get all available item categories"""
    return {
        "categories": [
            "Food",
            "Toys", 
            "Accessories",
            "Medicine",
            "Cleaning Supplies",
            "Equipment"
        ]
    }

@router.get("/low-stock")
async def get_low_stock_items(threshold: int = Query(10, description="Low stock threshold")):
    """Get items with low stock levels"""
    return {
        "items": [
            {
                "id": 1,
                "name": "Cat Shampoo",
                "current_stock": 3,
                "threshold": threshold
            }
        ],
        "count": 1
    }
