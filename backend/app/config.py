from functools import lru_cache
from pathlib import Path
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    project_name: str = "MuseAI Backend"
    api_prefix: str = "/api/v1"
    app_base_url: str = "http://127.0.0.1:8000"

    firebase_project_id: str = ""
    firebase_storage_bucket: str = ""
    google_application_credentials: Optional[str] = None

    allow_insecure_dev_tokens: bool = True
    ai_provider_mode: str = "mock"
    ai_generation_delay_seconds: int = 3
    default_track_duration_seconds: int = 30
    local_storage_dir: str = "local_storage"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def backend_root(self) -> Path:
        return Path(__file__).resolve().parent.parent

    @property
    def local_storage_path(self) -> Path:
        return self.backend_root / self.local_storage_dir


@lru_cache
def get_settings() -> Settings:
    return Settings()
