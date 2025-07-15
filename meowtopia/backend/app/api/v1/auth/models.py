from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

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

class RegisterRequest(BaseModel):
    fullName: str
    email: EmailStr
    password: str
    confirmPassword: str
    terms: bool
    marketing: Optional[bool] = False

class RegisterResponse(LoginResponse):
    pass

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    password: str
    confirmPassword: str

class VerifyEmailRequest(BaseModel):
    token: str

class ResendVerificationRequest(BaseModel):
    email: EmailStr

class ProfileResponse(BaseModel):
    id: str
    email: EmailStr
    fullName: str
    role: str
    avatar: Optional[str]
    emailVerified: bool
    createdAt: datetime
    lastLogin: Optional[datetime]

class UpdateProfileRequest(BaseModel):
    fullName: Optional[str]
    avatar: Optional[str]

class ChangePasswordRequest(BaseModel):
    oldPassword: str
    newPassword: str
    confirmPassword: str

class ChangePasswordResponse(BaseModel):
    message: str

class UploadAvatarResponse(BaseModel):
    avatarUrl: str
