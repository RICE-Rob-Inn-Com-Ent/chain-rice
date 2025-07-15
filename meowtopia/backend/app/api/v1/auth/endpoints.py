from fastapi import APIRouter, UploadFile, File, status
from .models import (
    LoginRequest, LoginResponse, RegisterRequest, RegisterResponse,
    ForgotPasswordRequest, ResetPasswordRequest, VerifyEmailRequest,
    ResendVerificationRequest, ProfileResponse, UpdateProfileRequest,
    ChangePasswordRequest, ChangePasswordResponse, UploadAvatarResponse
)
from datetime import datetime

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=LoginResponse)
async def login_user(data: LoginRequest):
    """Login User"""
    return LoginResponse(
        access_token="token", token_type="bearer", expires_in=3600, user_id="user1", fullName="John Doe"
    )

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register_user(data: RegisterRequest):
    """Register User"""
    return RegisterResponse(
        access_token="token", token_type="bearer", expires_in=3600, user_id="user1", fullName=data.fullName
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

@router.post("/resend-verification")
async def resend_verification(data: ResendVerificationRequest):
    """Resend email verification link"""
    return {"message": "Verification email sent."}

@router.get("/profile", response_model=ProfileResponse)
async def get_profile():
    """Get current user profile"""
    return ProfileResponse(
        id="user1",
        email="user@example.com",
        fullName="John Doe",
        role="USER",
        avatar=None,
        emailVerified=True,
        createdAt=datetime.utcnow(),
        lastLogin=datetime.utcnow()
    )

@router.put("/profile", response_model=ProfileResponse)
async def update_profile(data: UpdateProfileRequest):
    """Update user profile"""
    return ProfileResponse(
        id="user1",
        email="user@example.com",
        fullName=data.fullName or "John Doe",
        role="USER",
        avatar=data.avatar,
        emailVerified=True,
        createdAt=datetime.utcnow(),
        lastLogin=datetime.utcnow()
    )

@router.post("/change-password", response_model=ChangePasswordResponse)
async def change_password(data: ChangePasswordRequest):
    """Change user password"""
    return ChangePasswordResponse(message="Password changed successfully.")

@router.post("/avatar", response_model=UploadAvatarResponse)
async def upload_avatar(file: UploadFile = File(...)):
    """Upload user avatar"""
    return UploadAvatarResponse(avatarUrl="https://example.com/avatar.png")
