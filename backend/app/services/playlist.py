import uuid

from fastapi import HTTPException, status

from app.schemas import (
    PlaylistCreateRequest,
    PlaylistReorderRequest,
    PlaylistResponse,
    PlaylistTrackMutationRequest,
    PlaylistUpdateRequest,
)
from app.security import CurrentUser
from app.services.utils import clean_none, utcnow
from app.supabase import require_supabase_client


class PlaylistService:
    def __init__(self) -> None:
        self.db = require_supabase_client()

    def list_playlists(self, user: CurrentUser) -> list[PlaylistResponse]:
        response = (
            self.db.table("playlists")
            .select("*")
            .eq("uid", user.uid)
            .order("created_at", desc=True)
            .execute()
        )
        return [self._to_playlist(row) for row in (response.data or [])]

    def create_playlist(
        self,
        user: CurrentUser,
        payload: PlaylistCreateRequest,
    ) -> PlaylistResponse:
        now = utcnow().isoformat()
        playlist_id = str(uuid.uuid4())
        self.db.table("playlists").insert(
            {
                "id": playlist_id,
                "uid": user.uid,
                "name": payload.name,
                "description": payload.description,
                "visibility": payload.visibility.value,
                "track_ids": [],
                "created_at": now,
                "updated_at": now,
            }
        ).execute()
        return self.get_playlist(user, playlist_id)

    def get_playlist(self, user: CurrentUser, playlist_id: str) -> PlaylistResponse:
        response = (
            self.db.table("playlists")
            .select("*")
            .eq("id", playlist_id)
            .eq("uid", user.uid)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        if not rows:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Playlist not found")
        return self._to_playlist(rows[0])

    def update_playlist(
        self,
        user: CurrentUser,
        playlist_id: str,
        payload: PlaylistUpdateRequest,
    ) -> PlaylistResponse:
        self.get_playlist(user, playlist_id)
        self.db.table("playlists").update(
            clean_none(
                {
                    "name": payload.name,
                    "description": payload.description,
                    "visibility": payload.visibility.value if payload.visibility else None,
                    "updated_at": utcnow().isoformat(),
                }
            )
        ).eq("id", playlist_id).eq("uid", user.uid).execute()
        return self.get_playlist(user, playlist_id)

    def delete_playlist(self, user: CurrentUser, playlist_id: str) -> None:
        self.get_playlist(user, playlist_id)
        self.db.table("playlists").delete().eq("id", playlist_id).eq("uid", user.uid).execute()

    def add_track(
        self,
        user: CurrentUser,
        playlist_id: str,
        payload: PlaylistTrackMutationRequest,
    ) -> PlaylistResponse:
        track_rows = (
            self.db.table("generations")
            .select("id")
            .eq("id", payload.track_id)
            .eq("uid", user.uid)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not track_rows:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Track not found")

        playlist = self.get_playlist(user, playlist_id)
        track_ids = list(playlist.track_ids)
        if payload.track_id not in track_ids:
            track_ids.append(payload.track_id)

        self.db.table("playlists").update(
            {"track_ids": track_ids, "updated_at": utcnow().isoformat()}
        ).eq("id", playlist_id).eq("uid", user.uid).execute()
        return self.get_playlist(user, playlist_id)

    def remove_track(
        self,
        user: CurrentUser,
        playlist_id: str,
        track_id: str,
    ) -> PlaylistResponse:
        playlist = self.get_playlist(user, playlist_id)
        track_ids = [item for item in playlist.track_ids if item != track_id]
        self.db.table("playlists").update(
            {"track_ids": track_ids, "updated_at": utcnow().isoformat()}
        ).eq("id", playlist_id).eq("uid", user.uid).execute()
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
        self.db.table("playlists").update(
            {"track_ids": payload.track_ids, "updated_at": utcnow().isoformat()}
        ).eq("id", playlist_id).eq("uid", user.uid).execute()
        return self.get_playlist(user, playlist_id)

    @staticmethod
    def _to_playlist(data: dict) -> PlaylistResponse:
        return PlaylistResponse(
            id=data["id"],
            uid=data["uid"],
            name=data["name"],
            description=data.get("description"),
            visibility=data.get("visibility", "private"),
            track_ids=list(data.get("track_ids", [])),
            created_at=data["created_at"],
            updated_at=data.get("updated_at"),
        )
