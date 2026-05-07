# This backend file contains supporting server logic.

import json
import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx
from fastapi import HTTPException, status
from postgrest.exceptions import APIError

from app.config import get_settings
from app.schemas import (
    AuthLoginRequest,
    AuthSignupRequest,
    AuthTokenResponse,
    EmailVerificationRequest,
    EmailVerificationResponse,
    PasswordResetLinkRequest,
    PasswordResetLinkResponse,
    ProfileBootstrapRequest,
    SignupStartRequest,
    SignupStartResponse,
    SignupVerifyRequest,
    SignupVerifyResponse,
    UserProfileResponse,
)
from app.security import CurrentUser
from app.services.utils import clean_none, utcnow
from app.services.storage import delete_file, ensure_local_storage_dir
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

        auth_payload = response.json()
        self._sync_profile_from_auth_payload(auth_payload)
        return self._token_response_from_auth_payload(auth_payload)

    def start_signup_verification(
        self,
        payload: SignupStartRequest,
    ) -> SignupStartResponse:
        pending = self._pending_signup_row(payload.email)
        self._ensure_resend_allowed(pending)
        self._ensure_brevo_configured()

        now = utcnow()
        code = self._generate_signup_code()
        expires_at = now + timedelta(minutes=self.settings.signup_verification_code_ttl_minutes)
        resend_count = int((pending or {}).get("resend_count", 0)) + 1

        self._upsert_pending_signup(
            payload.email,
            {
                "email": payload.email,
                "full_name": payload.full_name,
                "password": payload.password,
                "code_hash": self._hash_signup_code(payload.email, code),
                "expires_at": expires_at.isoformat(),
                "attempt_count": 0,
                "resend_count": resend_count,
                "last_sent_at": now.isoformat(),
                "created_at": (pending or {}).get("created_at") or now.isoformat(),
                "updated_at": now.isoformat(),
            },
            debug_code=code,
        )

        self._send_signup_code_email(
            to_email=payload.email,
            full_name=payload.full_name,
            code=code,
            expires_in_minutes=self.settings.signup_verification_code_ttl_minutes,
        )
        return SignupStartResponse(
            message="Verification code sent",
            expires_in_seconds=self.settings.signup_verification_code_ttl_minutes * 60,
        )

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

        auth_payload = response.json()
        self._sync_profile_from_auth_payload(auth_payload)
        return self._token_response_from_auth_payload(auth_payload)

    def verify_signup_code(
        self,
        payload: SignupVerifyRequest,
    ) -> SignupVerifyResponse:
        pending = self._pending_signup_row(payload.email)
        if not pending:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No pending signup found for this email.",
            )

        if self._is_pending_signup_expired(pending):
            self._delete_pending_signup(payload.email)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification code expired. Request a new code.",
            )

        expected_hash = self._hash_signup_code(payload.email, payload.code.strip())
        if pending.get("code_hash") != expected_hash:
            attempts = int(pending.get("attempt_count", 0)) + 1
            self._update_pending_signup(
                payload.email,
                {"attempt_count": attempts, "updated_at": utcnow().isoformat()},
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification code.",
            )

        self._create_or_confirm_auth_user(
            email=payload.email,
            password=str(pending.get("password", "")),
            full_name=pending.get("full_name"),
        )
        self._delete_pending_signup(payload.email)
        return SignupVerifyResponse(message="Email verified. You can sign in now.")

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

    def resend_verification_email(
        self,
        payload: EmailVerificationRequest,
    ) -> EmailVerificationResponse:
        pending = self._pending_signup_row(payload.email)
        if not pending:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No pending signup found for this email.",
            )
        self._ensure_resend_allowed(pending)
        self._ensure_brevo_configured()

        now = utcnow()
        code = self._generate_signup_code()
        expires_at = now + timedelta(minutes=self.settings.signup_verification_code_ttl_minutes)
        resend_count = int(pending.get("resend_count", 0)) + 1
        self._update_pending_signup(
            payload.email,
            {
                "code_hash": self._hash_signup_code(payload.email, code),
                "expires_at": expires_at.isoformat(),
                "last_sent_at": now.isoformat(),
                "updated_at": now.isoformat(),
                "resend_count": resend_count,
            },
            debug_code=code,
        )
        self._send_signup_code_email(
            to_email=payload.email,
            full_name=pending.get("full_name"),
            code=code,
            expires_in_minutes=self.settings.signup_verification_code_ttl_minutes,
        )
        return EmailVerificationResponse(
            message="Verification code resent",
            verification_link=None,
        )

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

    def _sync_profile_from_auth_payload(self, payload: dict) -> None:
        user_payload = payload.get("user") or {}
        if not user_payload:
            return
        metadata = user_payload.get("user_metadata") or {}
        try:
            self.db.table("users").upsert(
                clean_none(
                    {
                        "id": user_payload.get("id"),
                        "email": user_payload.get("email"),
                        "full_name": metadata.get("full_name") or metadata.get("name"),
                        "photo_url": metadata.get("avatar_url"),
                        "created_at": user_payload.get("created_at"),
                        "updated_at": utcnow().isoformat(),
                    }
                )
            ).execute()
        except Exception:
            # Auth should still succeed even if the app schema is not yet applied.
            pass

    def _send_brevo_transactional_email(
        self,
        *,
        to_email: str,
        subject: str,
        html_content: str,
    ) -> bool:
        if not self.settings.brevo_api_key or not self.settings.brevo_sender_email:
            return False

        response = httpx.post(
            "https://api.brevo.com/v3/smtp/email",
            headers={
                "api-key": self.settings.brevo_api_key,
                "Content-Type": "application/json",
            },
            json={
                "sender": {
                    "email": self.settings.brevo_sender_email,
                    "name": self.settings.brevo_sender_name,
                },
                "to": [{"email": to_email}],
                "subject": subject,
                "htmlContent": html_content,
            },
            timeout=30.0,
        )
        response.raise_for_status()
        return True

    def _pending_signup_row(self, email: str) -> dict:
        try:
            response = (
                self.db.table("pending_signups")
                .select("*")
                .eq("email", email)
                .limit(1)
                .execute()
            )
            rows = response.data or []
            return rows[0] if rows else {}
        except APIError as exc:
            if self._is_missing_pending_signups_table(exc):
                return self._local_pending_signup_row(email)
            raise

    def _upsert_pending_signup(self, email: str, payload: dict, debug_code: Optional[str] = None) -> None:
        try:
            self.db.table("pending_signups").upsert(payload).execute()
        except APIError as exc:
            if self._is_missing_pending_signups_table(exc):
                self._local_upsert_pending_signup(email, payload, debug_code=debug_code)
                return
            raise

    def _update_pending_signup(
        self,
        email: str,
        updates: dict,
        debug_code: Optional[str] = None,
    ) -> None:
        try:
            self.db.table("pending_signups").update(updates).eq("email", email).execute()
        except APIError as exc:
            if self._is_missing_pending_signups_table(exc):
                current = self._local_pending_signup_row(email)
                if not current:
                    return
                current.update(updates)
                self._local_upsert_pending_signup(email, current, debug_code=debug_code)
                return
            raise

    def _delete_pending_signup(self, email: str) -> None:
        try:
            self.db.table("pending_signups").delete().eq("email", email).execute()
        except APIError as exc:
            if self._is_missing_pending_signups_table(exc):
                self._local_delete_pending_signup(email)
                return
            raise

    def _is_missing_pending_signups_table(self, exc: APIError) -> bool:
        message = str(exc)
        return "pending_signups" in message and "schema cache" in message

    def _local_pending_signup_row(self, email: str) -> dict:
        store = self._read_pending_signup_store()
        return store.get(email.lower(), {})

    def _local_upsert_pending_signup(
        self,
        email: str,
        payload: dict,
        debug_code: Optional[str] = None,
    ) -> None:
        store = self._read_pending_signup_store()
        row = dict(payload)
        if debug_code:
            row["debug_code"] = debug_code
        store[email.lower()] = row
        self._write_pending_signup_store(store)

    def _local_delete_pending_signup(self, email: str) -> None:
        store = self._read_pending_signup_store()
        store.pop(email.lower(), None)
        self._write_pending_signup_store(store)

    def _pending_signup_store_path(self):
        storage_dir = ensure_local_storage_dir()
        return storage_dir / "pending_signups.json"

    def _read_pending_signup_store(self) -> dict:
        path = self._pending_signup_store_path()
        if not path.exists():
            return {}
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return {}

    def _write_pending_signup_store(self, payload: dict) -> None:
        path = self._pending_signup_store_path()
        path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def _ensure_brevo_configured(self) -> None:
        if self.settings.brevo_api_key and self.settings.brevo_sender_email:
            return
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Brevo email delivery is not configured.",
        )

    def _ensure_resend_allowed(self, pending: dict) -> None:
        if not pending:
            return
        last_sent_at = pending.get("last_sent_at")
        if not last_sent_at:
            return
        last_sent = self._as_datetime(last_sent_at)
        elapsed = (utcnow() - last_sent).total_seconds()
        cooldown = self.settings.signup_verification_resend_cooldown_seconds
        if elapsed < cooldown:
            wait_seconds = max(1, int(cooldown - elapsed))
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Please wait {wait_seconds} seconds before requesting another verification code.",
            )

    def _is_pending_signup_expired(self, pending: dict) -> bool:
        expires_at = pending.get("expires_at")
        if not expires_at:
            return True
        return self._as_datetime(expires_at) < utcnow()

    def _as_datetime(self, value: str) -> datetime:
        normalized = value.strip()
        if normalized.endswith("Z"):
            normalized = normalized[:-1] + "+00:00"
        parsed = datetime.fromisoformat(normalized)
        if parsed.tzinfo is None:
            return parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)

    def _generate_signup_code(self) -> str:
        return f"{secrets.randbelow(1000000):06d}"

    def _hash_signup_code(self, email: str, code: str) -> str:
        return hashlib.sha256(f"{email.lower()}:{code}".encode("utf-8")).hexdigest()

    def _send_signup_code_email(
        self,
        *,
        to_email: str,
        full_name: Optional[str],
        code: str,
        expires_in_minutes: int,
    ) -> None:
        name = full_name or "there"
        self._send_brevo_transactional_email(
            to_email=to_email,
            subject="Your MuseAI verification code",
            html_content=(
                f"<p>Hi {name},</p>"
                "<p>Use this verification code to finish creating your MuseAI account:</p>"
                f"<h2 style=\"letter-spacing:4px;\">{code}</h2>"
                f"<p>This code expires in {expires_in_minutes} minutes.</p>"
            ),
        )

    def _create_or_confirm_auth_user(
        self,
        *,
        email: str,
        password: str,
        full_name: Optional[str],
    ) -> None:
        try:
            response = httpx.post(
                f"{self.settings.supabase_url.rstrip('/')}/auth/v1/admin/users",
                headers=service_headers(),
                json=clean_none(
                    {
                        "email": email,
                        "password": password,
                        "email_confirm": True,
                        "user_metadata": {"full_name": full_name} if full_name else None,
                    }
                ),
                timeout=30.0,
            )
            if response.status_code not in (200, 201):
                body = response.text or ""
                if "already" not in body.lower() and "exists" not in body.lower():
                    response.raise_for_status()
                self._confirm_existing_auth_user(
                    email=email,
                    password=password,
                    full_name=full_name,
                )
        except HTTPException:
            raise
        except httpx.HTTPStatusError as exc:
            detail = exc.response.text or "Unable to create verified user"
            raise HTTPException(status_code=exc.response.status_code, detail=detail) from exc
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to create verified user",
            ) from exc

    def _confirm_existing_auth_user(
        self,
        *,
        email: str,
        password: str,
        full_name: Optional[str],
    ) -> None:
        response = httpx.get(
            f"{self.settings.supabase_url.rstrip('/')}/auth/v1/admin/users",
            headers=service_headers(),
            timeout=30.0,
        )
        response.raise_for_status()
        users = (response.json() or {}).get("users") or []
        existing = next((user for user in users if (user.get("email") or "").lower() == email.lower()), None)
        if not existing or not existing.get("id"):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Existing auth user could not be located for verification.",
            )

        update_response = httpx.put(
            f"{self.settings.supabase_url.rstrip('/')}/auth/v1/admin/users/{existing['id']}",
            headers=service_headers(),
            json=clean_none(
                {
                    "email": email,
                    "password": password,
                    "email_confirm": True,
                    "user_metadata": {"full_name": full_name} if full_name else None,
                }
            ),
            timeout=30.0,
        )
        update_response.raise_for_status()
