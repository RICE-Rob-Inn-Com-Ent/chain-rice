"""
Meowtopia Backend API

Main FastAPI application for the Meowtopia virtual cat universe.
Provides authentication, game data management, and blockchain integration.
"""

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from contextlib import asynccontextmanager
import uvicorn

from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1.router import api_router
from app.core.auth import get_current_user
from app.models.user import User


# Create database tables
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown
    await engine.dispose()


# Create FastAPI app
app = FastAPI(
    title="Meowtopia API",
    description="Backend API for Meowtopia virtual cat universe",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_HOSTS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security scheme
security = HTTPBearer()

# Include API routes
app.include_router(api_router, prefix="/api/v1")


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Welcome to Meowtopia API",
        "version": "1.0.0",
        "docs": "/docs",
        "blockchain": "Chain-Rice",
        "features": [
            "User Authentication",
            "Cat NFT Management", 
            "Token Wallet Integration",
            "Game Progress Tracking",
            "Tournament System",
            "Breeding Mechanics",
            "Real-time Updates"
        ]
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.get("/protected")
async def protected_route(current_user: User = Depends(get_current_user)):
    """Example protected route requiring authentication."""
    return {
        "message": f"Hello {current_user.username}!",
        "user_id": current_user.id,
        "wallet_address": current_user.wallet_address
    }


# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return {"error": exc.detail, "status_code": exc.status_code}


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    return {
        "error": "Internal server error",
        "status_code": 500,
        "detail": str(exc) if settings.DEBUG else "An unexpected error occurred"
    }


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )