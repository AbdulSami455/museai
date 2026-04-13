from functools import lru_cache

from fastapi import HTTPException, status
from supabase import Client, create_client

from app.config import get_settings


@lru_cache
def get_supabase_client() -> Client:
    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise RuntimeError("Supabase is not configured")
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def require_supabase_client() -> Client:
    try:
        return get_supabase_client()
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Supabase is not configured",
        ) from exc


def service_headers(content_type: str = "application/json") -> dict[str, str]:
    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Supabase is not configured",
        )
    return {
        "apikey": settings.supabase_service_role_key,
        "Authorization": f"Bearer {settings.supabase_service_role_key}",
        "Content-Type": content_type,
    }


def auth_headers(token: str) -> dict[str, str]:
    settings = get_settings()
    api_key = settings.supabase_anon_key or settings.supabase_service_role_key
    if not settings.supabase_url or not api_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Supabase auth is not configured",
        )
    return {
        "apikey": api_key,
        "Authorization": f"Bearer {token}",
    }


def public_headers(content_type: str = "application/json") -> dict[str, str]:
    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_anon_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Supabase public auth is not configured",
        )
    return {
        "apikey": settings.supabase_anon_key,
        "Content-Type": content_type,
    }
