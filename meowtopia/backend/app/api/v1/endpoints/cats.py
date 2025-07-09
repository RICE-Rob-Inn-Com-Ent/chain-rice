from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum
import uuid

from .auth import get_current_user

router = APIRouter(prefix="/cats", tags=["Cats"])

# Enums
class CatRarity(str, Enum):
    """Cat rarity levels"""
    COMMON = "common"
    RARE = "rare"
    EPIC = "epic"
    LEGENDARY = "legendary"

class CatActivity(str, Enum):
    """Cat activity types"""
    FEED = "feed"
    PLAY = "play"
    TRAIN = "train"
    SLEEP = "sleep"

# Pydantic models
class CatBase(BaseModel):
    """Base cat model"""
    name: str = Field(..., min_length=1, max_length=50, description="Cat's name")
    rarity: CatRarity = Field(..., description="Cat's rarity level")
    breed: str = Field(..., description="Cat's breed")

class CatCreate(CatBase):
    """Cat creation request model"""
    pass

class CatResponse(CatBase):
    """Cat response model"""
    id: str
    owner_id: str
    level: int = Field(1, ge=1, description="Cat's current level")
    experience: int = Field(0, ge=0, description="Current experience points")
    energy: int = Field(100, ge=0, le=100, description="Current energy (0-100)")
    max_energy: int = Field(100, ge=100, description="Maximum energy capacity")
    
    # Attributes
    cuteness: int = Field(50, ge=0, le=100, description="Cuteness attribute")
    playfulness: int = Field(50, ge=0, le=100, description="Playfulness attribute")
    intelligence: int = Field(50, ge=0, le=100, description="Intelligence attribute")
    
    # Game state
    is_available: bool = Field(True, description="Whether cat can perform activities")
    last_activity: Optional[datetime] = Field(None, description="Last activity timestamp")
    created_at: datetime
    updated_at: datetime

class CatActivityRequest(BaseModel):
    """Cat activity request model"""
    activity: CatActivity = Field(..., description="Type of activity to perform")
    duration_minutes: Optional[int] = Field(30, ge=1, le=480, description="Activity duration in minutes")

class CatActivityResponse(BaseModel):
    """Cat activity response model"""
    cat_id: str
    activity: CatActivity
    success: bool
    energy_cost: int
    energy_remaining: int
    mwt_earned: Optional[float] = None
    mwt_cost: Optional[float] = None
    experience_gained: int
    new_level: Optional[int] = None
    message: str

class CatBreedingRequest(BaseModel):
    """Cat breeding request model"""
    cat1_id: str = Field(..., description="First cat's ID")
    cat2_id: str = Field(..., description="Second cat's ID")

class CatBreedingResponse(BaseModel):
    """Cat breeding response model"""
    success: bool
    new_cat: Optional[CatResponse] = None
    mwt_cost: float
    message: str

# Mock database
cats_db = {}

def generate_cat_stats(rarity: CatRarity) -> dict:
    """Generate cat statistics based on rarity"""
    base_stats = {
        "cuteness": 50,
        "playfulness": 50,
        "intelligence": 50
    }
    
    rarity_multipliers = {
        CatRarity.COMMON: 1.0,
        CatRarity.RARE: 1.2,
        CatRarity.EPIC: 1.5,
        CatRarity.LEGENDARY: 2.0
    }
    
    multiplier = rarity_multipliers[rarity]
    return {
        "cuteness": int(base_stats["cuteness"] * multiplier),
        "playfulness": int(base_stats["playfulness"] * multiplier),
        "intelligence": int(base_stats["intelligence"] * multiplier)
    }

@router.post("/", response_model=CatResponse, status_code=status.HTTP_201_CREATED)
async def create_cat(cat_data: CatCreate, current_user: dict = Depends(get_current_user)):
    """
    🐱 **Create New Cat**
    
    Create a new virtual cat for the current user.
    
    - **name**: Cat's name (1-50 characters)
    - **rarity**: Cat's rarity level (common, rare, epic, legendary)
    - **breed**: Cat's breed type
    
    Returns the newly created cat with generated attributes.
    """
    cat_id = str(uuid.uuid4())
    stats = generate_cat_stats(cat_data.rarity)
    
    new_cat = {
        "id": cat_id,
        "owner_id": current_user["id"],
        "name": cat_data.name,
        "rarity": cat_data.rarity,
        "breed": cat_data.breed,
        "level": 1,
        "experience": 0,
        "energy": 100,
        "max_energy": 100,
        "cuteness": stats["cuteness"],
        "playfulness": stats["playfulness"],
        "intelligence": stats["intelligence"],
        "is_available": True,
        "last_activity": None,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    cats_db[cat_id] = new_cat
    
    # Update user's cat count
    current_user["cats_owned"] += 1
    
    return CatResponse(**new_cat)

@router.get("/", response_model=List[CatResponse])
async def get_user_cats(current_user: dict = Depends(get_current_user)):
    """
    📋 **Get User's Cats**
    
    Retrieve all cats owned by the current user.
    
    Returns a list of all user's cats with their current status.
    """
    user_cats = [
        CatResponse(**cat) for cat in cats_db.values()
        if cat["owner_id"] == current_user["id"]
    ]
    return user_cats

@router.get("/{cat_id}", response_model=CatResponse)
async def get_cat(cat_id: str, current_user: dict = Depends(get_current_user)):
    """
    🐱 **Get Cat Details**
    
    Retrieve detailed information about a specific cat.
    
    - **cat_id**: Unique identifier of the cat
    
    Returns detailed cat information including attributes and status.
    """
    cat = cats_db.get(cat_id)
    if not cat:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cat not found"
        )
    
    if cat["owner_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this cat"
        )
    
    return CatResponse(**cat)

@router.post("/{cat_id}/activity", response_model=CatActivityResponse)
async def perform_cat_activity(
    cat_id: str,
    activity_data: CatActivityRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    🎮 **Perform Cat Activity**
    
    Perform an activity with a cat (feed, play, train, sleep).
    
    - **cat_id**: ID of the cat to interact with
    - **activity**: Type of activity (feed, play, train, sleep)
    - **duration_minutes**: Duration of the activity (1-480 minutes)
    
    Returns the result of the activity including energy changes and rewards.
    """
    cat = cats_db.get(cat_id)
    if not cat:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cat not found"
        )
    
    if cat["owner_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to interact with this cat"
        )
    
    if not cat["is_available"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cat is not available for activities"
        )
    
    # Activity costs and rewards
    activity_config = {
        CatActivity.FEED: {
            "energy_cost": 0,
            "energy_gain": 20,
            "mwt_cost": 10.0,
            "mwt_earned": 0,
            "exp_gain": 5
        },
        CatActivity.PLAY: {
            "energy_cost": 20,
            "energy_gain": 0,
            "mwt_cost": 0,
            "mwt_earned": 15.0,
            "exp_gain": 10
        },
        CatActivity.TRAIN: {
            "energy_cost": 30,
            "energy_gain": 0,
            "mwt_cost": 0,
            "mwt_earned": 0,
            "exp_gain": 20
        },
        CatActivity.SLEEP: {
            "energy_cost": 0,
            "energy_gain": 50,
            "mwt_cost": 0,
            "mwt_earned": 0,
            "exp_gain": 2
        }
    }
    
    config = activity_config[activity_data.activity]
    
    # Check if user has enough MWT for feeding
    if config["mwt_cost"] > 0 and current_user["mwt_balance"] < config["mwt_cost"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient MWT balance"
        )
    
    # Check if cat has enough energy
    if config["energy_cost"] > 0 and cat["energy"] < config["energy_cost"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cat doesn't have enough energy"
        )
    
    # Perform activity
    old_level = cat["level"]
    cat["energy"] = max(0, min(100, cat["energy"] - config["energy_cost"] + config["energy_gain"]))
    cat["experience"] += config["exp_gain"]
    cat["last_activity"] = datetime.utcnow()
    cat["updated_at"] = datetime.utcnow()
    
    # Level up check (every 100 exp)
    new_level = (cat["experience"] // 100) + 1
    if new_level > cat["level"]:
        cat["level"] = new_level
        cat["max_energy"] += 10  # Increase max energy with level
    
    # Update user balance
    if config["mwt_cost"] > 0:
        current_user["mwt_balance"] -= config["mwt_cost"]
    if config["mwt_earned"] > 0:
        current_user["mwt_balance"] += config["mwt_earned"]
    
    return CatActivityResponse(
        cat_id=cat_id,
        activity=activity_data.activity,
        success=True,
        energy_cost=config["energy_cost"],
        energy_remaining=cat["energy"],
        mwt_earned=config["mwt_earned"] if config["mwt_earned"] > 0 else None,
        mwt_cost=config["mwt_cost"] if config["mwt_cost"] > 0 else None,
        experience_gained=config["exp_gain"],
        new_level=new_level if new_level > old_level else None,
        message=f"Successfully performed {activity_data.activity} activity!"
    )

@router.post("/breed", response_model=CatBreedingResponse)
async def breed_cats(
    breeding_data: CatBreedingRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    🐱❤️ **Breed Cats**
    
    Breed two cats to create a new offspring.
    
    - **cat1_id**: First cat's ID
    - **cat2_id**: Second cat's ID
    
    Returns the new cat if breeding is successful.
    """
    cat1 = cats_db.get(breeding_data.cat1_id)
    cat2 = cats_db.get(breeding_data.cat2_id)
    
    if not cat1 or not cat2:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="One or both cats not found"
        )
    
    if cat1["owner_id"] != current_user["id"] or cat2["owner_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to breed these cats"
        )
    
    if cat1["id"] == cat2["id"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot breed a cat with itself"
        )
    
    # Breeding cost
    breeding_cost = 50.0
    if current_user["mwt_balance"] < breeding_cost:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient MWT balance for breeding"
        )
    
    # Create offspring
    offspring_id = str(uuid.uuid4())
    offspring_name = f"{cat1['name']} + {cat2['name']}'s Baby"
    
    # Determine offspring rarity (simplified logic)
    parent_rarities = [cat1["rarity"], cat2["rarity"]]
    if CatRarity.LEGENDARY in parent_rarities:
        offspring_rarity = CatRarity.EPIC
    elif CatRarity.EPIC in parent_rarities:
        offspring_rarity = CatRarity.RARE
    else:
        offspring_rarity = CatRarity.COMMON
    
    stats = generate_cat_stats(offspring_rarity)
    
    offspring = {
        "id": offspring_id,
        "owner_id": current_user["id"],
        "name": offspring_name,
        "rarity": offspring_rarity,
        "breed": f"Mixed {cat1['breed']}-{cat2['breed']}",
        "level": 1,
        "experience": 0,
        "energy": 100,
        "max_energy": 100,
        "cuteness": stats["cuteness"],
        "playfulness": stats["playfulness"],
        "intelligence": stats["intelligence"],
        "is_available": True,
        "last_activity": None,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    cats_db[offspring_id] = offspring
    
    # Update user stats
    current_user["mwt_balance"] -= breeding_cost
    current_user["cats_owned"] += 1
    
    return CatBreedingResponse(
        success=True,
        new_cat=CatResponse(**offspring),
        mwt_cost=breeding_cost,
        message="Breeding successful! New cat created."
    ) 