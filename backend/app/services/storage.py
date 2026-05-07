# This file provides local storage helpers for generated assets.

from pathlib import Path
from typing import Optional

import httpx

from app.config import get_settings
from app.supabase import service_headers


def _local_file_url(relative_path: str) -> str:
    settings = get_settings()
    return f"{settings.app_base_url.rstrip('/')}/assets/{relative_path}"


def create_signed_url(relative_path: str) -> str:
    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_service_role_key:
        return _local_file_url(relative_path)

    bucket = settings.supabase_storage_bucket
    signed_url_response = httpx.post(
        f"{settings.supabase_url.rstrip('/')}/storage/v1/object/sign/{bucket}/{relative_path}",
        headers=service_headers(),
        json={"expiresIn": settings.signed_asset_url_ttl_seconds},
        timeout=30.0,
    )
    signed_url_response.raise_for_status()
    payload = signed_url_response.json()
    signed_url = payload.get("signedURL") or payload.get("signedUrl")
    if not signed_url:
        raise RuntimeError("Supabase did not return a signed URL")
    return f"{settings.supabase_url.rstrip('/')}/storage/v1{signed_url}"


def upload_bytes(relative_path: str, data: bytes, content_type: str) -> str:
    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_service_role_key:
        target = settings.local_storage_path / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        return _local_file_url(relative_path)

    bucket = settings.supabase_storage_bucket
    upload_response = httpx.post(
        f"{settings.supabase_url.rstrip('/')}/storage/v1/object/{bucket}/{relative_path}",
        headers={
            **service_headers(content_type=content_type),
            "x-upsert": "true",
        },
        content=data,
        timeout=30.0,
    )
    upload_response.raise_for_status()
    return create_signed_url(relative_path)


def delete_file(relative_path: Optional[str]) -> None:
    if not relative_path:
        return

    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_service_role_key:
        target = settings.local_storage_path / relative_path
        if target.exists():
            target.unlink()
        return

    bucket = settings.supabase_storage_bucket
    response = httpx.delete(
        f"{settings.supabase_url.rstrip('/')}/storage/v1/object/{bucket}/{relative_path}",
        headers=service_headers(),
        timeout=30.0,
    )
    if response.status_code not in (200, 204, 404):
        response.raise_for_status()


def ensure_local_storage_dir() -> Path:
    settings = get_settings()
    settings.local_storage_path.mkdir(parents=True, exist_ok=True)
    return settings.local_storage_path
