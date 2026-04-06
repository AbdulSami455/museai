from datetime import timedelta
from pathlib import Path
from typing import Optional

from app.config import get_settings
from app.firebase import get_storage_bucket


def _local_file_url(relative_path: str) -> str:
    settings = get_settings()
    return f"{settings.app_base_url.rstrip('/')}/assets/{relative_path}"


def upload_bytes(relative_path: str, data: bytes, content_type: str) -> str:
    settings = get_settings()
    if not settings.firebase_storage_bucket:
        target = settings.local_storage_path / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        return _local_file_url(relative_path)

    bucket = get_storage_bucket()
    blob = bucket.blob(relative_path)
    blob.upload_from_string(data, content_type=content_type)
    return blob.generate_signed_url(
        expiration=timedelta(days=3650),
        method="GET",
        version="v4",
    )


def delete_file(relative_path: Optional[str]) -> None:
    if not relative_path:
        return

    settings = get_settings()
    if not settings.firebase_storage_bucket:
        target = settings.local_storage_path / relative_path
        if target.exists():
            target.unlink()
        return

    bucket = get_storage_bucket()
    blob = bucket.blob(relative_path)
    if blob.exists():
        blob.delete()


def ensure_local_storage_dir() -> Path:
    settings = get_settings()
    settings.local_storage_path.mkdir(parents=True, exist_ok=True)
    return settings.local_storage_path
