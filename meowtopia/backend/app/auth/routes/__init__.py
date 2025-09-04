from fastapi import APIRouter
from .register import router as register_router
from .login import router as login_router
from .password import router as password_router
from .email import router as email_router
from .twofa import router as twofa_router
from .me import router as me_router

router = APIRouter()
router.include_router(register_router)
router.include_router(login_router)
router.include_router(password_router)
router.include_router(email_router)
router.include_router(twofa_router)
router.include_router(me_router)

