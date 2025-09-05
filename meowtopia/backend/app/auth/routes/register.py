from fastapi import APIRouter, HTTPException
import secrets

from ..security import get_password_hash
from ..store import USERS_BY_EMAIL
from ..schemas import RegisterRequest

router = APIRouter()


@router.post("/register")
def register(req: RegisterRequest):
    email_key = req.email.lower()
    if email_key in USERS_BY_EMAIL:
        raise HTTPException(status_code=400, detail="User already exists")

    user_id = secrets.token_hex(8)
    password_hash = get_password_hash(req.password)
    user = {
        "id": user_id,
        "email": email_key,
        "password_hash": password_hash,
        "role": "user",
        "is_email_confirmed": False,
        "twofa_enabled": False,
        "twofa_secret": None,
        "confirm_tokens": set(),
        "reset_tokens": set(),
    }

    confirm_token = secrets.token_urlsafe(32)
    user["confirm_tokens"].add(confirm_token)
    USERS_BY_EMAIL[email_key] = user

    return {
        "message": "User registered. Please confirm your email.",
        "confirm_token": confirm_token,
        "user_id": user_id,
    }


