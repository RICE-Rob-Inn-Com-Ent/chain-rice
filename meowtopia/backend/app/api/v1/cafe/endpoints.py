from fastapi import APIRouter, Query, status
from typing import Optional
from .models import (
    MenuItem, MenuResponse, CatProfile, CatsResponse,
    TableReservation, CreateReservation, UpdateReservation, ReservationsResponse,
    CafeOrder, OrderItem, LocalizedText
)

# Router (PL): Moduł kawiarni
router = APIRouter(tags=["Cafe Management"])

# MENU
@router.get("/menu", response_model=MenuResponse, summary="Pobierz menu kawiarni")
async def get_menu(
    page: int = Query(1, ge=1, description="Numer strony"),
    per_page: int = Query(10, ge=1, le=100, description="Elementy na stronę"),
    category_id: Optional[int] = Query(None, description="Filtr po kategorii")
):
    items = [
        MenuItem(
            id=1,
            category_id=1,
            name=LocalizedText(pl="Latte", en="Latte"),
            description=LocalizedText(pl="Kawa z mlekiem", en="Coffee with milk"),
            price_pln=18.0,
            is_vegan=False,
            is_gluten_free=True,
        ),
        MenuItem(
            id=2,
            category_id=1,
            name=LocalizedText(pl="Herbata", en="Tea"),
            description=LocalizedText(pl="Różne smaki", en="Various flavors"),
            price_pln=12.0,
            is_vegan=True,
            is_gluten_free=True,
        ),
    ]
    return MenuResponse(items=items, total=len(items), page=page, per_page=per_page)

# KOTY
@router.get("/cats", response_model=CatsResponse, summary="Lista kotów w kawiarni")
async def get_cats(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100)
):
    cats = [
        CatProfile(id=1, name="Mruczek", age_years=2.5, breed="Mix"),
        CatProfile(id=2, name="Pusia", age_years=4.0, breed="British"),
    ]
    return CatsResponse(items=cats, total=len(cats), page=page, per_page=per_page)

# REZERWACJE
@router.get("/reservations", response_model=ReservationsResponse, summary="Pobierz rezerwacje")
async def list_reservations(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100)
):
    reservations = [
        TableReservation(
            id=1,
            customer_name="Jan Kowalski",
            customer_phone="+48 600 000 000",
            persons=2,
            date_time="2025-08-22T15:00:00",
            status="confirmed",
        )
    ]
    return ReservationsResponse(items=reservations, total=len(reservations), page=page, per_page=per_page)

@router.post("/reservations", response_model=TableReservation, status_code=status.HTTP_201_CREATED, summary="Utwórz rezerwację")
async def create_reservation(payload: CreateReservation):
    return TableReservation(id=999, status="pending", **payload.dict())

@router.put("/reservations/{reservation_id}", response_model=TableReservation, summary="Aktualizuj rezerwację")
async def update_reservation(reservation_id: int, payload: UpdateReservation):
    data = payload.dict(exclude_unset=True)
    return TableReservation(id=reservation_id, customer_name="Aktualizacja", customer_phone="", persons=data.get("persons", 2), date_time=data.get("date_time", "2025-08-22T15:00:00"), status=data.get("status", "pending"))

# ZAMÓWIENIA
@router.post("/orders", response_model=CafeOrder, status_code=status.HTTP_201_CREATED, summary="Utwórz zamówienie")
async def create_order(items: list[OrderItem]):
    total = 0.0
    for it in items:
        total += 10.0 * it.quantity
    return CafeOrder(id=1, items=items, total_pln=total, status="new")
