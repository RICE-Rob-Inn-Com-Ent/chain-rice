from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime

# Modele danych (PL):
# - Pola wielojęzyczne: pl, en, ua
# - Zgodne z potrzebami kawiarni: Menu, Rezerwacje, Koty, Zamówienia

LanguageCode = Literal["pl", "en", "ua"]

class LocalizedText(BaseModel):
    pl: str = Field(..., description="Tekst w języku polskim")
    en: Optional[str] = Field(None, description="Tekst w języku angielskim")
    ua: Optional[str] = Field(None, description="Tekst w języku ukraińskim")

class MenuCategory(BaseModel):
    id: Optional[int] = None
    name: LocalizedText
    description: Optional[LocalizedText] = None
    order: int = 0

class MenuItem(BaseModel):
    id: Optional[int] = None
    category_id: int
    name: LocalizedText
    description: Optional[LocalizedText] = None
    price_pln: float = Field(..., ge=0, description="Cena w PLN")
    is_vegan: bool = False
    is_gluten_free: bool = False
    is_available: bool = True

class CatProfile(BaseModel):
    id: Optional[int] = None
    name: str
    age_years: float = Field(..., ge=0)
    breed: Optional[str] = None
    description: Optional[LocalizedText] = None
    adoption_available: bool = False
    photo_url: Optional[str] = None

class TableReservation(BaseModel):
    id: Optional[int] = None
    customer_name: str
    customer_phone: str
    persons: int = Field(..., ge=1, le=10)
    date_time: datetime
    notes: Optional[str] = None
    status: Literal["pending", "confirmed", "cancelled", "completed"] = "pending"

class CreateReservation(BaseModel):
    customer_name: str
    customer_phone: str
    persons: int = Field(..., ge=1, le=10)
    date_time: datetime
    notes: Optional[str] = None

class UpdateReservation(BaseModel):
    persons: Optional[int] = Field(None, ge=1, le=10)
    date_time: Optional[datetime] = None
    notes: Optional[str] = None
    status: Optional[Literal["pending", "confirmed", "cancelled", "completed"]] = None

class OrderItem(BaseModel):
    menu_item_id: int
    quantity: int = Field(..., ge=1)

class CafeOrder(BaseModel):
    id: Optional[int] = None
    user_id: Optional[int] = None
    items: List[OrderItem]
    total_pln: float = Field(..., ge=0)
    status: Literal["new", "in_progress", "ready", "served", "cancelled"] = "new"
    created_at: Optional[datetime] = None

class PaginatedResponse(BaseModel):
    total: int
    page: int
    per_page: int

class MenuResponse(PaginatedResponse):
    items: List[MenuItem]

class CatsResponse(PaginatedResponse):
    items: List[CatProfile]

class ReservationsResponse(PaginatedResponse):
    items: List[TableReservation]
