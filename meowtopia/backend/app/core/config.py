"""Configuration settings for Meowtopia backend."""

from pydantic_settings import BaseSettings
from typing import List, Optional
import os


class Settings(BaseSettings):
    """Application settings."""
    
    # App settings
    DEBUG: bool = False
    PROJECT_NAME: str = "Meowtopia API"
    VERSION: str = "1.0.0"
    DESCRIPTION: str = "Backend API for Meowtopia virtual cat universe"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Database
    DATABASE_URL: str = "postgresql://meowtopia:password@localhost/meowtopia"
    TEST_DATABASE_URL: str = "postgresql://meowtopia:password@localhost/meowtopia_test"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    
    # CORS
    ALLOWED_HOSTS: List[str] = ["*"]
    
    # Blockchain settings
    CHAIN_RICE_RPC_URL: str = "http://localhost:26657"
    CHAIN_RICE_REST_URL: str = "http://localhost:1317"
    CHAIN_ID: str = "chainrice"
    
    # Smart contract addresses (set after deployment)
    MWT_TOKEN_CONTRACT: Optional[str] = None
    CAT_NFT_CONTRACT: Optional[str] = None
    DAO_CONTRACT: Optional[str] = None
    
    # Game settings
    MAX_CATS_PER_USER: int = 100
    BREEDING_COOLDOWN_HOURS: int = 24
    DAILY_REWARD_AMOUNT: int = 10
    TOURNAMENT_DURATION_HOURS: int = 168  # 7 days
    
    # File uploads
    MAX_FILE_SIZE: int = 5 * 1024 * 1024  # 5MB
    UPLOAD_DIR: str = "uploads"
    ALLOWED_FILE_TYPES: List[str] = ["image/jpeg", "image/png", "image/gif"]
    
    # Email settings (for notifications)
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    SMTP_TLS: bool = True
    
    # Celery settings
    CELERY_BROKER_URL: str = "redis://localhost:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/0"
    
    # Logging
    LOG_LEVEL: str = "INFO"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Create settings instance
settings = Settings()