from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, timedelta
import jwt
from passlib.context import CryptContext

router = APIRouter(prefix="/auth", tags=["Authentication"])

# Security
security = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Pydantic models for request/response
class UserRegister(BaseModel):
    """User registration request model"""
    username: str
    email: EmailStr
    password: str
    wallet_address: Optional[str] = None

class UserLogin(BaseModel):
    """User login request model"""
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    """JWT token response model"""
    access_token: str
    token_type: str
    expires_in: int
    user_id: str
    username: str

class UserProfile(BaseModel):
    """User profile response model"""
    id: str
    username: str
    email: EmailStr
    wallet_address: Optional[str]
    game_level: int = 1
    mwt_balance: float = 0.0
    cats_owned: int = 0
    created_at: datetime
    last_login: Optional[datetime]

# Mock database (replace with actual database)
users_db = {}
tokens_db = {}

SECRET_KEY = "your-secret-key-here"  # In production, use environment variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash password"""
    return pwd_context.hash(password)

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current authenticated user"""
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = users_db.get(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register_user(user_data: UserRegister):
    """
    🆕 **Register New User**
    
    Create a new user account for the Meowtopia virtual cat universe.
    
    - **username**: Unique username for the account
    - **email**: Valid email address
    - **password**: Secure password (min 8 characters)
    - **wallet_address**: Optional blockchain wallet address
    
    Returns JWT token for immediate authentication.
    """
    # Check if user already exists
    for user in users_db.values():
        if user["email"] == user_data.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        if user["username"] == user_data.username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
    
    # Create new user
    user_id = f"user_{len(users_db) + 1}"
    hashed_password = get_password_hash(user_data.password)
    
    new_user = {
        "id": user_id,
        "username": user_data.username,
        "email": user_data.email,
        "hashed_password": hashed_password,
        "wallet_address": user_data.wallet_address,
        "game_level": 1,
        "mwt_balance": 100.0,  # Starting balance
        "cats_owned": 0,
        "created_at": datetime.utcnow(),
        "last_login": datetime.utcnow()
    }
    
    users_db[user_id] = new_user
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user_id}, expires_delta=access_token_expires
    )
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user_id,
        username=user_data.username
    )

@router.post("/login", response_model=TokenResponse)
async def login_user(user_data: UserLogin):
    """
    🔐 **User Login**
    
    Authenticate user and receive JWT token for API access.
    
    - **email**: Registered email address
    - **password**: Account password
    
    Returns JWT token for API authentication.
    """
    # Find user by email
    user = None
    for u in users_db.values():
        if u["email"] == user_data.email:
            user = u
            break
    
    if not user or not verify_password(user_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Update last login
    user["last_login"] = datetime.utcnow()
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["id"]}, expires_delta=access_token_expires
    )
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user["id"],
        username=user["username"]
    )

@router.get("/me", response_model=UserProfile)
async def get_current_user_profile(current_user: dict = Depends(get_current_user)):
    """
    👤 **Get Current User Profile**
    
    Retrieve the profile information for the currently authenticated user.
    
    Requires JWT authentication.
    """
    return UserProfile(
        id=current_user["id"],
        username=current_user["username"],
        email=current_user["email"],
        wallet_address=current_user["wallet_address"],
        game_level=current_user["game_level"],
        mwt_balance=current_user["mwt_balance"],
        cats_owned=current_user["cats_owned"],
        created_at=current_user["created_at"],
        last_login=current_user["last_login"]
    )

@router.post("/logout")
async def logout_user(current_user: dict = Depends(get_current_user)):
    """
    🚪 **User Logout**
    
    Logout the current user (invalidate JWT token).
    
    Requires JWT authentication.
    """
    # In a real implementation, you would blacklist the token
    # For now, we'll just return a success message
    return {"message": "Successfully logged out"} 