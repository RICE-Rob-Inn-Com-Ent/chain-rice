"""Main API router for Meowtopia backend."""

from fastapi import APIRouter
from app.api.v1.endpoints import auth, users, cats, game, blockchain

api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(cats.router, prefix="/cats", tags=["cats"])
api_router.include_router(game.router, prefix="/game", tags=["game"])
api_router.include_router(blockchain.router, prefix="/blockchain", tags=["blockchain"])