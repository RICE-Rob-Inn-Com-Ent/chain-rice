from fastapi import APIRouter, Depends
from ..deps import get_current_user_payload, get_user_or_404

router = APIRouter()


@router.get("/me")
def me(payload = Depends(get_current_user_payload)):
    email = payload.get("sub")
    user = get_user_or_404(email)
    return {
        "id": user["id"],
        "email": user["email"],
        "role": user["role"],
        "is_email_confirmed": user["is_email_confirmed"],
        "twofa_enabled": user["twofa_enabled"],
    }

