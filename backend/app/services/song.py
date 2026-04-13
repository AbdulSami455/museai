from app.schemas import SongResponse
from app.supabase import require_supabase_client


class SongService:
    def __init__(self) -> None:
        self.db = require_supabase_client()

    def list_songs(self) -> list[SongResponse]:
        response = (
            self.db.table("songs")
            .select("*")
            .order("release_date", desc=True)
            .execute()
        )
        songs: list[SongResponse] = []
        for data in response.data or []:
            songs.append(
                SongResponse(
                    id=data.get("id", ""),
                    title=data.get("title", "Untitled"),
                    artist=data.get("artist"),
                    duration=data.get("duration"),
                    release_date=data.get("release_date") or data.get("releaseDate"),
                    cover_url=data.get("cover_url") or data.get("coverUrl"),
                    audio_url=data.get("audio_url") or data.get("songUrl"),
                )
            )
        return songs
