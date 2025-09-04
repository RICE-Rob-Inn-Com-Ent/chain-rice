from fastapi import APIRouter, HTTPException, Depends
import secrets

from ..security import get_password_hash, verify_password
from ..store import USERS_BY_EMAIL
from ..deps import get_current_user_payload, get_user_or_404
from ..schemas import ForgotPasswordRequest, ResetPasswordRequest, ChangePasswordRequest

router = APIRouter()


@router.post("/forgot-password")
def forgot_password(req: ForgotPasswordRequest):
    user = USERS_BY_EMAIL.get(req.email.lower())
    reset_token = None
    if user:
        reset_token = secrets.token_urlsafe(32)
        user["reset_tokens"].add(reset_token)
    return {
        "message": "If the email exists, a reset link has been sent.",
        "reset_token": reset_token,
    }


@router.post("/reset-password")
def reset_password(req: ResetPasswordRequest):
    for user in USERS_BY_EMAIL.values():
        if req.token in user["reset_tokens"]:
            user["password_hash"] = get_password_hash(req.new_password)
            user["reset_tokens"].discard(req.token)
            return {"message": "Password updated"}
    raise HTTPException(status_code=400, detail="Invalid or expired reset token")


@router.post("/change-password")
def change_password(req: ChangePasswordRequest, payload = Depends(get_current_user_payload)):
    email = payload.get("sub")
    user = get_user_or_404(email)
    if not verify_password(req.old_password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Incorrect current password")
    user["password_hash"] = get_password_hash(req.new_password)
    return {"message": "Password changed"}

