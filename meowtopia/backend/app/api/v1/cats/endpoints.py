"""
🐱 Meowtopia - API Endpoints dla Zarządzania Kotami w Kociej Kawiarni
Autor: System Zarządzania Meowtopia
Data: 2025-01-18

Kompletne API do zarządzania kotami w kociej kawiarni z zaawansowaną logiką biznesową.
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Path, Body, status, BackgroundTasks
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc, asc, func
import json
import logging

from .models import (
    # SQLAlchemy models
    Cat, CatMedicalRecord, CatInteraction, CatBooking,
    
    # Pydantic models
    CatProfile, CreateCatProfile, UpdateCatProfile, CatsListResponse,
    CatMedicalRecordData, CatInteractionData, CatBookingData,
    CatStatistics, CatSearchFilters,
    
    # Enums
    CatGender, CatBreed, CatPersonality, CatHealthStatus, 
    CatAvailabilityStatus, AdoptionStatus
)

# Import zależności - zastąpione mock'ami dla działania bez bazy danych
logger = logging.getLogger(__name__)

router = APIRouter(tags=["🐱 Zarządzanie Kotami"])

# Mock database session dla działania bez prawdziwej bazy danych
def get_db():
    """Mock database session"""
    pass
    yield

# Mock data - przykładowe koty
MOCK_CATS = [
    {
        "id": 1,
        "name": "Whiskers",
        "chip_id": "PL123456789",
        "breed": "mieszaniec",
        "gender": "samiec",
        "birth_date": "2022-03-15",
        "age_months": 22,
        "weight": 4.2,
        "color": "Szaro-biały w paski",
        "distinctive_features": "Białe skarpetki na łapkach, różowy nosek",
        "photo_url": "/static/cats/whiskers.jpg",
        "gallery_urls": ["/static/cats/whiskers1.jpg", "/static/cats/whiskers2.jpg"],
        "personality": "przyjazny",
        "personality_traits": ["towarzyski", "lubi_pieszczoty", "zabawny"],
        "energy_level": 7,
        "sociability": 9,
        "playfulness": 8,
        "health_status": "dobry",
        "is_neutered": True,
        "is_vaccinated": True,
        "vaccination_date": "2024-10-15",
        "medical_notes": "Zdrowy kot, regularne szczepienia",
        "availability_status": "dostępny",
        "arrival_date": "2022-04-01",
        "is_resident": True,
        "adoption_status": "nie_do_adopcji",
        "adoption_fee": None,
        "special_needs": None,
        "favorite_toys": ["piłeczka", "myszka_z_piórkami", "laserowy_pointer"],
        "favorite_spots": ["parapet_przy_oknie", "pufy_w_rogu", "cat_tree_poziom_2"],
        "food_preferences": "Sucha karma premium, lubi łososia",
        "interaction_notes": "Uwielbia pieszczoty za uszkami. Bardzo towarzyski z dziećmi.",
        "total_interactions": 245,
        "popularity_score": 8.7,
        "last_interaction": "2025-01-17T15:30:00",
        "created_at": "2022-04-01T10:00:00",
        "updated_at": "2025-01-17T16:45:00"
    },
    {
        "id": 2,
        "name": "Luna",
        "chip_id": "PL987654321",
        "breed": "pers",
        "gender": "samica",
        "birth_date": "2021-08-10",
        "age_months": 29,
        "weight": 3.8,
        "color": "Biała z szarymi uszkami",
        "distinctive_features": "Długa, puszysta sierść, błękitne oczy",
        "photo_url": "/static/cats/luna.jpg",
        "gallery_urls": ["/static/cats/luna1.jpg", "/static/cats/luna2.jpg"],
        "personality": "spokojny",
        "personality_traits": ["elegancka", "niezależna", "lubi_obserwować"],
        "energy_level": 4,
        "sociability": 6,
        "playfulness": 3,
        "health_status": "doskonały",
        "is_neutered": True,
        "is_vaccinated": True,
        "vaccination_date": "2024-09-20",
        "medical_notes": "Wymaga codziennego szczotkowania sierści",
        "availability_status": "dostępny",
        "arrival_date": "2021-09-01",
        "is_resident": True,
        "adoption_status": "dostępny_do_adopcji",
        "adoption_fee": 300.0,
        "special_needs": "Codzienna pielęgnacja sierści",
        "favorite_toys": ["piórka", "wędka_z_myszką"],
        "favorite_spots": ["fotel_przy_kominku", "półka_książkowa_poziom_3"],
        "food_preferences": "Mokra karma dla kotów długowłosych",
        "interaction_notes": "Lubi spokojne pieszczoty. Preferuje ciszę.",
        "total_interactions": 156,
        "popularity_score": 7.2,
        "last_interaction": "2025-01-17T14:15:00",
        "created_at": "2021-09-01T11:00:00",
        "updated_at": "2025-01-17T14:20:00"
    },
    {
        "id": 3,
        "name": "Miki",
        "chip_id": "PL456789123",
        "breed": "maine_coon",
        "gender": "samiec",
        "birth_date": "2023-05-20",
        "age_months": 8,
        "weight": 2.1,
        "color": "Rudy tygrys z białym",
        "distinctive_features": "Duże uszy z pędzelkami, imponujący ogon",
        "photo_url": "/static/cats/miki.jpg",
        "gallery_urls": ["/static/cats/miki1.jpg", "/static/cats/miki2.jpg"],
        "personality": "energiczny",
        "personality_traits": ["bardzo_aktywny", "inteligentny", "lubi_wspinaczki"],
        "energy_level": 9,
        "sociability": 8,
        "playfulness": 10,
        "health_status": "doskonały",
        "is_neutered": False,
        "is_vaccinated": True,
        "vaccination_date": "2024-12-10",
        "medical_notes": "Młody kot w doskonałej kondycji. Planowana kastracja w lutym 2025.",
        "availability_status": "dostępny",
        "arrival_date": "2023-06-15",
        "is_resident": True,
        "adoption_status": "dostępny_do_adopcji",
        "adoption_fee": 450.0,
        "special_needs": None,
        "favorite_toys": ["duża_piłka", "drapak_wysokość_max", "puzzle_na_karma"],
        "favorite_spots": ["cat_tree_szczyt", "półka_pod_sufitem"],
        "food_preferences": "Sucha karma kitten, duże porcje",
        "interaction_notes": "Bardzo aktywny, potrzebuje dużo ruchu. Uwielbia zabawy wysokoenergetyczne.",
        "total_interactions": 89,
        "popularity_score": 9.1,
        "last_interaction": "2025-01-17T16:00:00",
        "created_at": "2023-06-15T09:30:00",
        "updated_at": "2025-01-17T16:05:00"
    }
]

@router.get("/", response_model=CatsListResponse, summary="📋 Lista wszystkich kotów")
async def get_all_cats(
    page: int = Query(1, ge=1, description="Numer strony"),
    per_page: int = Query(10, ge=1, le=100, description="Kotów na stronę"),
    name: Optional[str] = Query(None, description="Szukaj po imieniu kota"),
    breed: Optional[CatBreed] = Query(None, description="Filtruj po rasie"),
    gender: Optional[CatGender] = Query(None, description="Filtruj po płci"),
    availability_status: Optional[CatAvailabilityStatus] = Query(None, description="Status dostępności"),
    adoption_status: Optional[AdoptionStatus] = Query(None, description="Status adopcji"),
    health_status: Optional[CatHealthStatus] = Query(None, description="Status zdrowia"),
    personality: Optional[CatPersonality] = Query(None, description="Typ osobowości"),
    age_min_months: Optional[int] = Query(None, ge=0, description="Minimalny wiek w miesiącach"),
    age_max_months: Optional[int] = Query(None, le=300, description="Maksymalny wiek w miesiącach"),
    energy_level_min: Optional[int] = Query(None, ge=1, le=10, description="Minimalny poziom energii"),
    sort_by: str = Query("name", description="Sortuj po: name, age, popularity, interactions"),
    sort_order: str = Query("asc", description="Kierunek sortowania: asc, desc"),
    db: Session = Depends(get_db)
):
    """
    🐱 Pobierz listę wszystkich kotów w kawiarni z zaawansowanymi filtrami i sortowaniem.
    
    ## Funkcje biznesowe:
    - **Paginacja** - wydajne przeglądanie dużej liczby kotów
    - **Filtrowanie wielokryterialne** - znajdź idealnego kota dla klienta
    - **Sortowanie** - uporządkuj według preferencji
    - **Wyszukiwanie tekstowe** - znajdź kota po imieniu
    
    ## Przypadki użycia:
    - 👥 **Klienci**: przeglądanie dostępnych kotów
    - 👨‍💼 **Personel**: zarządzanie listą kotów  
    - 🏥 **Weterynarz**: przegląd zdrowia kotów
    - 🏠 **Adopcje**: lista kotów dostępnych do adopcji
    """
    
    # Filtrowanie mock danych
    filtered_cats = MOCK_CATS.copy()
    
    if name:
        filtered_cats = [cat for cat in filtered_cats if name.lower() in cat["name"].lower()]
    
    if breed:
        filtered_cats = [cat for cat in filtered_cats if cat["breed"] == breed.value]
        
    if gender:
        filtered_cats = [cat for cat in filtered_cats if cat["gender"] == gender.value]
        
    if availability_status:
        filtered_cats = [cat for cat in filtered_cats if cat["availability_status"] == availability_status.value]
        
    if adoption_status:
        filtered_cats = [cat for cat in filtered_cats if cat["adoption_status"] == adoption_status.value]
        
    if health_status:
        filtered_cats = [cat for cat in filtered_cats if cat["health_status"] == health_status.value]
        
    if personality:
        filtered_cats = [cat for cat in filtered_cats if cat["personality"] == personality.value]
    
    if age_min_months:
        filtered_cats = [cat for cat in filtered_cats if cat.get("age_months", 0) >= age_min_months]
        
    if age_max_months:
        filtered_cats = [cat for cat in filtered_cats if cat.get("age_months", 0) <= age_max_months]
        
    if energy_level_min:
        filtered_cats = [cat for cat in filtered_cats if cat.get("energy_level", 0) >= energy_level_min]
    
    # Sortowanie
    reverse_order = sort_order == "desc"
    if sort_by == "age":
        filtered_cats.sort(key=lambda x: x.get("age_months", 0), reverse=reverse_order)
    elif sort_by == "popularity":
        filtered_cats.sort(key=lambda x: x.get("popularity_score", 0), reverse=reverse_order)
    elif sort_by == "interactions":
        filtered_cats.sort(key=lambda x: x.get("total_interactions", 0), reverse=reverse_order)
    else:  # name
        filtered_cats.sort(key=lambda x: x["name"], reverse=reverse_order)
    
    # Paginacja
    total = len(filtered_cats)
    start_idx = (page - 1) * per_page
    end_idx = start_idx + per_page
    paginated_cats = filtered_cats[start_idx:end_idx]
    
    total_pages = (total + per_page - 1) // per_page
    
    logger.info(f"Pobrano listę kotów: {len(paginated_cats)}/{total} kotów, strona {page}/{total_pages}")
    
    return CatsListResponse(
        cats=[CatProfile(**cat) for cat in paginated_cats],
        total=total,
        page=page,
        per_page=per_page,
        pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1
    )


@router.get("/{cat_id}", response_model=CatProfile, summary="🐱 Szczegóły kota")
async def get_cat_by_id(
    cat_id: int = Path(..., description="ID kota"),
    db: Session = Depends(get_db)
):
    """
    🐱 Pobierz szczegółowe informacje o konkretnym kocie.
    
    Zwraca pełny profil kota z wszystkimi informacjami:
    - Dane osobowe i charakterystyka
    - Status zdrowia i historia medyczna
    - Preferencje i zachowania
    - Statystyki interakcji
    - Informacje o adopcji
    """
    
    # Znajdź kota w mock danych
    cat = next((cat for cat in MOCK_CATS if cat["id"] == cat_id), None)
    if not cat:
        logger.warning(f"Nie znaleziono kota z ID: {cat_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Kot z ID {cat_id} nie został znaleziony w systemie"
        )
    
    logger.info(f"Pobrano profil kota: {cat['name']} (ID: {cat_id})")
    return CatProfile(**cat)


@router.post("/", response_model=CatProfile, status_code=status.HTTP_201_CREATED, summary="➕ Dodaj nowego kota")
async def create_new_cat(
    cat_data: CreateCatProfile = Body(..., description="Dane nowego kota"),
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db)
):
    """
    ➕ Dodaj nowego kota do kawiarni.
    
    ## Proces biznesowy:
    1. **Walidacja danych** - sprawdzenie kompletności informacji
    2. **Generowanie profilu** - tworzenie unikalnego profilu kota
    3. **Inicjalizacja statystyk** - ustawienie początkowych wartości
    4. **Powiadomienia** - informowanie personelu o nowym mieszkańcu
    5. **Przygotowanie miejsca** - planowanie przestrzeni dla kota
    
    ## Wymagane dokumenty:
    - Certyfikat szczepień
    - Historia medyczna (jeśli dostępna)
    - Dokument identyfikacji (chip)
    """
    
    # Walidacja unikalności chip_id
    if cat_data.chip_id:
        existing_cat = next((cat for cat in MOCK_CATS if cat.get("chip_id") == cat_data.chip_id), None)
        if existing_cat:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Kot z numerem chipa {cat_data.chip_id} już istnieje w systemie"
            )
    
    # Generowanie nowego ID
    new_id = max((cat["id"] for cat in MOCK_CATS), default=0) + 1
    
    # Obliczanie wieku na podstawie daty urodzenia
    age_months = None
    if cat_data.birth_date:
        today = date.today()
        age_months = (today.year - cat_data.birth_date.year) * 12 + today.month - cat_data.birth_date.month
    
    # Tworzenie nowego profilu kota
    new_cat_data = {
        "id": new_id,
        "name": cat_data.name,
        "chip_id": cat_data.chip_id,
        "breed": cat_data.breed.value if cat_data.breed else "mieszaniec",
        "gender": cat_data.gender.value,
        "birth_date": cat_data.birth_date.isoformat() if cat_data.birth_date else None,
        "age_months": age_months,
        "weight": cat_data.weight,
        "color": cat_data.color,
        "distinctive_features": cat_data.distinctive_features,
        "photo_url": cat_data.photo_url,
        "gallery_urls": [],
        "personality": cat_data.personality.value if cat_data.personality else None,
        "personality_traits": [],
        "energy_level": cat_data.energy_level,
        "sociability": cat_data.sociability,
        "playfulness": cat_data.playfulness,
        "health_status": cat_data.health_status.value,
        "is_neutered": cat_data.is_neutered,
        "is_vaccinated": cat_data.is_vaccinated,
        "vaccination_date": cat_data.vaccination_date.isoformat() if cat_data.vaccination_date else None,
        "medical_notes": None,
        "availability_status": "dostępny",
        "arrival_date": date.today().isoformat(),
        "is_resident": True,
        "adoption_status": cat_data.adoption_status.value,
        "adoption_fee": cat_data.adoption_fee,
        "special_needs": cat_data.special_needs,
        "favorite_toys": [],
        "favorite_spots": [],
        "food_preferences": None,
        "interaction_notes": None,
        "total_interactions": 0,
        "popularity_score": 0.0,
        "last_interaction": None,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat()
    }
    
    # Dodanie do mock danych
    MOCK_CATS.append(new_cat_data)
    
    # Symulacja zadań w tle
    if background_tasks:
        background_tasks.add_task(
            notify_staff_new_cat,
            cat_name=cat_data.name,
            cat_id=new_id
        )
        background_tasks.add_task(
            prepare_cat_space,
            cat_id=new_id,
            special_needs=cat_data.special_needs
        )
    
    logger.info(f"Dodano nowego kota: {cat_data.name} (ID: {new_id})")
    
    return CatProfile(**new_cat_data)


@router.put("/{cat_id}", response_model=CatProfile, summary="📝 Aktualizuj profil kota")
async def update_cat_profile(
    cat_id: int = Path(..., description="ID kota"),
    cat_update: UpdateCatProfile = Body(..., description="Dane do aktualizacji"),
    db: Session = Depends(get_db)
):
    """
    📝 Aktualizuj informacje o kocie.
    
    Pozwala na modyfikację wszystkich aspektów profilu kota:
    - Dane podstawowe i opis
    - Status zdrowia i informacje medyczne  
    - Preferencje i zachowania
    - Status dostępności
    - Informacje o adopcji
    """
    
    # Znajdź kota
    cat_index = next((i for i, cat in enumerate(MOCK_CATS) if cat["id"] == cat_id), None)
    if cat_index is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Kot z ID {cat_id} nie został znaleziony"
        )
    
    current_cat = MOCK_CATS[cat_index]
    
    # Aktualizuj tylko podane pola
    update_data = cat_update.dict(exclude_unset=True)
    
    # Specjalna obsługa enum values
    for field, value in update_data.items():
        if hasattr(value, 'value'):  # Jest to enum
            update_data[field] = value.value
        elif field == "vaccination_date" and value:
            update_data[field] = value.isoformat()
    
    # Aktualizuj dane
    current_cat.update(update_data)
    current_cat["updated_at"] = datetime.now().isoformat()
    
    # Przelicz wiek jeśli zmieniono datę urodzenia
    if "birth_date" in update_data and current_cat["birth_date"]:
        birth_date = datetime.fromisoformat(current_cat["birth_date"]).date()
        today = date.today()
        age_months = (today.year - birth_date.year) * 12 + today.month - birth_date.month
        current_cat["age_months"] = max(0, age_months)
    
    logger.info(f"Zaktualizowano profil kota: {current_cat['name']} (ID: {cat_id})")
    
    return CatProfile(**current_cat)


@router.delete("/{cat_id}", status_code=status.HTTP_204_NO_CONTENT, summary="🗑️ Usuń kota z systemu")
async def delete_cat(
    cat_id: int = Path(..., description="ID kota"),
    reason: str = Query(..., description="Powód usunięcia (adopcja, przeniesienie, itp.)"),
    db: Session = Depends(get_db)
):
    """
    🗑️ Usuń kota z systemu kawiarni.
    
    **Uwaga**: Ta operacja jest nieodwracalna!
    
    ## Powody usunięcia:
    - **Adopcja** - kot znalazł nowy dom
    - **Przeniesienie** - kot został przeniesiony do innej placówki
    - **Problemy zdrowotne** - kot wymaga specjalistycznej opieki
    - **Inne** - szczegóły w opisie
    """
    
    # Znajdź kota
    cat_index = next((i for i, cat in enumerate(MOCK_CATS) if cat["id"] == cat_id), None)
    if cat_index is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Kot z ID {cat_id} nie został znaleziony"
        )
    
    removed_cat = MOCK_CATS.pop(cat_index)
    
    logger.info(f"Usunięto kota z systemu: {removed_cat['name']} (ID: {cat_id}), powód: {reason}")


@router.get("/{cat_id}/medical-history", response_model=List[CatMedicalRecordData], summary="🏥 Historia medyczna kota")
async def get_cat_medical_history(
    cat_id: int = Path(..., description="ID kota"),
    start_date: Optional[date] = Query(None, description="Data początkowa"),
    end_date: Optional[date] = Query(None, description="Data końcowa"),
    record_type: Optional[str] = Query(None, description="Typ rekordu: szczepienie, badanie, leczenie"),
    db: Session = Depends(get_db)
):
    """
    🏥 Pobierz kompletną historię medyczną kota.
    
    Zawiera wszystkie rekordy medyczne:
    - Szczepienia i ich terminy
    - Badania kontrolne
    - Leczenie i diagnozy
    - Zalecenia weterynaryjne
    - Koszty leczenia
    """
    
    # Sprawdź czy kot istnieje
    cat = next((cat for cat in MOCK_CATS if cat["id"] == cat_id), None)
    if not cat:
        raise HTTPException(status_code=404, detail="Kot nie znaleziony")
    
    # Mock danych medycznych
    medical_records = [
        {
            "id": 1,
            "cat_id": cat_id,
            "date": "2024-10-15",
            "type": "szczepienie",
            "veterinarian": "Dr. Anna Kowalska",
            "clinic": "Klinika Weterynaryjna Przyjaźń",
            "diagnosis": "Profilaktyczne szczepienie roczne",
            "treatment": "Szczepionka przeciwko panleukopenii, kaliciwirozowi, rinotrachitis",
            "medications": ["Nobivac Tricat", "Nobivac Rabies"],
            "next_visit": "2025-10-15",
            "cost": 120.0,
            "notes": "Kot w doskonałej kondycji, bez przeciwwskazań",
            "created_at": "2024-10-15T10:30:00"
        },
        {
            "id": 2,
            "cat_id": cat_id,
            "date": "2024-08-20",
            "type": "badanie",
            "veterinarian": "Dr. Piotr Nowak",
            "clinic": "Klinika Weterynaryjna Przyjaźń",
            "diagnosis": "Badanie kontrolne - wynik prawidłowy",
            "treatment": "Brak potrzeby leczenia",
            "medications": [],
            "next_visit": None,
            "cost": 80.0,
            "notes": "Zalecane regularne szczotkowanie sierści",
            "created_at": "2024-08-20T14:15:00"
        }
    ] if cat_id in [1, 2, 3] else []
    
    # Filtrowanie
    filtered_records = medical_records
    
    if start_date:
        filtered_records = [r for r in filtered_records if r["date"] >= start_date.isoformat()]
    if end_date:
        filtered_records = [r for r in filtered_records if r["date"] <= end_date.isoformat()]
    if record_type:
        filtered_records = [r for r in filtered_records if r["type"] == record_type]
    
    return [CatMedicalRecordData(**record) for record in filtered_records]


@router.post("/{cat_id}/medical-records", response_model=CatMedicalRecordData, summary="📋 Dodaj rekord medyczny")
async def add_medical_record(
    cat_id: int = Path(..., description="ID kota"),
    record_data: CatMedicalRecordData = Body(..., description="Dane rekordu medycznego"),
    db: Session = Depends(get_db)
):
    """
    📋 Dodaj nowy rekord medyczny dla kota.
    
    Służy do dokumentowania:
    - Wizyt weterynaryjnych
    - Szczepień i ich terminów
    - Badań diagnostycznych  
    - Leczenia i jego skutków
    - Kosztów leczenia
    """
    
    # Sprawdź czy kot istnieje
    cat = next((cat for cat in MOCK_CATS if cat["id"] == cat_id), None)
    if not cat:
        raise HTTPException(status_code=404, detail="Kot nie znaleziony")
    
    # Symulacja dodania rekordu
    new_record = record_data.dict()
    new_record["id"] = 999  # Mock ID
    new_record["cat_id"] = cat_id
    new_record["created_at"] = datetime.now().isoformat()
    
    logger.info(f"Dodano rekord medyczny dla kota {cat['name']} (ID: {cat_id})")
    
    return CatMedicalRecordData(**new_record)


@router.get("/{cat_id}/interactions", response_model=List[CatInteractionData], summary="🤝 Interakcje kota")
async def get_cat_interactions(
    cat_id: int = Path(..., description="ID kota"),
    limit: int = Query(50, ge=1, le=200, description="Maksymalna liczba rekordów"),
    start_date: Optional[date] = Query(None, description="Data początkowa"),
    end_date: Optional[date] = Query(None, description="Data końcowa"),
    interaction_type: Optional[str] = Query(None, description="Typ interakcji"),
    db: Session = Depends(get_db)
):
    """
    🤝 Pobierz historię interakcji kota z klientami i personelem.
    
    Zawiera informacje o:
    - Czasach spędzonych z klientami
    - Typach aktywności
    - Nastrojach kota przed i po interakcji
    - Ocenach jakości spotkań
    - Preferencjach interakcji
    """
    
    # Sprawdź czy kot istnieje
    cat = next((cat for cat in MOCK_CATS if cat["id"] == cat_id), None)
    if not cat:
        raise HTTPException(status_code=404, detail="Kot nie znaleziony")
    
    # Mock danych interakcji
    interactions = [
        {
            "id": 1,
            "cat_id": cat_id,
            "customer_id": 123,
            "staff_id": None,
            "start_time": "2025-01-17T15:30:00",
            "end_time": "2025-01-17T16:15:00",
            "duration_minutes": 45,
            "interaction_type": "pieszczoty",
            "quality_rating": 5,
            "cat_mood_before": "spokojny",
            "cat_mood_after": "zadowolony",
            "notes": "Kot bardzo pozytywnie zareagował na klienta. Mruczał przez cały czas.",
            "created_at": "2025-01-17T16:20:00"
        },
        {
            "id": 2,
            "cat_id": cat_id,
            "customer_id": None,
            "staff_id": 5,
            "start_time": "2025-01-17T14:00:00",
            "end_time": "2025-01-17T14:30:00",
            "duration_minutes": 30,
            "interaction_type": "zabawa",
            "quality_rating": 4,
            "cat_mood_before": "energiczny",
            "cat_mood_after": "zmęczony",
            "notes": "Aktywna zabawa z piłeczką. Kot się dobrze bawił.",
            "created_at": "2025-01-17T14:35:00"
        }
    ] if cat_id in [1, 2, 3] else []
    
    return [CatInteractionData(**interaction) for interaction in interactions[:limit]]


@router.get("/{cat_id}/bookings", response_model=List[CatBookingData], summary="📅 Rezerwacje z kotem")
async def get_cat_bookings(
    cat_id: int = Path(..., description="ID kota"),
    start_date: Optional[date] = Query(None, description="Data początkowa"),
    end_date: Optional[date] = Query(None, description="Data końcowa"),
    status: Optional[str] = Query(None, description="Status rezerwacji"),
    db: Session = Depends(get_db)
):
    """
    📅 Pobierz listę rezerwacji dla konkretnego kota.
    
    Pokazuje:
    - Zaplanowane sesje z klientami
    - Statusy rezerwacji
    - Specjalne życzenia klientów
    - Ceny usług
    - Informacje kontaktowe
    """
    
    # Sprawdź czy kot istnieje
    cat = next((cat for cat in MOCK_CATS if cat["id"] == cat_id), None)
    if not cat:
        raise HTTPException(status_code=404, detail="Kot nie znaleziony")
    
    # Mock rezerwacji
    bookings = [
        {
            "id": 1,
            "cat_id": cat_id,
            "customer_id": 123,
            "booking_date": "2025-01-20",
            "start_time": "2025-01-20T15:00:00",
            "end_time": "2025-01-20T16:00:00",
            "status": "potwierdzona",
            "special_requests": "Proszę o spokojną sesję, pierwsza wizyta z kotem",
            "price": 35.0,
            "created_at": "2025-01-18T10:30:00"
        }
    ] if cat_id in [1, 2] else []
    
    return [CatBookingData(**booking) for booking in bookings]


@router.get("/statistics/overview", response_model=CatStatistics, summary="📊 Statystyki kotów")
async def get_cats_statistics(
    db: Session = Depends(get_db)
):
    """
    📊 Pobierz kompleksowe statystyki dotyczące kotów w kawiarni.
    
    Zawiera:
    - Ogólną liczbę kotów
    - Rozkład ras i płci
    - Statystyki zdrowia
    - Popularność kotów
    - Statystyki adopcji
    - Trendy interakcji
    """
    
    total_cats = len(MOCK_CATS)
    available_cats = len([cat for cat in MOCK_CATS if cat["availability_status"] == "dostępny"])
    cats_for_adoption = len([cat for cat in MOCK_CATS if cat["adoption_status"] == "dostępny_do_adopcji"])
    
    # Znajdź najpopularniejszego kota
    most_popular = max(MOCK_CATS, key=lambda x: x["popularity_score"]) if MOCK_CATS else None
    
    # Rozkład ras
    breed_distribution = {}
    for cat in MOCK_CATS:
        breed = cat["breed"]
        breed_distribution[breed] = breed_distribution.get(breed, 0) + 1
    
    # Rozkład wieku
    age_distribution = {"młode (0-12m)": 0, "dorosłe (1-5lat)": 0, "starsze (5+lat)": 0}
    for cat in MOCK_CATS:
        age = cat.get("age_months", 0)
        if age <= 12:
            age_distribution["młode (0-12m)"] += 1
        elif age <= 60:
            age_distribution["dorosłe (1-5lat)"] += 1
        else:
            age_distribution["starsze (5+lat)"] += 1
    
    # Status zdrowia
    health_status_summary = {}
    for cat in MOCK_CATS:
        status = cat["health_status"]
        health_status_summary[status] = health_status_summary.get(status, 0) + 1
    
    return CatStatistics(
        total_cats=total_cats,
        available_cats=available_cats,
        cats_for_adoption=cats_for_adoption,
        adopted_this_month=2,  # Mock data
        most_popular_cat={
            "name": most_popular["name"],
            "popularity_score": most_popular["popularity_score"],
            "total_interactions": most_popular["total_interactions"]
        } if most_popular else None,
        breed_distribution=breed_distribution,
        age_distribution=age_distribution,
        health_status_summary=health_status_summary,
        interaction_stats={
            "total_interactions_today": 15,
            "average_session_length": 42,
            "most_popular_activity": "pieszczoty",
            "satisfaction_rating": 4.6
        }
    )


@router.post("/{cat_id}/interactions", response_model=CatInteractionData, summary="🤝 Zapisz nową interakcję")
async def record_cat_interaction(
    cat_id: int = Path(..., description="ID kota"),
    interaction: CatInteractionData = Body(..., description="Dane interakcji"),
    db: Session = Depends(get_db)
):
    """
    🤝 Zapisz nową interakcję kota z klientem lub personelem.
    
    ## Automatyczne funkcje:
    - Obliczenie czasu trwania
    - Aktualizacja statystyk popularności
    - Aktualizacja preferencji kota
    - Powiadomienia dla personelu
    """
    
    # Sprawdź czy kot istnieje
    cat = next((cat for cat in MOCK_CATS if cat["id"] == cat_id), None)
    if not cat:
        raise HTTPException(status_code=404, detail="Kot nie znaleziony")
    
    # Oblicz czas trwania jeśli podano oba czasy
    duration = None
    if interaction.start_time and interaction.end_time:
        delta = interaction.end_time - interaction.start_time
        duration = int(delta.total_seconds() / 60)
    
    # Symulacja zapisania interakcji
    new_interaction = interaction.dict()
    new_interaction["id"] = 999
    new_interaction["cat_id"] = cat_id
    new_interaction["duration_minutes"] = duration
    new_interaction["created_at"] = datetime.now().isoformat()
    
    # Aktualizuj statystyki kota
    cat_index = next(i for i, c in enumerate(MOCK_CATS) if c["id"] == cat_id)
    MOCK_CATS[cat_index]["total_interactions"] += 1
    MOCK_CATS[cat_index]["last_interaction"] = datetime.now().isoformat()
    
    # Aktualizuj wskaźnik popularności na podstawie oceny
    if interaction.quality_rating:
        current_score = MOCK_CATS[cat_index]["popularity_score"]
        MOCK_CATS[cat_index]["popularity_score"] = round(
            (current_score * 0.9) + (interaction.quality_rating * 0.1), 1
        )
    
    logger.info(f"Zarejestrowano interakcję z kotem {cat['name']} (ID: {cat_id})")
    
    return CatInteractionData(**new_interaction)


# Funkcje pomocnicze (background tasks)
async def notify_staff_new_cat(cat_name: str, cat_id: int):
    """Powiadomienie personelu o nowym kocie"""
    logger.info(f"📧 Powiadomienie: Nowy kot '{cat_name}' został dodany do systemu (ID: {cat_id})")


async def prepare_cat_space(cat_id: int, special_needs: Optional[str]):
    """Przygotowanie przestrzeni dla nowego kota"""
    logger.info(f"🏠 Przygotowywanie przestrzeni dla kota ID: {cat_id}")
    if special_needs:
        logger.info(f"⚠️ Specjalne potrzeby: {special_needs}")


# Endpoint do zarządzania dostępnością
@router.patch("/{cat_id}/availability", summary="📍 Zmień status dostępności")
async def update_cat_availability(
    cat_id: int = Path(..., description="ID kota"),
    new_status: CatAvailabilityStatus = Body(..., description="Nowy status dostępności"),
    notes: Optional[str] = Body(None, description="Notatki do zmiany statusu"),
    db: Session = Depends(get_db)
):
    """
    📍 Zmień status dostępności kota.
    
    Służy do:
    - Oznaczania kota jako zajętego/wolnego
    - Ustawiania statusów specjalnych (jedzenie, sen, pielęgnacja)
    - Blokowania kota na czas wizyt weterynaryjnych
    - Zarządzania harmonogramem interakcji
    """
    
    # Znajdź kota
    cat_index = next((i for i, cat in enumerate(MOCK_CATS) if cat["id"] == cat_id), None)
    if cat_index is None:
        raise HTTPException(status_code=404, detail="Kot nie znaleziony")
    
    old_status = MOCK_CATS[cat_index]["availability_status"]
    MOCK_CATS[cat_index]["availability_status"] = new_status.value
    MOCK_CATS[cat_index]["updated_at"] = datetime.now().isoformat()
    
    logger.info(f"Zmieniono status dostępności kota {MOCK_CATS[cat_index]['name']}: {old_status} → {new_status.value}")
    
    return {
        "message": f"Status dostępności zmieniony z '{old_status}' na '{new_status.value}'",
        "cat_id": cat_id,
        "old_status": old_status,
        "new_status": new_status.value,
        "notes": notes,
        "updated_at": datetime.now().isoformat()
    }