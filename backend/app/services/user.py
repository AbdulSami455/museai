from fastapi import HTTPException, status

from app.firebase import get_auth_module, get_firestore_client
from app.schemas import (
    PasswordResetLinkRequest,
    PasswordResetLinkResponse,
    ProfileBootstrapRequest,
    UserProfileResponse,
)
from app.security import CurrentUser
from app.services.firestore_utils import clean_none, utcnow


class UserService:
    def __init__(self) -> None:
        self.db = get_firestore_client()
        self.auth = get_auth_module()

    def _user_doc(self, uid: str):
        return self.db.collection("users").document(uid)

    def get_me(self, user: CurrentUser) -> UserProfileResponse:
        snapshot = self._user_doc(user.uid).get()
        data = snapshot.to_dict() or {}
        return UserProfileResponse(
            uid=user.uid,
            email=data.get("email") or user.email,
            full_name=data.get("fullName"),
            photo_url=data.get("photoUrl"),
            created_at=data.get("createdAt"),
        )

    def bootstrap_profile(
        self,
        user: CurrentUser,
        payload: ProfileBootstrapRequest,
    ) -> UserProfileResponse:
        snapshot = self._user_doc(user.uid).get()
        now = utcnow()
        existing = snapshot.to_dict() or {}
        self._user_doc(user.uid).set(
            clean_none(
                {
                    "uid": user.uid,
                    "email": user.email or existing.get("email"),
                    "fullName": payload.full_name or existing.get("fullName") or user.name,
                    "photoUrl": existing.get("photoUrl"),
                    "createdAt": existing.get("createdAt") or now,
                    "updatedAt": now,
                }
            ),
            merge=True,
        )
        return self.get_me(user)

    def generate_password_reset_link(
        self,
        payload: PasswordResetLinkRequest,
    ) -> PasswordResetLinkResponse:
        try:
            link = self.auth.generate_password_reset_link(payload.email)
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unable to create password reset link",
            ) from exc
        return PasswordResetLinkResponse(reset_link=link)

    def delete_account(self, user: CurrentUser) -> None:
        generations_ref = (
            self.db.collection("generations").document(user.uid).collection("tracks")
        )
        playlists_ref = self.db.collection("playlists").document(user.uid).collection("lists")

        for doc in generations_ref.stream():
            data = doc.to_dict() or {}
            from app.services.storage import delete_file

            delete_file(data.get("audioStoragePath"))
            delete_file(data.get("coverStoragePath"))
            doc.reference.delete()

        for doc in playlists_ref.stream():
            doc.reference.delete()

        self.db.collection("generations").document(user.uid).delete()
        self.db.collection("playlists").document(user.uid).delete()
        self._user_doc(user.uid).delete()

        try:
            self.auth.delete_user(user.uid)
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="User data deleted, but auth user deletion failed",
            ) from exc
