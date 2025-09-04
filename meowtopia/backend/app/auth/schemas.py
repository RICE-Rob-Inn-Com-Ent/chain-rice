from typing import Optional, Literal
from pydantic import BaseModel, EmailStr, Field


class TokenResponse(BaseModel):
    access_token: Optional[str] = None
    token_type: Literal["bearer"] = "bearer"
    requires_2fa: Optional[bool] = None
    temp_token: Optional[str] = None


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    twofa_code: Optional[str] = None


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=6, max_length=128)


class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str = Field(min_length=6, max_length=128)


class ConfirmEmailRequest(BaseModel):
    token: str


class TwoFAInitResponse(BaseModel):
    secret: str
    otpauth_url: Optional[str] = None


class TwoFAVerifyRequest(BaseModel):
    code: str
    temp_token: Optional[str] = None

