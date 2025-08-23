from typing import Optional
from datetime import datetime as dt
from pydantic import BaseModel, EmailStr
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from app.config import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    fullName = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False, index=True)
    password = Column(String, nullable=False)
    role = Column(String, nullable=False, default="user")  # "admin" or "user"
    terms = Column(Boolean, nullable=False)
    firstName = Column(String, nullable=True)
    lastName = Column(String, nullable=True)
    username = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    privacy = Column(Boolean, nullable=True)
    cookies = Column(Boolean, nullable=True)
    aml = Column(Boolean, nullable=True)
    mica = Column(Boolean, nullable=True)
    marketing = Column(Boolean, nullable=True)
    newsletter = Column(Boolean, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    rememberMe: Optional[bool] = False

class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int
    user_id: str
    fullName: str
    role: str  # Added role field

class RegisterRequest(BaseModel):
    fullName: str
    email: EmailStr
    password: str
    confirmPassword: str
    terms: bool
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    username: Optional[str] = None
    phone: Optional[str] = None
    privacy: Optional[bool] = None
    cookies: Optional[bool] = None
    aml: Optional[bool] = None
    mica: Optional[bool] = None
    marketing: Optional[bool] = False
    newsletter: Optional[bool] = False

class RegisterResponse(LoginResponse):
    pass

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    password: str
    confirmPassword: str

class VerifyEmailRequest(BaseModel):
    token: str

