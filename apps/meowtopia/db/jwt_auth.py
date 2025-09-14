import os
import jwt
import hashlib
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from fastapi import HTTPException, status
from passlib.context import CryptContext

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT settings
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Test users database (in production, use a real database)
TEST_USERS = {
    "admin@test.com": {
        "id": 1,
        "email": "admin@test.com",
        "password": "$2b$12$DJNI7DdqswB45D9aOO7YuewWWk5zEdHiZGwoyFDZSYLt4IWPx1XkO",  # "admin123"
        "role": "admin",
        "is_active": True
    },
    "user@test.com": {
        "id": 2,
        "email": "user@test.com", 
        "password": "$2b$12$CT0xPQswx55nQ36PrSvCb.gIQPZgsD.uuamnSWGc9R1gvUgYnl.WW",  # "user123"
        "role": "user",
        "is_active": True
    }
}

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash a password."""
    return pwd_context.hash(password)

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify and decode a JWT token."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

def authenticate_user(email: str, password: str) -> Optional[Dict[str, Any]]:
    """Authenticate a user with email and password."""
    user = TEST_USERS.get(email)
    if not user:
        return None
    if not verify_password(password, user["password"]):
        return None
    return user

def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    """Get user by email."""
    return TEST_USERS.get(email)

def get_user_by_id(user_id: int) -> Optional[Dict[str, Any]]:
    """Get user by ID."""
    for user in TEST_USERS.values():
        if user["id"] == user_id:
            return user
    return None

def check_user_permission(user: Dict[str, Any], required_role: str) -> bool:
    """Check if user has required permission."""
    if not user or not user.get("is_active"):
        return False
    
    if required_role == "admin":
        return user.get("role") == "admin"
    elif required_role == "user":
        return user.get("role") in ["admin", "user"]
    
    return False
