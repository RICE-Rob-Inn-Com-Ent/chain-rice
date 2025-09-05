from fastapi import APIRouter
from .routes import router as _routes

router = APIRouter(prefix="/auth", tags=["auth"])
router.include_router(_routes)


