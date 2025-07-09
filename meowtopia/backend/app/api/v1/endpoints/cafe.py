from fastapi import APIRouter, HTTPException, Depends, status, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from enum import Enum
import uuid
import random

from .auth import get_current_user

router = APIRouter(prefix="/cafe", tags=["Cafe Management"])

# Enums
class ItemCategory(str, Enum):
    """Cafe item categories"""
    FOOD = "food"
    DRINK = "drink"
    DESSERT = "dessert"
    CAT_FOOD = "cat_food"
    CAT_TOY = "cat_toy"
    DECORATION = "decoration"

class OrderStatus(str, Enum):
    """Order status"""
    PENDING = "pending"
    PREPARING = "preparing"
    READY = "ready"
    SERVED = "served"
    CANCELLED = "cancelled"

class StaffRole(str, Enum):
    """Staff roles"""
    MANAGER = "manager"
    BARISTA = "barista"
    WAITER = "waiter"
    CLEANER = "cleaner"
    CAT_CAREGIVER = "cat_caregiver"

class CustomerMood(str, Enum):
    """Customer mood levels"""
    VERY_HAPPY = "very_happy"
    HAPPY = "happy"
    NEUTRAL = "neutral"
    UNHAPPY = "unhappy"
    VERY_UNHAPPY = "very_unhappy"

# Pydantic Models
class CafeItemBase(BaseModel):
    """Base cafe item model"""
    name: str = Field(..., min_length=1, max_length=100)
    category: ItemCategory
    description: str = Field(..., max_length=500)
    price: float = Field(..., gt=0)
    cost: float = Field(..., gt=0)
    stock_quantity: int = Field(..., ge=0)
    min_stock_level: int = Field(..., ge=0)

class CafeItemCreate(CafeItemBase):
    """Cafe item creation request"""
    pass

class CafeItemResponse(CafeItemBase):
    """Cafe item response model"""
    id: str
    cafe_id: str
    profit_margin: float
    is_available: bool
    created_at: datetime
    updated_at: datetime

class StaffMemberBase(BaseModel):
    """Base staff member model"""
    name: str = Field(..., min_length=1, max_length=100)
    role: StaffRole
    hourly_rate: float = Field(..., gt=0)
    email: str = Field(..., max_length=100)

class StaffMemberCreate(StaffMemberBase):
    """Staff member creation request"""
    pass

class StaffMemberResponse(StaffMemberBase):
    """Staff member response model"""
    id: str
    cafe_id: str
    is_active: bool
    total_hours_worked: float
    total_salary_paid: float
    hire_date: datetime
    created_at: datetime
    updated_at: datetime

class CustomerBase(BaseModel):
    """Base customer model"""
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., max_length=100)
    phone: Optional[str] = None

class CustomerCreate(CustomerBase):
    """Customer creation request"""
    pass

class CustomerResponse(CustomerBase):
    """Customer response model"""
    id: str
    cafe_id: str
    total_visits: int
    total_spent: float
    favorite_items: List[str]
    mood: CustomerMood
    last_visit: Optional[datetime]
    created_at: datetime
    updated_at: datetime

class OrderItem(BaseModel):
    """Order item model"""
    item_id: str
    quantity: int = Field(..., gt=0)
    unit_price: float
    total_price: float

class OrderBase(BaseModel):
    """Base order model"""
    customer_id: str
    items: List[OrderItem]
    table_number: Optional[int] = None
    special_requests: Optional[str] = None

class OrderCreate(OrderBase):
    """Order creation request"""
    pass

class OrderResponse(OrderBase):
    """Order response model"""
    id: str
    cafe_id: str
    status: OrderStatus
    total_amount: float
    tax_amount: float
    tip_amount: float = 0.0
    staff_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    served_at: Optional[datetime] = None

class CafeAnalytics(BaseModel):
    """Cafe analytics model"""
    total_revenue: float
    total_orders: int
    average_order_value: float
    top_selling_items: List[Dict[str, Any]]
    customer_satisfaction: float
    staff_performance: List[Dict[str, Any]]
    inventory_alerts: List[Dict[str, Any]]
    daily_revenue: List[Dict[str, Any]]
    period: str

class CafeSettings(BaseModel):
    """Cafe settings model"""
    cafe_name: str
    opening_hours: Dict[str, str]
    max_capacity: int
    auto_restock_threshold: int
    tax_rate: float
    service_charge_rate: float
    cat_interaction_fee: float

# Mock databases
cafe_items_db = {}
staff_db = {}
customers_db = {}
orders_db = {}
cafe_settings_db = {}

def calculate_profit_margin(price: float, cost: float) -> float:
    """Calculate profit margin percentage"""
    if price == 0:
        return 0
    return ((price - cost) / price) * 100

def generate_cafe_id() -> str:
    """Generate unique cafe ID"""
    return f"cafe_{len(cafe_items_db) + 1}"

# Cafe Management Endpoints
@router.post("/items", response_model=CafeItemResponse, status_code=status.HTTP_201_CREATED)
async def create_cafe_item(item_data: CafeItemCreate, current_user: dict = Depends(get_current_user)):
    """
    🍽️ **Add New Cafe Item**
    
    Add a new item to the cafe's menu/inventory.
    
    - **name**: Item name (e.g., "Catpuccino", "Whisker Latte")
    - **category**: Item category (food, drink, dessert, cat_food, cat_toy, decoration)
    - **description**: Detailed description of the item
    - **price**: Selling price
    - **cost**: Cost to make/purchase
    - **stock_quantity**: Current stock level
    - **min_stock_level**: Minimum stock before reorder alert
    
    Returns the newly created item with calculated profit margin.
    """
    item_id = str(uuid.uuid4())
    cafe_id = generate_cafe_id()
    profit_margin = calculate_profit_margin(item_data.price, item_data.cost)
    
    new_item = {
        "id": item_id,
        "cafe_id": cafe_id,
        "name": item_data.name,
        "category": item_data.category,
        "description": item_data.description,
        "price": item_data.price,
        "cost": item_data.cost,
        "stock_quantity": item_data.stock_quantity,
        "min_stock_level": item_data.min_stock_level,
        "profit_margin": profit_margin,
        "is_available": item_data.stock_quantity > 0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    cafe_items_db[item_id] = new_item
    
    return CafeItemResponse(**new_item)

@router.get("/items", response_model=List[CafeItemResponse])
async def get_cafe_items(
    category: Optional[ItemCategory] = Query(None, description="Filter by category"),
    available_only: bool = Query(False, description="Show only available items"),
    current_user: dict = Depends(get_current_user)
):
    """
    📋 **Get Cafe Items**
    
    Retrieve all cafe items with optional filtering.
    
    - **category**: Filter by item category
    - **available_only**: Show only items in stock
    
    Returns a list of cafe items with current stock levels.
    """
    items = list(cafe_items_db.values())
    
    if category:
        items = [item for item in items if item["category"] == category]
    
    if available_only:
        items = [item for item in items if item["is_available"]]
    
    return [CafeItemResponse(**item) for item in items]

@router.put("/items/{item_id}/stock", response_model=CafeItemResponse)
async def update_item_stock(
    item_id: str,
    quantity: int = Query(..., description="New stock quantity"),
    current_user: dict = Depends(get_current_user)
):
    """
    📦 **Update Item Stock**
    
    Update the stock quantity for a specific item.
    
    - **item_id**: ID of the item to update
    - **quantity**: New stock quantity
    
    Returns the updated item with new availability status.
    """
    item = cafe_items_db.get(item_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found"
        )
    
    item["stock_quantity"] = max(0, quantity)
    item["is_available"] = item["stock_quantity"] > 0
    item["updated_at"] = datetime.utcnow()
    
    return CafeItemResponse(**item)

# Staff Management
@router.post("/staff", response_model=StaffMemberResponse, status_code=status.HTTP_201_CREATED)
async def hire_staff_member(staff_data: StaffMemberCreate, current_user: dict = Depends(get_current_user)):
    """
    👥 **Hire Staff Member**
    
    Add a new staff member to the cafe.
    
    - **name**: Staff member's full name
    - **role**: Staff role (manager, barista, waiter, cleaner, cat_caregiver)
    - **hourly_rate**: Hourly wage
    - **email**: Contact email
    
    Returns the newly hired staff member.
    """
    staff_id = str(uuid.uuid4())
    cafe_id = generate_cafe_id()
    
    new_staff = {
        "id": staff_id,
        "cafe_id": cafe_id,
        "name": staff_data.name,
        "role": staff_data.role,
        "hourly_rate": staff_data.hourly_rate,
        "email": staff_data.email,
        "is_active": True,
        "total_hours_worked": 0.0,
        "total_salary_paid": 0.0,
        "hire_date": datetime.utcnow(),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    staff_db[staff_id] = new_staff
    
    return StaffMemberResponse(**new_staff)

@router.get("/staff", response_model=List[StaffMemberResponse])
async def get_staff_members(
    active_only: bool = Query(True, description="Show only active staff"),
    role: Optional[StaffRole] = Query(None, description="Filter by role"),
    current_user: dict = Depends(get_current_user)
):
    """
    👥 **Get Staff Members**
    
    Retrieve all staff members with optional filtering.
    
    - **active_only**: Show only active staff members
    - **role**: Filter by staff role
    
    Returns a list of staff members with their performance data.
    """
    staff = list(staff_db.values())
    
    if active_only:
        staff = [s for s in staff if s["is_active"]]
    
    if role:
        staff = [s for s in staff if s["role"] == role]
    
    return [StaffMemberResponse(**s) for s in staff]

# Customer Management
@router.post("/customers", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
async def add_customer(customer_data: CustomerCreate, current_user: dict = Depends(get_current_user)):
    """
    👤 **Add Customer**
    
    Add a new customer to the cafe's database.
    
    - **name**: Customer's full name
    - **email**: Contact email
    - **phone**: Phone number (optional)
    
    Returns the newly added customer.
    """
    customer_id = str(uuid.uuid4())
    cafe_id = generate_cafe_id()
    
    new_customer = {
        "id": customer_id,
        "cafe_id": cafe_id,
        "name": customer_data.name,
        "email": customer_data.email,
        "phone": customer_data.phone,
        "total_visits": 0,
        "total_spent": 0.0,
        "favorite_items": [],
        "mood": CustomerMood.NEUTRAL,
        "last_visit": None,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    customers_db[customer_id] = new_customer
    
    return CustomerResponse(**new_customer)

@router.get("/customers", response_model=List[CustomerResponse])
async def get_customers(
    top_spenders: bool = Query(False, description="Show top spending customers"),
    current_user: dict = Depends(get_current_user)
):
    """
    👥 **Get Customers**
    
    Retrieve all customers with optional sorting.
    
    - **top_spenders**: Sort by total amount spent
    
    Returns a list of customers with their visit history.
    """
    customers = list(customers_db.values())
    
    if top_spenders:
        customers.sort(key=lambda x: x["total_spent"], reverse=True)
    
    return [CustomerResponse(**c) for c in customers]

# Order Management
@router.post("/orders", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(order_data: OrderCreate, current_user: dict = Depends(get_current_user)):
    """
    🍽️ **Create New Order**
    
    Create a new order for customers.
    
    - **customer_id**: ID of the customer placing the order
    - **items**: List of items with quantities
    - **table_number**: Table number (optional)
    - **special_requests**: Special instructions (optional)
    
    Returns the created order with calculated totals.
    """
    order_id = str(uuid.uuid4())
    cafe_id = generate_cafe_id()
    
    # Calculate totals
    total_amount = sum(item.total_price for item in order_data.items)
    tax_rate = 0.08  # 8% tax rate
    tax_amount = total_amount * tax_rate
    
    # Check stock availability
    for item in order_data.items:
        cafe_item = cafe_items_db.get(item.item_id)
        if not cafe_item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Item {item.item_id} not found"
            )
        
        if cafe_item["stock_quantity"] < item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock for {cafe_item['name']}"
            )
        
        # Update stock
        cafe_item["stock_quantity"] -= item.quantity
        cafe_item["is_available"] = cafe_item["stock_quantity"] > 0
        cafe_item["updated_at"] = datetime.utcnow()
    
    new_order = {
        "id": order_id,
        "cafe_id": cafe_id,
        "customer_id": order_data.customer_id,
        "items": [item.dict() for item in order_data.items],
        "table_number": order_data.table_number,
        "special_requests": order_data.special_requests,
        "status": OrderStatus.PENDING,
        "total_amount": total_amount,
        "tax_amount": tax_amount,
        "tip_amount": 0.0,
        "staff_id": None,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "served_at": None
    }
    
    orders_db[order_id] = new_order
    
    # Update customer stats
    customer = customers_db.get(order_data.customer_id)
    if customer:
        customer["total_visits"] += 1
        customer["total_spent"] += total_amount
        customer["last_visit"] = datetime.utcnow()
        customer["updated_at"] = datetime.utcnow()
    
    return OrderResponse(**new_order)

@router.get("/orders", response_model=List[OrderResponse])
async def get_orders(
    status: Optional[OrderStatus] = Query(None, description="Filter by order status"),
    customer_id: Optional[str] = Query(None, description="Filter by customer"),
    current_user: dict = Depends(get_current_user)
):
    """
    📋 **Get Orders**
    
    Retrieve all orders with optional filtering.
    
    - **status**: Filter by order status
    - **customer_id**: Filter by customer
    
    Returns a list of orders with their current status.
    """
    orders = list(orders_db.values())
    
    if status:
        orders = [order for order in orders if order["status"] == status]
    
    if customer_id:
        orders = [order for order in orders if order["customer_id"] == customer_id]
    
    return [OrderResponse(**order) for order in orders]

@router.put("/orders/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: str,
    status: OrderStatus,
    staff_id: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    🔄 **Update Order Status**
    
    Update the status of an order.
    
    - **order_id**: ID of the order to update
    - **status**: New order status
    - **staff_id**: ID of staff member handling the order
    
    Returns the updated order.
    """
    order = orders_db.get(order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    order["status"] = status
    order["staff_id"] = staff_id
    order["updated_at"] = datetime.utcnow()
    
    if status == OrderStatus.SERVED:
        order["served_at"] = datetime.utcnow()
    
    return OrderResponse(**order)

# Analytics and Reporting
@router.get("/analytics", response_model=CafeAnalytics)
async def get_cafe_analytics(
    period: str = Query("today", description="Analytics period: today, week, month"),
    current_user: dict = Depends(get_current_user)
):
    """
    📊 **Get Cafe Analytics**
    
    Retrieve comprehensive analytics for the cafe.
    
    - **period**: Time period for analytics (today, week, month)
    
    Returns detailed analytics including revenue, orders, and performance metrics.
    """
    # Calculate analytics from mock data
    total_revenue = sum(order["total_amount"] for order in orders_db.values())
    total_orders = len(orders_db)
    average_order_value = total_revenue / total_orders if total_orders > 0 else 0
    
    # Top selling items
    item_sales = {}
    for order in orders_db.values():
        for item in order["items"]:
            item_id = item["item_id"]
            quantity = item["quantity"]
            item_sales[item_id] = item_sales.get(item_id, 0) + quantity
    
    top_selling_items = []
    for item_id, quantity in sorted(item_sales.items(), key=lambda x: x[1], reverse=True)[:5]:
        item = cafe_items_db.get(item_id)
        if item:
            top_selling_items.append({
                "item_id": item_id,
                "name": item["name"],
                "quantity_sold": quantity,
                "revenue": quantity * item["price"]
            })
    
    # Customer satisfaction (mock data)
    customer_satisfaction = random.uniform(4.0, 5.0)
    
    # Staff performance
    staff_performance = []
    for staff in staff_db.values():
        staff_performance.append({
            "staff_id": staff["id"],
            "name": staff["name"],
            "role": staff["role"],
            "hours_worked": staff["total_hours_worked"],
            "orders_handled": len([o for o in orders_db.values() if o["staff_id"] == staff["id"]])
        })
    
    # Inventory alerts
    inventory_alerts = []
    for item in cafe_items_db.values():
        if item["stock_quantity"] <= item["min_stock_level"]:
            inventory_alerts.append({
                "item_id": item["id"],
                "name": item["name"],
                "current_stock": item["stock_quantity"],
                "min_stock": item["min_stock_level"]
            })
    
    # Daily revenue (mock data)
    daily_revenue = []
    for i in range(7):
        date = datetime.utcnow() - timedelta(days=i)
        daily_revenue.append({
            "date": date.strftime("%Y-%m-%d"),
            "revenue": random.uniform(100, 500)
        })
    
    return CafeAnalytics(
        total_revenue=total_revenue,
        total_orders=total_orders,
        average_order_value=average_order_value,
        top_selling_items=top_selling_items,
        customer_satisfaction=customer_satisfaction,
        staff_performance=staff_performance,
        inventory_alerts=inventory_alerts,
        daily_revenue=daily_revenue,
        period=period
    )

# Cafe Settings
@router.get("/settings", response_model=CafeSettings)
async def get_cafe_settings(current_user: dict = Depends(get_current_user)):
    """
    ⚙️ **Get Cafe Settings**
    
    Retrieve current cafe settings and configuration.
    
    Returns cafe settings including hours, capacity, and rates.
    """
    # Mock cafe settings
    return CafeSettings(
        cafe_name="Meowtopia Cat Cafe",
        opening_hours={
            "monday": "9:00 AM - 10:00 PM",
            "tuesday": "9:00 AM - 10:00 PM",
            "wednesday": "9:00 AM - 10:00 PM",
            "thursday": "9:00 AM - 10:00 PM",
            "friday": "9:00 AM - 11:00 PM",
            "saturday": "10:00 AM - 11:00 PM",
            "sunday": "10:00 AM - 9:00 PM"
        },
        max_capacity=50,
        auto_restock_threshold=10,
        tax_rate=0.08,
        service_charge_rate=0.15,
        cat_interaction_fee=5.0
    )

@router.put("/settings", response_model=CafeSettings)
async def update_cafe_settings(
    settings: CafeSettings,
    current_user: dict = Depends(get_current_user)
):
    """
    ⚙️ **Update Cafe Settings**
    
    Update cafe settings and configuration.
    
    - **settings**: New cafe settings
    
    Returns the updated cafe settings.
    """
    # In a real implementation, save to database
    cafe_settings_db["current"] = settings.dict()
    return settings 