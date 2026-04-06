from fastapi import HTTPException, status
from firebase_admin import firestore

from app.firebase import get_firestore_client
from app.schemas import (
    PlaylistCreateRequest,
    PlaylistReorderRequest,
    PlaylistResponse,
    PlaylistTrackMutationRequest,
    PlaylistUpdateRequest,
)
from app.security import CurrentUser
from app.services.firestore_utils import clean_none, snapshot_to_dict, utcnow


class PlaylistService:
    def __init__(self) -> None:
        self.db = get_firestore_client()

    def _lists(self, uid: str):
        return self.db.collection("playlists").document(uid).collection("lists")

    def _tracks(self, uid: str):
        return self.db.collection("generations").document(uid).collection("tracks")

    def _doc(self, uid: str, playlist_id: str):
        return self._lists(uid).document(playlist_id)

    def list_playlists(self, user: CurrentUser) -> list[PlaylistResponse]:
        docs = (
            self._lists(user.uid)
            .order_by("createdAt", direction=firestore.Query.DESCENDING)
            .stream()
        )
        return [self._to_playlist(snapshot_to_dict(doc)) for doc in docs]

    def create_playlist(
        self,
        user: CurrentUser,
        payload: PlaylistCreateRequest,
    ) -> PlaylistResponse:
        now = utcnow()
        doc_ref = self._lists(user.uid).document()
        doc_ref.set(
            {
                "uid": user.uid,
                "name": payload.name,
                "description": payload.description,
                "visibility": payload.visibility.value,
                "trackIds": [],
                "createdAt": now,
                "updatedAt": now,
            }
        )
        return self.get_playlist(user, doc_ref.id)

    def get_playlist(self, user: CurrentUser, playlist_id: str) -> PlaylistResponse:
        snapshot = self._doc(user.uid, playlist_id).get()
        if not snapshot.exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Playlist not found")
        return self._to_playlist(snapshot_to_dict(snapshot))

    def update_playlist(
        self,
        user: CurrentUser,
        playlist_id: str,
        payload: PlaylistUpdateRequest,
    ) -> PlaylistResponse:
        doc_ref = self._doc(user.uid, playlist_id)
        if not doc_ref.get().exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Playlist not found")

        doc_ref.update(
            clean_none(
                {
                    "name": payload.name,
                    "description": payload.description,
                    "visibility": payload.visibility.value if payload.visibility else None,
                    "updatedAt": utcnow(),
                }
            )
        )
        return self.get_playlist(user, playlist_id)

    def delete_playlist(self, user: CurrentUser, playlist_id: str) -> None:
        doc_ref = self._doc(user.uid, playlist_id)
        if not doc_ref.get().exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Playlist not found")
        doc_ref.delete()

    def add_track(
        self,
        user: CurrentUser,
        playlist_id: str,
        payload: PlaylistTrackMutationRequest,
    ) -> PlaylistResponse:
        if not self._tracks(user.uid).document(payload.track_id).get().exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Track not found")

        playlist = self.get_playlist(user, playlist_id)
        track_ids = list(playlist.track_ids)
        if payload.track_id not in track_ids:
            track_ids.append(payload.track_id)

        self._doc(user.uid, playlist_id).update({"trackIds": track_ids, "updatedAt": utcnow()})
        return self.get_playlist(user, playlist_id)

    def remove_track(
        self,
        user: CurrentUser,
        playlist_id: str,
        track_id: str,
    ) -> PlaylistResponse:
        playlist = self.get_playlist(user, playlist_id)
        track_ids = [item for item in playlist.track_ids if item != track_id]
        self._doc(user.uid, playlist_id).update({"trackIds": track_ids, "updatedAt": utcnow()})
        return self.get_playlist(user, playlist_id)

    def reorder_tracks(
        self,
        user: CurrentUser,
        playlist_id: str,
        payload: PlaylistReorderRequest,
    ) -> PlaylistResponse:
        playlist = self.get_playlist(user, playlist_id)
        if sorted(payload.track_ids) != sorted(playlist.track_ids):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reorder payload must contain the same track ids",
            )
        self._doc(user.uid, playlist_id).update(
            {"trackIds": payload.track_ids, "updatedAt": utcnow()}
        )
        return self.get_playlist(user, playlist_id)

    @staticmethod
    def _to_playlist(data: dict) -> PlaylistResponse:
        return PlaylistResponse(
            id=data["id"],
            uid=data["uid"],
            name=data["name"],
            description=data.get("description"),
            visibility=data.get("visibility", "private"),
            track_ids=list(data.get("trackIds", [])),
            created_at=data["createdAt"],
            updated_at=data.get("updatedAt"),
        )
