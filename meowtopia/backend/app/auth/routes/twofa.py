from fastapi import APIRouter, HTTPException, Depends
try:
    import pyotp
except Exception:
    pyotp = None

from ..deps import get_current_user_payload, get_user_or_404
from ..store import TWOFA_TEMP_TOKENS
from ..schemas import TwoFAInitResponse, TwoFAVerifyRequest
from ..config import SECRET_KEY, ALGORITHM, get_access_token_expiry_delta
from jose import jwt
from datetime import datetime

router = APIRouter()


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode.update({"exp": datetime.utcnow() + get_access_token_expiry_delta()})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


@router.post("/2fa/initiate", response_model=TwoFAInitResponse)
def twofa_initiate(payload = Depends(get_current_user_payload)):
    if not pyotp:
        raise HTTPException(status_code=500, detail="pyotp is required for 2FA; please install it")

    email = payload.get("sub")
    user = get_user_or_404(email)

    if user["twofa_enabled"] and user["twofa_secret"]:
        totp = pyotp.TOTP(user["twofa_secret"])
        return TwoFAInitResponse(secret=user["twofa_secret"], otpauth_url=totp.provisioning_uri(name=email, issuer_name="Meowtopia"))

    secret = pyotp.random_base32()
    user["twofa_secret"] = secret
    totp = pyotp.TOTP(secret)
    return TwoFAInitResponse(secret=secret, otpauth_url=totp.provisioning_uri(name=email, issuer_name="Meowtopia"))


@router.post("/2fa/verify")
def twofa_verify(req: TwoFAVerifyRequest, maybe_payload = Depends(lambda: None)):
    if req.temp_token:
        challenge = TWOFA_TEMP_TOKENS.get(req.temp_token)
        if not challenge or challenge["exp"] < datetime.utcnow():
            raise HTTPException(status_code=400, detail="Invalid or expired 2FA challenge")
        email = challenge["email"]
        user = get_user_or_404(email)
        if not pyotp or not user["twofa_secret"]:
            raise HTTPException(status_code=500, detail="2FA not available")
        totp = pyotp.TOTP(user["twofa_secret"])
        if not totp.verify(req.code, valid_window=1):
            raise HTTPException(status_code=401, detail="Invalid 2FA code")
        TWOFA_TEMP_TOKENS.pop(req.temp_token, None)
        token = create_access_token(
            {"sub": user["email"], "role": user["role"], "user_id": user["id"], "twofa_enabled": True}
        )
        return {"message": "2FA verification successful", "access_token": token, "token_type": "bearer"}

    if maybe_payload is None:
        raise HTTPException(status_code=401, detail="Authorization required")
    email = maybe_payload.get("sub")
    user = get_user_or_404(email)
    if not pyotp or not user["twofa_secret"]:
        raise HTTPException(status_code=500, detail="2FA not available")
    totp = pyotp.TOTP(user["twofa_secret"])
    if not totp.verify(req.code, valid_window=1):
        raise HTTPException(status_code=401, detail="Invalid 2FA code")
    user["twofa_enabled"] = True
    return {"message": "2FA enabled"}


