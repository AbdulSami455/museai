from dataclasses import dataclass
from typing import Optional

from fastapi import HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import get_settings
from app.firebase import get_auth_module

bearer_scheme = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class CurrentUser:
    uid: str
    email: Optional[str] = None
    name: Optional[str] = None


def verify_bearer_token(
    credentials: Optional[HTTPAuthorizationCredentials],
) -> CurrentUser:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
        )

    token = credentials.credentials
    settings = get_settings()

    if settings.allow_insecure_dev_tokens and token.startswith("dev:"):
        _, uid, *rest = token.split(":")
        email = rest[0] if rest else None
        return CurrentUser(uid=uid, email=email)

    try:
        auth_module = get_auth_module()
        decoded = auth_module.verify_id_token(token)
        return CurrentUser(
            uid=decoded["uid"],
            email=decoded.get("email"),
            name=decoded.get("name"),
        )
    except Exception as exc:  # pragma: no cover - depends on Firebase runtime
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from exc
