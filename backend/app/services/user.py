import httpx
from fastapi import HTTPException, status

from app.config import get_settings
from app.schemas import (
    AuthLoginRequest,
    AuthSignupRequest,
    AuthTokenResponse,
    PasswordResetLinkRequest,
    PasswordResetLinkResponse,
    ProfileBootstrapRequest,
    UserProfileResponse,
)
from app.security import CurrentUser
from app.services.firestore_utils import clean_none, utcnow
from app.services.storage import delete_file
from app.supabase import public_headers, require_supabase_client, service_headers


class UserService:
    def __init__(self) -> None:
        self.db = require_supabase_client()
        self.settings = get_settings()

    def _user_row(self, uid: str) -> dict:
        response = self.db.table("users").select("*").eq("id", uid).limit(1).execute()
        rows = response.data or []
        return rows[0] if rows else {}

    def get_me(self, user: CurrentUser) -> UserProfileResponse:
        data = self._user_row(user.uid)
        return UserProfileResponse(
            uid=user.uid,
            email=data.get("email") or user.email,
            full_name=data.get("full_name"),
            photo_url=data.get("photo_url"),
            created_at=data.get("created_at"),
        )

    def sign_up(self, payload: AuthSignupRequest) -> AuthTokenResponse:
        try:
            response = httpx.post(
                f"{self.settings.supabase_url.rstrip('/')}/auth/v1/signup",
                headers=public_headers(),
                json=clean_none(
                    {
                        "email": payload.email,
                        "password": payload.password,
                        "data": {"full_name": payload.full_name} if payload.full_name else None,
                    }
                ),
                timeout=30.0,
            )
            response.raise_for_status()
        except HTTPException:
            raise
        except httpx.HTTPStatusError as exc:
            detail = exc.response.text or "Signup failed"
            raise HTTPException(status_code=exc.response.status_code, detail=detail) from exc
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to sign up user",
            ) from exc

        return self._token_response_from_auth_payload(response.json())

    def sign_in(self, payload: AuthLoginRequest) -> AuthTokenResponse:
        try:
            response = httpx.post(
                f"{self.settings.supabase_url.rstrip('/')}/auth/v1/token?grant_type=password",
                headers=public_headers(),
                json={"email": payload.email, "password": payload.password},
                timeout=30.0,
            )
            response.raise_for_status()
        except HTTPException:
            raise
        except httpx.HTTPStatusError as exc:
            detail = exc.response.text or "Login failed"
            raise HTTPException(status_code=exc.response.status_code, detail=detail) from exc
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to sign in user",
            ) from exc

        return self._token_response_from_auth_payload(response.json())

    def bootstrap_profile(
        self,
        user: CurrentUser,
        payload: ProfileBootstrapRequest,
    ) -> UserProfileResponse:
        now = utcnow()
        existing = self._user_row(user.uid)
        self.db.table("users").upsert(
            clean_none(
                {
                    "id": user.uid,
                    "email": user.email or existing.get("email"),
                    "full_name": payload.full_name or existing.get("full_name") or user.name,
                    "photo_url": existing.get("photo_url"),
                    "created_at": existing.get("created_at") or now.isoformat(),
                    "updated_at": now.isoformat(),
                }
            )
        ).execute()
        return self.get_me(user)

    def generate_password_reset_link(
        self,
        payload: PasswordResetLinkRequest,
    ) -> PasswordResetLinkResponse:
        try:
            request_payload = {"type": "recovery", "email": payload.email}
            if self.settings.supabase_password_reset_redirect_to:
                request_payload["redirect_to"] = self.settings.supabase_password_reset_redirect_to
            response = httpx.post(
                f"{self.settings.supabase_url.rstrip('/')}/auth/v1/admin/generate_link",
                headers=service_headers(),
                json=request_payload,
                timeout=30.0,
            )
            response.raise_for_status()
            link = response.json().get("action_link")
            if not link:
                raise RuntimeError("Supabase did not return an action link")
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unable to create password reset link",
            ) from exc
        return PasswordResetLinkResponse(reset_link=link)

    def delete_account(self, user: CurrentUser) -> None:
        generation_rows = (
            self.db.table("generations").select("*").eq("uid", user.uid).execute().data or []
        )
        for row in generation_rows:
            delete_file(row.get("audio_storage_path"))
            delete_file(row.get("cover_storage_path"))

        self.db.table("generations").delete().eq("uid", user.uid).execute()
        self.db.table("playlists").delete().eq("uid", user.uid).execute()
        self.db.table("users").delete().eq("id", user.uid).execute()

        try:
            response = httpx.delete(
                f"{self.settings.supabase_url.rstrip('/')}/auth/v1/admin/users/{user.uid}",
                headers=service_headers(),
                timeout=30.0,
            )
            response.raise_for_status()
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="User data deleted, but auth user deletion failed",
            ) from exc

    def _token_response_from_auth_payload(self, payload: dict) -> AuthTokenResponse:
        user_payload = payload.get("user") or {}
        metadata = user_payload.get("user_metadata") or {}

        user = None
        if user_payload:
            user = UserProfileResponse(
                uid=user_payload.get("id", ""),
                email=user_payload.get("email"),
                full_name=metadata.get("full_name") or metadata.get("name"),
                photo_url=metadata.get("avatar_url"),
                created_at=user_payload.get("created_at"),
            )

        return AuthTokenResponse(
            access_token=payload.get("access_token"),
            refresh_token=payload.get("refresh_token"),
            expires_in=payload.get("expires_in"),
            token_type=payload.get("token_type"),
            user=user,
        )
