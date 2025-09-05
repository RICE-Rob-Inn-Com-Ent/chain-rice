from fastapi import APIRouter, HTTPException
from ..store import USERS_BY_EMAIL
from ..schemas import ConfirmEmailRequest

router = APIRouter()


@router.post("/confirm-email")
def confirm_email(req: ConfirmEmailRequest):
    for user in USERS_BY_EMAIL.values():
        if req.token in user["confirm_tokens"]:
            user["is_email_confirmed"] = True
            user["confirm_tokens"].discard(req.token)
            return {"message": "Email confirmed"}
    raise HTTPException(status_code=400, detail="Invalid or expired confirmation token")


