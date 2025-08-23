from fastapi import APIRouter, UploadFile, File, status, Depends, HTTPException
from sqlalchemy.orm import Session
from app.config import SessionLocal
from .models import (
    User, LoginRequest, LoginResponse, RegisterRequest, RegisterResponse,
    ForgotPasswordRequest, ResetPasswordRequest, VerifyEmailRequest,
)
from .jwt import (
    verify_password, get_password_hash, create_access_token,
    get_current_user, require_admin, get_current_user_role
)
from datetime import datetime, timedelta
import os
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from typing import List

router = APIRouter(tags=["Authentication & Security"])

security = HTTPBasic()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/login", response_model=LoginResponse)
async def login_user(data: LoginRequest, db: Session = Depends(get_db)):
    """Login User"""
    # Find user by email
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Verify password
    if not verify_password(data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Create access token with user info including role
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "email": user.email,
            "fullName": user.fullName,
            "role": user.role
        },
        expires_delta=access_token_expires
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=1800,  # 30 minutes in seconds
        user_id=str(user.id),
        fullName=user.fullName if isinstance(user.fullName, str) else getattr(user, "fullName", ""),
        role=user.role
    )

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register_user(data: RegisterRequest, db: Session = Depends(get_db)):
    """Register User"""
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Hash password
    hashed_password = get_password_hash(data.password)
    
    # Create user with default role "user"
    user = User(
        fullName=data.fullName,
        email=data.email,
        password=hashed_password,
        role="user",  # Default role for new users
        terms=data.terms,
        firstName=data.firstName,
        lastName=data.lastName,
        username=data.username,
        phone=data.phone,
        privacy=data.privacy,
        cookies=data.cookies,
        aml=data.aml,
        mica=data.mica,
        marketing=data.marketing,
        newsletter=data.newsletter,
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create access token for newly registered user
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "email": user.email,
            "fullName": user.fullName,
            "role": user.role
        },
        expires_delta=access_token_expires
    )
    
    return RegisterResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=1800,
        user_id=str(user.id),
        fullName=user.fullName if isinstance(user.fullName, str) else getattr(user, "fullName", ""),
        role=user.role
    )

@router.post("/logout")
async def logout_user():
    """Logout User"""
    return {"message": "Successfully logged out"}

@router.post("/refresh", response_model=LoginResponse)
async def refresh_token(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    """Refresh JWT Token"""
    # Get fresh user data from database
    user = db.query(User).filter(User.id == int(current_user["sub"])).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Create new access token
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "email": user.email,
            "fullName": user.fullName,
            "role": user.role
        },
        expires_delta=access_token_expires
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=1800,
        user_id=str(user.id),
        fullName=user.fullName if isinstance(user.fullName, str) else getattr(user, "fullName", ""),
        role=user.role
    )

@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest):
    """Request password reset email"""
    return {"message": "If the email exists, a reset link was sent."}

@router.post("/reset-password")
async def reset_password(data: ResetPasswordRequest):
    """Reset user password"""
    return {"message": "Password has been reset."}

@router.post("/verify-email")
async def verify_email(data: VerifyEmailRequest):
    """Verify user email address"""
    return {"message": "Email verified."}

@router.get("/me")
async def get_current_user_info(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get current user information"""
    user = db.query(User).filter(User.id == int(current_user["sub"])).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "id": user.id,
        "email": user.email,
        "fullName": user.fullName,
        "role": user.role,
        "firstName": user.firstName,
        "lastName": user.lastName,
        "username": user.username,
        "phone": user.phone,
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }

@router.get("/users", response_model=List[dict])
async def get_users(db: Session = Depends(get_db), current_user: dict = Depends(require_admin)):
    """Pobiera listę wszystkich użytkowników (tylko dla adminów)"""
    users = db.query(User).all()
    
    return [
        {
            "id": user.id,
            "fullName": user.fullName,
            "email": user.email,
            "role": user.role,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "username": user.username,
            "phone": user.phone,
            "terms": user.terms,
            "privacy": user.privacy,
            "cookies": user.cookies,
            "aml": user.aml,
            "mica": user.mica,
            "marketing": user.marketing,
            "newsletter": user.newsletter,
            "created_at": user.created_at,
            "updated_at": user.updated_at,
        }
        for user in users
    ]

@router.get("/get-user-id")
def get_user_id(current_user: dict = Depends(get_current_user)):
    """Pobiera ID aktualnego użytkownika"""
    return {"user_id": current_user["sub"], "role": current_user["role"]}

@router.get("/user/{user_id}", response_model=dict)
async def get_user_by_id(user_id: int, db: Session = Depends(get_db), current_user: dict = Depends(require_admin)):
    """Pobiera konkretnego użytkownika po ID (tylko dla adminów)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "id": user.id,
        "fullName": user.fullName,
        "email": user.email,
        "role": user.role,
        "firstName": user.firstName,
        "lastName": user.lastName,
        "username": user.username,
        "phone": user.phone,
        "terms": user.terms,
        "privacy": user.privacy,
        "cookies": user.cookies,
        "aml": user.aml,
        "mica": user.mica,
        "marketing": user.marketing,
        "newsletter": user.newsletter,
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }

@router.get("/security/env")
def get_env_vars(current_user: dict = Depends(require_admin)):
    """Get environment variables (admin only)"""
    env_vars = {k: v for k, v in os.environ.items() if k.startswith("SMTP_") or k.startswith("EMAIL_")}
    return {
        "env_vars": env_vars,
        "quantum_warning": "WARNING: Quantum computers may break current cryptography in the future. Rotate credentials regularly and use post-quantum algorithms when available."
    }

# Admin-only endpoint to create admin user
@router.post("/create-admin", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def create_admin_user(data: RegisterRequest, db: Session = Depends(get_db)):
    """Create admin user (for initial setup)"""
    # Check if admin already exists
    if db.query(User).filter(User.role == "admin").first():
        raise HTTPException(status_code=400, detail="Admin user already exists")
    
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Hash password
    hashed_password = get_password_hash(data.password)
    
    # Create admin user
    user = User(
        fullName=data.fullName,
        email=data.email,
        password=hashed_password,
        role="admin",  # Admin role
        terms=data.terms,
        firstName=data.firstName,
        lastName=data.lastName,
        username=data.username,
        phone=data.phone,
        privacy=data.privacy,
        cookies=data.cookies,
        aml=data.aml,
        mica=data.mica,
        marketing=data.marketing,
        newsletter=data.newsletter,
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create access token
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "email": user.email,
            "fullName": user.fullName,
            "role": user.role
        },
        expires_delta=access_token_expires
    )
    
    return RegisterResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=1800,
        user_id=str(user.id),
        fullName=user.fullName if isinstance(user.fullName, str) else getattr(user, "fullName", ""),
        role=user.role
    )
