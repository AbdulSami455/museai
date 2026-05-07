# This backend file contains supporting server logic.

from dataclasses import dataclass
from typing import Optional

import httpx
from fastapi import HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import get_settings
from app.supabase import auth_headers

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
        response = httpx.get(
            f"{settings.supabase_url.rstrip('/')}/auth/v1/user",
            headers=auth_headers(token),
            timeout=10.0,
        )
        if response.status_code != status.HTTP_200_OK:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
            )
        decoded = response.json()
        metadata = decoded.get("user_metadata") or {}
        return CurrentUser(
            uid=decoded["id"],
            email=decoded.get("email"),
            name=metadata.get("full_name") or metadata.get("name"),
        )
    except HTTPException:
        raise
    except Exception as exc:  # pragma: no cover - depends on Supabase runtime
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from exc
