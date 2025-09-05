from fastapi import APIRouter
from .routes import router as _routes

# Backward-compatible router export under the same filename
router = APIRouter(prefix="/auth", tags=["auth"])
router.include_router(_routes)

