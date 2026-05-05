from functools import lru_cache
from pathlib import Path
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    project_name: str = "MuseAI Backend"
    api_prefix: str = "/api/v1"
    app_base_url: str = "http://127.0.0.1:8000"
    cors_allowed_origins: str = "http://localhost:3000,http://127.0.0.1:3000"

    supabase_url: str = ""
    supabase_service_role_key: str = ""
    supabase_anon_key: str = ""
    supabase_storage_bucket: str = "museai-assets"
    supabase_password_reset_redirect_to: Optional[str] = None
    signed_asset_url_ttl_seconds: int = 3600
    brevo_api_key: str = ""
    brevo_sender_email: str = ""
    brevo_sender_name: str = "MuseAI"
    email_verification_redirect_to: Optional[str] = None
    signup_verification_code_ttl_minutes: int = 15
    signup_verification_resend_cooldown_seconds: int = 60

    allow_insecure_dev_tokens: bool = False
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

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
