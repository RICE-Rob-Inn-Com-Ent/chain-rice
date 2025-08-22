"""
🐱 Meowtopia - Modele dla Zarządzania Kotami w Kociej Kawiarni
Autor: System Zarządzania Meowtopia
Data: 2025-01-18

Kompleksowy system zarządzania kotami z pełną logiką biznesową dla kociej kawiarni.
"""

from typing import Optional, List, Dict, Any
from datetime import datetime, date
from enum import Enum
from pydantic import BaseModel, Field, validator
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, Text, Date, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.config import Base


class CatGender(str, Enum):
    """Płeć kota"""
    MALE = "samiec"
    FEMALE = "samica"
    UNKNOWN = "nieznana"


class CatBreed(str, Enum):
    """Rasy kotów - popularne rasy w Polsce"""
    MIXED = "mieszaniec"
    PERSIAN = "pers"
    MAINE_COON = "maine_coon"
    BRITISH_SHORTHAIR = "brytyjczyk_krótkowłosy"
    SIAMESE = "siam"
    RAGDOLL = "ragdoll"
    BENGAL = "bengalczyk"
    ABYSSINIAN = "abisynczyk"
    RUSSIAN_BLUE = "rosyjski_niebieski"
    NORWEGIAN_FOREST = "norweski_leśny"
    SCOTTISH_FOLD = "szkocki_zwisłouchy"
    SPHYNX = "sphynx"
    EXOTIC_SHORTHAIR = "egzotyk_krótkowłosy"


class CatPersonality(str, Enum):
    """Charakter/osobowość kota"""
    FRIENDLY = "przyjazny"
    SHY = "nieśmiały"
    PLAYFUL = "zabawny"
    LAZY = "leniwy"
    AGGRESSIVE = "agresywny"
    CALM = "spokojny"
    CURIOUS = "ciekawski"
    INDEPENDENT = "niezależny"
    AFFECTIONATE = "czuły"
    ENERGETIC = "energiczny"


class CatHealthStatus(str, Enum):
    """Status zdrowia kota"""
    EXCELLENT = "doskonały"
    GOOD = "dobry"
    FAIR = "średni"
    POOR = "słaby"
    SICK = "chory"
    RECOVERING = "zdrowiejący"
    NEEDS_ATTENTION = "wymaga_uwagi"


class CatAvailabilityStatus(str, Enum):
    """Status dostępności kota dla klientów"""
    AVAILABLE = "dostępny"
    BUSY = "zajęty"
    RESTING = "odpoczywa"
    EATING = "je"
    SLEEPING = "śpi"
    PLAYING = "bawi_się"
    GROOMING = "pielęgnuje_się"
    VET_VISIT = "u_weterynarza"
    UNAVAILABLE = "niedostępny"


class AdoptionStatus(str, Enum):
    """Status adopcji"""
    NOT_FOR_ADOPTION = "nie_do_adopcji"
    AVAILABLE_FOR_ADOPTION = "dostępny_do_adopcji"
    PENDING_ADOPTION = "oczekuje_na_adopcję"
    ADOPTED = "adoptowany"
    RESERVED = "zarezerwowany"


# Modele SQLAlchemy (baza danych)
class Cat(Base):
    """Model kota w bazie danych - główna tabela z informacjami o kotach w kawiarni"""
    __tablename__ = "cats"
    
    # Podstawowe informacje
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, index=True, comment="Imię kota")
    chip_id = Column(String(50), unique=True, index=True, comment="Numer chipa identyfikacyjnego")
    
    # Charakterystyka fizyczna
    breed = Column(String(50), default=CatBreed.MIXED, comment="Rasa kota")
    gender = Column(String(20), nullable=False, comment="Płeć kota")
    birth_date = Column(Date, comment="Data urodzenia")
    weight = Column(Float, comment="Waga w kilogramach")
    color = Column(String(100), comment="Kolor sierści")
    distinctive_features = Column(Text, comment="Charakterystyczne cechy")
    
    # Zdjęcia i multimedia
    photo_url = Column(String(500), comment="URL głównego zdjęcia")
    gallery_urls = Column(Text, comment="URLs dodatkowych zdjęć (JSON)")
    
    # Osobowość i zachowanie
    personality = Column(String(50), comment="Główna cecha charakteru")
    personality_traits = Column(Text, comment="Dodatkowe cechy charakteru (JSON)")
    energy_level = Column(Integer, default=5, comment="Poziom energii (1-10)")
    sociability = Column(Integer, default=5, comment="Towarzyskość (1-10)")
    playfulness = Column(Integer, default=5, comment="Zabawność (1-10)")
    
    # Status zdrowia
    health_status = Column(String(50), default=CatHealthStatus.GOOD)
    is_neutered = Column(Boolean, default=False, comment="Czy wykastrowany/wysterylizowany")
    is_vaccinated = Column(Boolean, default=True, comment="Czy szczepiony")
    vaccination_date = Column(Date, comment="Data ostatniego szczepienia")
    medical_notes = Column(Text, comment="Notatki medyczne")
    
    # Status w kawiarni
    availability_status = Column(String(50), default=CatAvailabilityStatus.AVAILABLE)
    arrival_date = Column(Date, comment="Data przyjścia do kawiarni")
    is_resident = Column(Boolean, default=True, comment="Czy to stały mieszkaniec kawiarni")
    
    # Adopcja
    adoption_status = Column(String(50), default=AdoptionStatus.NOT_FOR_ADOPTION)
    adoption_fee = Column(Float, comment="Opłata adopcyjna")
    special_needs = Column(Text, comment="Specjalne potrzeby")
    
    # Ulubione aktywności i preferencje
    favorite_toys = Column(Text, comment="Ulubione zabawki (JSON)")
    favorite_spots = Column(Text, comment="Ulubione miejsca w kawiarni (JSON)")
    food_preferences = Column(Text, comment="Preferencje żywieniowe")
    interaction_notes = Column(Text, comment="Notatki o interakcjach z klientami")
    
    # Statystyki
    total_interactions = Column(Integer, default=0, comment="Całkowita liczba interakcji")
    popularity_score = Column(Float, default=0.0, comment="Wskaźnik popularności")
    last_interaction = Column(DateTime(timezone=True), comment="Ostatnia interakcja")
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relacje
    medical_records = relationship("CatMedicalRecord", back_populates="cat")
    interactions = relationship("CatInteraction", back_populates="cat")
    bookings = relationship("CatBooking", back_populates="cat")


class CatMedicalRecord(Base):
    """Rekordy medyczne kotów"""
    __tablename__ = "cat_medical_records"
    
    id = Column(Integer, primary_key=True, index=True)
    cat_id = Column(Integer, ForeignKey("cats.id"), nullable=False)
    
    date = Column(Date, nullable=False, comment="Data wizyty/badania")
    type = Column(String(50), nullable=False, comment="Typ: szczepienie, badanie, leczenie")
    veterinarian = Column(String(100), comment="Imię i nazwisko weterynarza")
    clinic = Column(String(200), comment="Nazwa kliniki weterynaryjnej")
    
    diagnosis = Column(Text, comment="Diagnoza")
    treatment = Column(Text, comment="Leczenie")
    medications = Column(Text, comment="Leki (JSON)")
    next_visit = Column(Date, comment="Data następnej wizyty")
    cost = Column(Float, comment="Koszt wizyty")
    
    notes = Column(Text, comment="Dodatkowe notatki")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relacje
    cat = relationship("Cat", back_populates="medical_records")


class CatInteraction(Base):
    """Interakcje kotów z klientami"""
    __tablename__ = "cat_interactions"
    
    id = Column(Integer, primary_key=True, index=True)
    cat_id = Column(Integer, ForeignKey("cats.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    staff_id = Column(Integer, ForeignKey("staff.id"), nullable=True)
    
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True))
    duration_minutes = Column(Integer, comment="Czas trwania w minutach")
    
    interaction_type = Column(String(50), comment="Typ: pieszczoty, zabawa, karmienie")
    quality_rating = Column(Integer, comment="Ocena jakości interakcji (1-5)")
    cat_mood_before = Column(String(50), comment="Nastrój kota przed")
    cat_mood_after = Column(String(50), comment="Nastrój kota po")
    
    notes = Column(Text, comment="Notatki z interakcji")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relacje
    cat = relationship("Cat", back_populates="interactions")


class CatBooking(Base):
    """Rezerwacje czasu z konkretnym kotem"""
    __tablename__ = "cat_bookings"
    
    id = Column(Integer, primary_key=True, index=True)
    cat_id = Column(Integer, ForeignKey("cats.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
    
    booking_date = Column(Date, nullable=False)
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=False)
    
    status = Column(String(50), default="potwierdzona", comment="Status rezerwacji")
    special_requests = Column(Text, comment="Specjalne życzenia klienta")
    price = Column(Float, comment="Cena za sesję")
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relacje
    cat = relationship("Cat", back_populates="bookings")


# Modele Pydantic (API/JSON)
class CatProfile(BaseModel):
    """Kompletny profil kota"""
    id: Optional[int] = None
    name: str = Field(..., min_length=1, max_length=100, description="Imię kota")
    chip_id: Optional[str] = Field(None, description="Numer chipa")
    
    # Charakterystyka
    breed: CatBreed = CatBreed.MIXED
    gender: CatGender
    birth_date: Optional[date] = None
    age_months: Optional[int] = Field(None, description="Wiek w miesiącach (obliczany automatycznie)")
    weight: Optional[float] = Field(None, ge=0.5, le=15.0, description="Waga w kg")
    color: Optional[str] = None
    distinctive_features: Optional[str] = None
    
    # Multimedia
    photo_url: Optional[str] = None
    gallery_urls: Optional[List[str]] = []
    
    # Osobowość
    personality: Optional[CatPersonality] = None
    personality_traits: Optional[List[str]] = []
    energy_level: int = Field(5, ge=1, le=10, description="Poziom energii")
    sociability: int = Field(5, ge=1, le=10, description="Towarzyskość")  
    playfulness: int = Field(5, ge=1, le=10, description="Zabawność")
    
    # Zdrowie
    health_status: CatHealthStatus = CatHealthStatus.GOOD
    is_neutered: bool = False
    is_vaccinated: bool = True
    vaccination_date: Optional[date] = None
    medical_notes: Optional[str] = None
    
    # Status
    availability_status: CatAvailabilityStatus = CatAvailabilityStatus.AVAILABLE
    arrival_date: Optional[date] = None
    is_resident: bool = True
    
    # Adopcja
    adoption_status: AdoptionStatus = AdoptionStatus.NOT_FOR_ADOPTION
    adoption_fee: Optional[float] = Field(None, ge=0, description="Opłata adopcyjna")
    special_needs: Optional[str] = None
    
    # Preferencje
    favorite_toys: Optional[List[str]] = []
    favorite_spots: Optional[List[str]] = []
    food_preferences: Optional[str] = None
    interaction_notes: Optional[str] = None
    
    # Statystyki
    total_interactions: int = 0
    popularity_score: float = 0.0
    last_interaction: Optional[datetime] = None
    
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    @validator('age_months', always=True)
    def calculate_age(cls, v, values):
        """Automatyczne obliczanie wieku na podstawie daty urodzenia"""
        if 'birth_date' in values and values['birth_date']:
            today = date.today()
            birth = values['birth_date']
            age_months = (today.year - birth.year) * 12 + today.month - birth.month
            return max(0, age_months)
        return v

    class Config:
        from_attributes = True
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            date: lambda d: d.isoformat()
        }


class CreateCatProfile(BaseModel):
    """Model do tworzenia nowego profilu kota"""
    name: str = Field(..., min_length=1, max_length=100)
    chip_id: Optional[str] = None
    breed: CatBreed = CatBreed.MIXED
    gender: CatGender
    birth_date: Optional[date] = None
    weight: Optional[float] = Field(None, ge=0.5, le=15.0)
    color: Optional[str] = None
    distinctive_features: Optional[str] = None
    photo_url: Optional[str] = None
    personality: Optional[CatPersonality] = None
    energy_level: int = Field(5, ge=1, le=10)
    sociability: int = Field(5, ge=1, le=10)
    playfulness: int = Field(5, ge=1, le=10)
    health_status: CatHealthStatus = CatHealthStatus.GOOD
    is_neutered: bool = False
    is_vaccinated: bool = True
    vaccination_date: Optional[date] = None
    adoption_status: AdoptionStatus = AdoptionStatus.NOT_FOR_ADOPTION
    adoption_fee: Optional[float] = None
    special_needs: Optional[str] = None


class UpdateCatProfile(BaseModel):
    """Model do aktualizacji profilu kota"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    chip_id: Optional[str] = None
    breed: Optional[CatBreed] = None
    weight: Optional[float] = Field(None, ge=0.5, le=15.0)
    color: Optional[str] = None
    distinctive_features: Optional[str] = None
    photo_url: Optional[str] = None
    personality: Optional[CatPersonality] = None
    energy_level: Optional[int] = Field(None, ge=1, le=10)
    sociability: Optional[int] = Field(None, ge=1, le=10)
    playfulness: Optional[int] = Field(None, ge=1, le=10)
    health_status: Optional[CatHealthStatus] = None
    is_neutered: Optional[bool] = None
    is_vaccinated: Optional[bool] = None
    vaccination_date: Optional[date] = None
    medical_notes: Optional[str] = None
    availability_status: Optional[CatAvailabilityStatus] = None
    adoption_status: Optional[AdoptionStatus] = None
    adoption_fee: Optional[float] = Field(None, ge=0)
    special_needs: Optional[str] = None
    interaction_notes: Optional[str] = None


class CatMedicalRecordData(BaseModel):
    """Dane rekordu medycznego"""
    id: Optional[int] = None
    cat_id: int
    date: date
    type: str = Field(..., description="Typ: szczepienie, badanie, leczenie, kontrola")
    veterinarian: Optional[str] = None
    clinic: Optional[str] = None
    diagnosis: Optional[str] = None
    treatment: Optional[str] = None
    medications: Optional[List[str]] = []
    next_visit: Optional[date] = None
    cost: Optional[float] = Field(None, ge=0)
    notes: Optional[str] = None
    created_at: Optional[datetime] = None


class CatInteractionData(BaseModel):
    """Dane interakcji z kotem"""
    id: Optional[int] = None
    cat_id: int
    customer_id: Optional[int] = None
    staff_id: Optional[int] = None
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_minutes: Optional[int] = Field(None, ge=0)
    interaction_type: str = Field(..., description="pieszczoty, zabawa, karmienie, sesja_zdjęciowa")
    quality_rating: Optional[int] = Field(None, ge=1, le=5)
    cat_mood_before: Optional[str] = None
    cat_mood_after: Optional[str] = None
    notes: Optional[str] = None
    created_at: Optional[datetime] = None


class CatBookingData(BaseModel):
    """Dane rezerwacji z kotem"""
    id: Optional[int] = None
    cat_id: int
    customer_id: int
    booking_date: date
    start_time: datetime
    end_time: datetime
    status: str = "potwierdzona"
    special_requests: Optional[str] = None
    price: Optional[float] = Field(None, ge=0)
    created_at: Optional[datetime] = None


class CatStatistics(BaseModel):
    """Statystyki kotów w kawiarni"""
    total_cats: int
    available_cats: int
    cats_for_adoption: int
    adopted_this_month: int
    most_popular_cat: Optional[Dict[str, Any]]
    breed_distribution: Dict[str, int]
    age_distribution: Dict[str, int]
    health_status_summary: Dict[str, int]
    interaction_stats: Dict[str, Any]
    

class CatsListResponse(BaseModel):
    """Odpowiedź z listą kotów"""
    cats: List[CatProfile]
    total: int
    page: int
    per_page: int
    pages: int
    has_next: bool
    has_prev: bool
    
    
class CatSearchFilters(BaseModel):
    """Filtry wyszukiwania kotów"""
    name: Optional[str] = None
    breed: Optional[CatBreed] = None
    gender: Optional[CatGender] = None
    age_min_months: Optional[int] = Field(None, ge=0)
    age_max_months: Optional[int] = Field(None, le=300)
    personality: Optional[CatPersonality] = None
    availability_status: Optional[CatAvailabilityStatus] = None
    adoption_status: Optional[AdoptionStatus] = None
    health_status: Optional[CatHealthStatus] = None
    is_neutered: Optional[bool] = None
    energy_level_min: Optional[int] = Field(None, ge=1, le=10)
    energy_level_max: Optional[int] = Field(None, ge=1, le=10)
    sociability_min: Optional[int] = Field(None, ge=1, le=10)
    playfulness_min: Optional[int] = Field(None, ge=1, le=10)