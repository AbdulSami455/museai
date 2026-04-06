from firebase_admin import firestore

from app.firebase import get_firestore_client
from app.schemas import SongResponse


class SongService:
    def __init__(self) -> None:
        self.db = get_firestore_client()

    def list_songs(self) -> list[SongResponse]:
        docs = (
            self.db.collection("songs")
            .order_by("releaseDate", direction=firestore.Query.DESCENDING)
            .stream()
        )
        songs: list[SongResponse] = []
        for doc in docs:
            data = doc.to_dict() or {}
            songs.append(
                SongResponse(
                    id=doc.id,
                    title=data.get("title", "Untitled"),
                    artist=data.get("artist"),
                    duration=data.get("duration"),
                    release_date=data.get("releaseDate"),
                    cover_url=data.get("coverUrl"),
                    audio_url=data.get("songUrl"),
                )
            )
        return songs
