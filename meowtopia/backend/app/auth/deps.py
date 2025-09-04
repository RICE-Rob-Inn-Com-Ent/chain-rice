from typing import Dict, Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials
from jose import JWTError, jwt

from .config import SECRET_KEY, ALGORITHM
from .security import security
from .store import USERS_BY_EMAIL


def verify_token(token: str) -> Dict[str, Any]:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user_payload(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    return verify_token(credentials.credentials)


def get_user_or_404(email: str) -> Dict[str, Any]:
    user = USERS_BY_EMAIL.get(email.lower())
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def require_role(required_role: str):
    def role_checker(payload: Dict[str, Any] = Depends(get_current_user_payload)) -> Dict[str, Any]:
        role = payload.get("role", "user")
        if role != required_role and role != "admin":
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return payload
    return role_checker

