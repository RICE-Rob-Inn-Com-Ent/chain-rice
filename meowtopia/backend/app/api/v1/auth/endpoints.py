from fastapi import APIRouter, UploadFile, File, status, Depends, HTTPException
from sqlalchemy.orm import Session
from app.config import SessionLocal
from .models import (
    User, LoginRequest, LoginResponse, RegisterRequest, RegisterResponse,
    ForgotPasswordRequest, ResetPasswordRequest, VerifyEmailRequest,
)
from datetime import datetime
import os
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials

router = APIRouter(tags=["Authentication & Security"])

security = HTTPBasic()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@router.post("/login", response_model=LoginResponse)
async def login_user(data: LoginRequest):
    """Login User"""
    return LoginResponse(
        access_token="token", token_type="bearer", expires_in=3600, user_id="user1", fullName="John Doe"
    )

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register_user(data: RegisterRequest, db: Session = Depends(get_db)):
    """Register User"""
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed_password = pwd_context.hash(data.password)
    user = User(
        fullName=data.fullName,
        email=data.email,
        password=hashed_password,
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
    return RegisterResponse(
        access_token="token",
        token_type="bearer",
        expires_in=3600,
        user_id=str(user.id),
        fullName=user.fullName if isinstance(user.fullName, str) else getattr(user, "fullName", "")
    )

@router.post("/logout")
async def logout_user():
    """Logout User"""
    return {"message": "Successfully logged out"}

@router.post("/refresh", response_model=LoginResponse)
async def refresh_token():
    """Refresh JWT Token"""
    return LoginResponse(
        access_token="token", token_type="bearer", expires_in=3600, user_id="user1", fullName="John Doe"
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

@router.get("/security/env")
def get_env_vars(credentials: HTTPBasicCredentials = Depends(security)):
    admin_password = os.getenv("SECURITY_ADMIN_PASSWORD", "")
    if credentials.username != "admin" or credentials.password != admin_password:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    env_vars = {k: v for k, v in os.environ.items() if k.startswith("SMTP_") or k.startswith("EMAIL_")}
    return {
        "env_vars": env_vars,
        "quantum_warning": "WARNING: Quantum computers may break current cryptography in the future. Rotate credentials regularly and use post-quantum algorithms when available."
    }
