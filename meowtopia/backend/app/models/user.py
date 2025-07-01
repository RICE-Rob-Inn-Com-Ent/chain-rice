"""User model for authentication and game data."""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Float
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class User(Base):
    """User model for authentication and game data."""
    
    __tablename__ = "users"
    
    # Basic user info
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    
    # Blockchain info
    wallet_address = Column(String(255), unique=True, index=True)
    public_key = Column(Text)
    
    # Game data
    level = Column(Integer, default=1)
    experience = Column(Integer, default=0)
    mwt_balance = Column(Float, default=0.0)  # Cached balance from blockchain
    total_cats_owned = Column(Integer, default=0)
    total_cats_bred = Column(Integer, default=0)
    tournament_wins = Column(Integer, default=0)
    
    # Profile info
    display_name = Column(String(100))
    avatar_url = Column(String(255))
    bio = Column(Text)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True))
    
    # Settings
    email_notifications = Column(Boolean, default=True)
    push_notifications = Column(Boolean, default=True)
    privacy_mode = Column(Boolean, default=False)
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, username='{self.username}')>"