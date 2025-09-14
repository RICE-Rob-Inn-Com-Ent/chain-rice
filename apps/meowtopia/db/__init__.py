import os
import sys
import dotenv
import logging
import traceback
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel
from typing import Optional
from jwt_auth import (
    authenticate_user, 
    create_access_token, 
    verify_token, 
    get_user_by_email,
    get_user_by_id,
    check_user_permission
)

# Load environment variables
dotenv.load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Chain Rice Database API",
    description="Database service for Chain Rice blockchain application",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "database"}

# Pydantic models
class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: dict

class UserResponse(BaseModel):
    id: int
    email: str
    role: str
    is_active: bool

# Authentication dependency
async def get_current_user(token: str = Depends(lambda: None)):
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    try:
        payload = verify_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        user = get_user_by_id(int(user_id))
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        return user
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

# Authentication endpoints
@app.post("/auth/login", response_model=TokenResponse)
async def login(login_data: LoginRequest):
    """Authenticate user and return JWT token."""
    user = authenticate_user(login_data.email, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    access_token = create_access_token(data={"sub": str(user["id"])})
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user={
            "id": user["id"],
            "email": user["email"],
            "role": user["role"],
            "is_active": user["is_active"]
        }
    )

@app.get("/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    """Get current user information."""
    return UserResponse(
        id=current_user["id"],
        email=current_user["email"],
        role=current_user["role"],
        is_active=current_user["is_active"]
    )

@app.post("/auth/verify")
async def verify_auth(token: str):
    """Verify if token is valid."""
    try:
        payload = verify_token(token)
        user_id = payload.get("sub")
        if user_id:
            user = get_user_by_id(int(user_id))
            if user:
                return {
                    "valid": True,
                    "user": {
                        "id": user["id"],
                        "email": user["email"],
                        "role": user["role"],
                        "is_active": user["is_active"]
                    }
                }
        return {"valid": False}
    except:
        return {"valid": False}

@app.get("/auth/check-permission")
async def check_permission(role: str, current_user: dict = Depends(get_current_user)):
    """Check if current user has required permission."""
    has_permission = check_user_permission(current_user, role)
    return {"has_permission": has_permission}

# Root endpoint
@app.get("/")
async def root():
    return {"message": "Chain Rice Database API", "version": "1.0.0"}