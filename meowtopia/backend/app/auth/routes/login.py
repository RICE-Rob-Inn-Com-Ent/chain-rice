from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException
from jose import jwt
import secrets

try:
    import pyotp
except Exception:
    pyotp = None

from ..config import SECRET_KEY, ALGORITHM, get_access_token_expiry_delta
from ..security import verify_password
from ..store import USERS_BY_EMAIL, TWOFA_TEMP_TOKENS
from ..schemas import LoginRequest, TokenResponse

router = APIRouter()


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode.update({"exp": datetime.utcnow() + get_access_token_expiry_delta()})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest):
    user = USERS_BY_EMAIL.get(req.email.lower())
    if not user or not verify_password(req.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not user["is_email_confirmed"]:
        raise HTTPException(status_code=403, detail="Email not confirmed")

    if user["twofa_enabled"]:
        if not req.twofa_code:
            temp_token = secrets.token_urlsafe(32)
            TWOFA_TEMP_TOKENS[temp_token] = {"email": user["email"], "exp": datetime.utcnow() + timedelta(minutes=5)}
            return TokenResponse(requires_2fa=True, temp_token=temp_token)

        if not pyotp or not user["twofa_secret"]:
            raise HTTPException(status_code=500, detail="2FA not available")

        totp = pyotp.TOTP(user["twofa_secret"])
        if not totp.verify(req.twofa_code, valid_window=1):
            raise HTTPException(status_code=401, detail="Invalid 2FA code")

    token = create_access_token(
        {"sub": user["email"], "role": user["role"], "user_id": user["id"], "twofa_enabled": user["twofa_enabled"]}
    )
    return TokenResponse(access_token=token)


