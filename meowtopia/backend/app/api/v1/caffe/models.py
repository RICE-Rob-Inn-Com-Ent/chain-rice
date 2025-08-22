"""
☕ Meowtopia - Modele dla Zarządzania Kawiarnia w Kociej Kawiarni
Autor: System Zarządzania Meowtopia
Data: 2025-01-18

Kompleksowy system zarządzania kawiarnia z pełną logiką biznesową dla kociej kawiarni.
"""

from typing import Optional, List, Dict, Any
from datetime import datetime, date, time
from enum import Enum
from decimal import Decimal
from pydantic import BaseModel, Field, validator
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, Text, Date, Time, ForeignKey, Numeric
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.config import Base


class MenuCategory(str, Enum):
    """Kategorie menu"""
    COFFEE = "kawa"
    TEA = "herbata"
    HOT_DRINKS = "napoje_ciepłe"
    COLD_DRINKS = "napoje_zimne"
    DESSERTS = "desery"
    SNACKS = "przekąski"
    BREAKFAST = "śniadania"
    LUNCH = "lunche"
    CAT_TREATS = "przysmaki_dla_kotów"
    SPECIAL_OFFERS = "oferty_specjalne"


class ItemStatus(str, Enum):
    """Status pozycji menu"""
    AVAILABLE = "dostępny"
    OUT_OF_STOCK = "wyprzedany"
    SEASONAL = "sezonowy"
    DISCONTINUED = "wycofany"
    NEW = "nowość"
    POPULAR = "popularne"


class TableStatus(str, Enum):
    """Status stolika"""
    AVAILABLE = "dostępny"
    OCCUPIED = "zajęty"
    RESERVED = "zarezerwowany"
    CLEANING = "sprzątany"
    OUT_OF_ORDER = "niesprawny"


class OrderStatus(str, Enum):
    """Status zamówienia"""
    PENDING = "oczekuje"
    PREPARING = "przygotowywane"
    READY = "gotowe"
    SERVED = "podane"
    CANCELLED = "anulowane"
    COMPLETED = "zakończone"


class PaymentMethod(str, Enum):
    """Metody płatności"""
    CASH = "gotówka"
    CARD = "karta"
    MOBILE = "mobilna"
    VOUCHER = "bon"
    LOYALTY_POINTS = "punkty_lojalnościowe"


class TableSize(str, Enum):
    """Rozmiar stolika"""
    SMALL = "mały_2_osoby"
    MEDIUM = "średni_4_osoby"
    LARGE = "duży_6_osób"
    FAMILY = "rodzinny_8_osób"
    BAR = "bar_stojący"


class DayOfWeek(str, Enum):
    """Dni tygodnia"""
    MONDAY = "poniedziałek"
    TUESDAY = "wtorek"
    WEDNESDAY = "środa"
    THURSDAY = "czwartek"
    FRIDAY = "piątek"
    SATURDAY = "sobota"
    SUNDAY = "niedziela"


# Modele SQLAlchemy (baza danych)
class MenuItem(Base):
    """Model pozycji menu"""
    __tablename__ = "menu_items"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False, index=True, comment="Nazwa pozycji menu")
    name_en = Column(String(200), comment="Nazwa angielska")
    description = Column(Text, comment="Opis pozycji")
    description_en = Column(Text, comment="Opis angielski")
    
    category = Column(String(50), nullable=False, comment="Kategoria menu")
    price = Column(Numeric(10, 2), nullable=False, comment="Cena")
    cost = Column(Numeric(10, 2), comment="Koszt przygotowania")
    
    # Zdjęcia i prezentacja
    image_url = Column(String(500), comment="URL zdjęcia dania")
    gallery_urls = Column(Text, comment="Dodatkowe zdjęcia (JSON)")
    
    # Status i dostępność
    status = Column(String(50), default=ItemStatus.AVAILABLE)
    is_available = Column(Boolean, default=True)
    availability_hours = Column(Text, comment="Godziny dostępności (JSON)")
    
    # Informacje żywieniowe
    calories = Column(Integer, comment="Kalorie")
    allergens = Column(Text, comment="Alergeny (JSON)")
    dietary_info = Column(Text, comment="Informacje dietetyczne (JSON)")  # wegańskie, bezglutenowe, itp.
    
    # Czas przygotowania
    prep_time_minutes = Column(Integer, comment="Czas przygotowania w minutach")
    difficulty_level = Column(Integer, comment="Poziom trudności (1-5)")
    
    # Składniki i przepis
    ingredients = Column(Text, comment="Lista składników (JSON)")
    recipe_notes = Column(Text, comment="Notatki do przepisu")
    
    # Statystyki
    popularity_score = Column(Float, default=0.0, comment="Wskaźnik popularności")
    times_ordered = Column(Integer, default=0, comment="Ile razy zamówiono")
    avg_rating = Column(Float, comment="Średnia ocena")
    reviews_count = Column(Integer, default=0, comment="Liczba opinii")
    
    # Promocje i rabaty
    discount_percent = Column(Float, default=0.0, comment="Rabat procentowy")
    special_offer = Column(Text, comment="Opis oferty specjalnej")
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relacje
    order_items = relationship("OrderItem", back_populates="menu_item")


class CaffeTable(Base):
    """Model stolika w kawiarni"""
    __tablename__ = "caffe_tables"
    
    id = Column(Integer, primary_key=True, index=True)
    table_number = Column(String(10), unique=True, nullable=False, index=True, comment="Numer stolika")
    
    # Charakterystyka stolika
    size = Column(String(50), nullable=False, comment="Rozmiar stolika")
    capacity = Column(Integer, nullable=False, comment="Maksymalna liczba miejsc")
    location = Column(String(100), comment="Lokalizacja w kawiarni")
    description = Column(Text, comment="Opis stolika")
    
    # Status
    status = Column(String(50), default=TableStatus.AVAILABLE)
    is_active = Column(Boolean, default=True, comment="Czy stolik jest aktywny")
    
    # Właściwości specjalne
    is_window_side = Column(Boolean, default=False, comment="Czy przy oknie")
    is_cat_friendly = Column(Boolean, default=True, comment="Czy przyjazny kotom")
    has_power_outlet = Column(Boolean, default=False, comment="Czy ma gniazdko elektryczne")
    is_quiet_zone = Column(Boolean, default=False, comment="Czy w strefie ciszy")
    
    # QR kod menu
    qr_code_url = Column(String(500), comment="URL do QR kodu menu")
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relacje
    orders = relationship("Order", back_populates="table")
    reservations = relationship("TableReservation", back_populates="table")


class Order(Base):
    """Model zamówienia"""
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    order_number = Column(String(20), unique=True, nullable=False, index=True, comment="Numer zamówienia")
    
    # Powiązania
    table_id = Column(Integer, ForeignKey("caffe_tables.id"), nullable=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    staff_id = Column(Integer, ForeignKey("staff.id"), nullable=True)
    
    # Status i timing
    status = Column(String(50), default=OrderStatus.PENDING)
    order_date = Column(DateTime(timezone=True), default=func.now())
    estimated_prep_time = Column(Integer, comment="Przewidywany czas przygotowania (min)")
    actual_prep_time = Column(Integer, comment="Rzeczywisty czas przygotowania (min)")
    served_at = Column(DateTime(timezone=True), comment="Czas podania")
    
    # Finansowo
    subtotal = Column(Numeric(10, 2), default=0, comment="Wartość przed rabatem")
    discount_amount = Column(Numeric(10, 2), default=0, comment="Kwota rabatu")
    tax_amount = Column(Numeric(10, 2), default=0, comment="Kwota podatku")
    total_amount = Column(Numeric(10, 2), default=0, comment="Całkowita kwota")
    
    # Płatność
    payment_method = Column(String(50), comment="Metoda płatności")
    payment_status = Column(String(50), default="pending", comment="Status płatności")
    payment_date = Column(DateTime(timezone=True), comment="Data płatności")
    
    # Dodatkowe informacje
    special_requests = Column(Text, comment="Specjalne życzenia")
    notes = Column(Text, comment="Notatki do zamówienia")
    customer_rating = Column(Integer, comment="Ocena klienta (1-5)")
    customer_feedback = Column(Text, comment="Opinia klienta")
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relacje
    table = relationship("CaffeTable", back_populates="orders")
    items = relationship("OrderItem", back_populates="order")


class OrderItem(Base):
    """Model pozycji w zamówieniu"""
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    menu_item_id = Column(Integer, ForeignKey("menu_items.id"), nullable=False)
    
    quantity = Column(Integer, nullable=False, default=1, comment="Ilość")
    unit_price = Column(Numeric(10, 2), nullable=False, comment="Cena jednostkowa")
    total_price = Column(Numeric(10, 2), nullable=False, comment="Cena całkowita")
    
    # Modyfikacje
    modifications = Column(Text, comment="Modyfikacje do pozycji (JSON)")
    special_instructions = Column(Text, comment="Specjalne instrukcje")
    
    # Status przygotowania
    status = Column(String(50), default="pending", comment="Status przygotowania pozycji")
    started_at = Column(DateTime(timezone=True), comment="Rozpoczęcie przygotowania")
    completed_at = Column(DateTime(timezone=True), comment="Zakończenie przygotowania")
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relacje
    order = relationship("Order", back_populates="items")
    menu_item = relationship("MenuItem", back_populates="order_items")


class TableReservation(Base):
    """Model rezerwacji stolika"""
    __tablename__ = "table_reservations"
    
    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("caffe_tables.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    
    # Dane rezerwacji
    reservation_date = Column(Date, nullable=False, comment="Data rezerwacji")
    start_time = Column(DateTime(timezone=True), nullable=False, comment="Czas rozpoczęcia")
    end_time = Column(DateTime(timezone=True), nullable=False, comment="Czas zakończenia")
    duration_minutes = Column(Integer, comment="Czas trwania w minutach")
    
    # Dane klienta (jeśli nie ma konta)
    guest_name = Column(String(100), comment="Imię gościa")
    guest_phone = Column(String(20), comment="Telefon gościa")
    guest_email = Column(String(100), comment="Email gościa")
    
    # Szczegóły rezerwacji
    party_size = Column(Integer, nullable=False, comment="Liczba osób")
    special_requests = Column(Text, comment="Specjalne życzenia")
    occasion = Column(String(100), comment="Okazja (urodziny, rocznica, itp.)")
    
    # Status
    status = Column(String(50), default="potwierdzona", comment="Status rezerwacji")
    deposit_amount = Column(Numeric(10, 2), comment="Kwota zadatku")
    deposit_paid = Column(Boolean, default=False, comment="Czy zadatek opłacony")
    
    # Przypomnienia
    reminder_sent = Column(Boolean, default=False, comment="Czy wysłano przypomnienie")
    reminder_sent_at = Column(DateTime(timezone=True), comment="Kiedy wysłano przypomnienie")
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relacje
    table = relationship("CaffeTable", back_populates="reservations")


class OpeningHours(Base):
    """Model godzin otwarcia"""
    __tablename__ = "opening_hours"
    
    id = Column(Integer, primary_key=True, index=True)
    day_of_week = Column(String(20), nullable=False, comment="Dzień tygodnia")
    
    is_open = Column(Boolean, default=True, comment="Czy otwarte")
    open_time = Column(Time, comment="Godzina otwarcia")
    close_time = Column(Time, comment="Godzina zamknięcia")
    
    # Przerwy
    break_start = Column(Time, comment="Początek przerwy")
    break_end = Column(Time, comment="Koniec przerwy")
    
    # Specjalne wydarzenia
    is_special_day = Column(Boolean, default=False, comment="Czy dzień specjalny")
    special_note = Column(Text, comment="Notatka o dniu specjalnym")
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


# Modele Pydantic (API/JSON)
class MenuItemData(BaseModel):
    """Dane pozycji menu"""
    id: Optional[int] = None
    name: str = Field(..., min_length=1, max_length=200, description="Nazwa pozycji")
    name_en: Optional[str] = Field(None, max_length=200, description="Nazwa angielska")
    description: Optional[str] = Field(None, description="Opis pozycji")
    description_en: Optional[str] = Field(None, description="Opis angielski")
    
    category: MenuCategory
    price: float = Field(..., ge=0, description="Cena")
    cost: Optional[float] = Field(None, ge=0, description="Koszt przygotowania")
    
    image_url: Optional[str] = None
    gallery_urls: Optional[List[str]] = []
    
    status: ItemStatus = ItemStatus.AVAILABLE
    is_available: bool = True
    availability_hours: Optional[Dict[str, str]] = None
    
    # Informacje żywieniowe
    calories: Optional[int] = Field(None, ge=0)
    allergens: Optional[List[str]] = []
    dietary_info: Optional[List[str]] = []  # ["wegańskie", "bezglutenowe", "keto"]
    
    prep_time_minutes: Optional[int] = Field(None, ge=1, le=120)
    difficulty_level: Optional[int] = Field(None, ge=1, le=5)
    
    ingredients: Optional[List[str]] = []
    recipe_notes: Optional[str] = None
    
    # Statystyki
    popularity_score: float = 0.0
    times_ordered: int = 0
    avg_rating: Optional[float] = Field(None, ge=1, le=5)
    reviews_count: int = 0
    
    discount_percent: float = Field(0.0, ge=0, le=100)
    special_offer: Optional[str] = None
    
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class CreateMenuItem(BaseModel):
    """Model do tworzenia nowej pozycji menu"""
    name: str = Field(..., min_length=1, max_length=200)
    name_en: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = None
    description_en: Optional[str] = None
    category: MenuCategory
    price: float = Field(..., ge=0)
    cost: Optional[float] = Field(None, ge=0)
    image_url: Optional[str] = None
    calories: Optional[int] = Field(None, ge=0)
    allergens: Optional[List[str]] = []
    dietary_info: Optional[List[str]] = []
    prep_time_minutes: Optional[int] = Field(None, ge=1, le=120)
    ingredients: Optional[List[str]] = []
    recipe_notes: Optional[str] = None


class UpdateMenuItem(BaseModel):
    """Model do aktualizacji pozycji menu"""
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    name_en: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = None
    description_en: Optional[str] = None
    price: Optional[float] = Field(None, ge=0)
    cost: Optional[float] = Field(None, ge=0)
    image_url: Optional[str] = None
    status: Optional[ItemStatus] = None
    is_available: Optional[bool] = None
    calories: Optional[int] = Field(None, ge=0)
    allergens: Optional[List[str]] = None
    dietary_info: Optional[List[str]] = None
    prep_time_minutes: Optional[int] = Field(None, ge=1, le=120)
    ingredients: Optional[List[str]] = None
    recipe_notes: Optional[str] = None
    discount_percent: Optional[float] = Field(None, ge=0, le=100)
    special_offer: Optional[str] = None


class CaffeTableData(BaseModel):
    """Dane stolika"""
    id: Optional[int] = None
    table_number: str = Field(..., min_length=1, max_length=10)
    size: TableSize
    capacity: int = Field(..., ge=1, le=20)
    location: Optional[str] = None
    description: Optional[str] = None
    status: TableStatus = TableStatus.AVAILABLE
    is_active: bool = True
    is_window_side: bool = False
    is_cat_friendly: bool = True
    has_power_outlet: bool = False
    is_quiet_zone: bool = False
    qr_code_url: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class CreateCaffeTable(BaseModel):
    """Model do tworzenia stolika"""
    table_number: str = Field(..., min_length=1, max_length=10)
    size: TableSize
    capacity: int = Field(..., ge=1, le=20)
    location: Optional[str] = None
    description: Optional[str] = None
    is_window_side: bool = False
    is_cat_friendly: bool = True
    has_power_outlet: bool = False
    is_quiet_zone: bool = False


class OrderItemData(BaseModel):
    """Dane pozycji zamówienia"""
    id: Optional[int] = None
    menu_item_id: int
    menu_item_name: Optional[str] = None  # Do wyświetlania
    quantity: int = Field(..., ge=1, le=20)
    unit_price: float = Field(..., ge=0)
    total_price: float = Field(..., ge=0)
    modifications: Optional[List[str]] = []
    special_instructions: Optional[str] = None
    status: str = "pending"
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class CreateOrderItem(BaseModel):
    """Model do tworzenia pozycji zamówienia"""
    menu_item_id: int
    quantity: int = Field(..., ge=1, le=20)
    modifications: Optional[List[str]] = []
    special_instructions: Optional[str] = None


class OrderData(BaseModel):
    """Dane zamówienia"""
    id: Optional[int] = None
    order_number: Optional[str] = None
    table_id: Optional[int] = None
    table_number: Optional[str] = None  # Do wyświetlania
    customer_id: Optional[int] = None
    staff_id: Optional[int] = None
    
    status: OrderStatus = OrderStatus.PENDING
    order_date: Optional[datetime] = None
    estimated_prep_time: Optional[int] = None
    actual_prep_time: Optional[int] = None
    served_at: Optional[datetime] = None
    
    items: List[OrderItemData] = []
    
    subtotal: float = 0.0
    discount_amount: float = 0.0
    tax_amount: float = 0.0
    total_amount: float = 0.0
    
    payment_method: Optional[PaymentMethod] = None
    payment_status: str = "pending"
    payment_date: Optional[datetime] = None
    
    special_requests: Optional[str] = None
    notes: Optional[str] = None
    customer_rating: Optional[int] = Field(None, ge=1, le=5)
    customer_feedback: Optional[str] = None
    
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class CreateOrder(BaseModel):
    """Model do tworzenia zamówienia"""
    table_id: Optional[int] = None
    customer_id: Optional[int] = None
    items: List[CreateOrderItem] = Field(..., min_items=1)
    special_requests: Optional[str] = None
    notes: Optional[str] = None


class TableReservationData(BaseModel):
    """Dane rezerwacji stolika"""
    id: Optional[int] = None
    table_id: int
    table_number: Optional[str] = None  # Do wyświetlania
    customer_id: Optional[int] = None
    
    reservation_date: date
    start_time: datetime
    end_time: datetime
    duration_minutes: Optional[int] = None
    
    # Dane gościa
    guest_name: Optional[str] = Field(None, max_length=100)
    guest_phone: Optional[str] = Field(None, max_length=20)
    guest_email: Optional[str] = Field(None, max_length=100)
    
    party_size: int = Field(..., ge=1, le=20)
    special_requests: Optional[str] = None
    occasion: Optional[str] = Field(None, max_length=100)
    
    status: str = "potwierdzona"
    deposit_amount: Optional[float] = Field(None, ge=0)
    deposit_paid: bool = False
    
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    @validator('duration_minutes', always=True)
    def calculate_duration(cls, v, values):
        """Automatyczne obliczanie czasu trwania"""
        if 'start_time' in values and 'end_time' in values:
            if values['start_time'] and values['end_time']:
                delta = values['end_time'] - values['start_time']
                return int(delta.total_seconds() / 60)
        return v
    
    class Config:
        from_attributes = True


class CreateTableReservation(BaseModel):
    """Model do tworzenia rezerwacji"""
    table_id: int
    customer_id: Optional[int] = None
    reservation_date: date
    start_time: datetime
    end_time: datetime
    
    # Dane gościa (wymagane jeśli brak customer_id)
    guest_name: Optional[str] = Field(None, max_length=100)
    guest_phone: Optional[str] = Field(None, max_length=20)
    guest_email: Optional[str] = Field(None, max_length=100)
    
    party_size: int = Field(..., ge=1, le=20)
    special_requests: Optional[str] = None
    occasion: Optional[str] = Field(None, max_length=100)
    deposit_amount: Optional[float] = Field(None, ge=0)
    
    @validator('guest_name', always=True)
    def validate_guest_info(cls, v, values):
        """Walidacja danych gościa"""
        if not values.get('customer_id') and not v:
            raise ValueError('guest_name jest wymagane gdy brak customer_id')
        return v


class OpeningHoursData(BaseModel):
    """Dane godzin otwarcia"""
    id: Optional[int] = None
    day_of_week: DayOfWeek
    is_open: bool = True
    open_time: Optional[time] = None
    close_time: Optional[time] = None
    break_start: Optional[time] = None
    break_end: Optional[time] = None
    is_special_day: bool = False
    special_note: Optional[str] = None
    
    class Config:
        from_attributes = True


class MenuStatistics(BaseModel):
    """Statystyki menu"""
    total_items: int
    available_items: int
    categories_count: Dict[str, int]
    avg_price: float
    most_popular_item: Optional[Dict[str, Any]]
    revenue_by_category: Dict[str, float]
    low_stock_items: List[str]


class CaffeStatistics(BaseModel):
    """Statystyki kawiarni"""
    total_tables: int
    available_tables: int
    occupied_tables: int
    total_capacity: int
    current_occupancy: int
    occupancy_rate: float
    avg_table_turnover: float
    peak_hours: List[str]
    reservations_today: int
    orders_today: int
    revenue_today: float
    most_popular_table: Optional[Dict[str, Any]]


class MenuListResponse(BaseModel):
    """Odpowiedź z listą menu"""
    items: List[MenuItemData]
    total: int
    page: int
    per_page: int
    pages: int
    has_next: bool
    has_prev: bool


class TablesListResponse(BaseModel):
    """Odpowiedź z listą stolików"""
    tables: List[CaffeTableData]
    total: int
    available: int
    occupied: int
    capacity_total: int
    occupancy_rate: float


class OrdersListResponse(BaseModel):
    """Odpowiedź z listą zamówień"""
    orders: List[OrderData]
    total: int
    page: int
    per_page: int
    pages: int
    has_next: bool
    has_prev: bool
    stats: Dict[str, Any]