from datetime import datetime, timedelta, timezone

from postgrest.exceptions import APIError

from app.schemas import SongResponse
from app.supabase import require_supabase_client


DEMO_TRACK_TITLES = [
    "Midnight Aurora",
    "Neon Skyline",
    "Lofi Rain Circuit",
    "Solar Pulse",
    "Velvet Drive",
    "Polar Bloom",
    "Echo Harbor",
    "Silver Static",
    "Glass Horizon",
    "Night Engine",
    "Crimson Drift",
    "Signal Hearts",
]


class SongService:
    def __init__(self) -> None:
        self.db = require_supabase_client()

    def list_songs(self) -> list[SongResponse]:
        try:
            response = (
                self.db.table("songs")
                .select("*")
                .order("release_date", desc=True)
                .execute()
            )
        except APIError as exc:
            if "songs" in str(exc) and "schema cache" in str(exc):
                return self._demo_songs()
            raise
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

    def _demo_songs(self) -> list[SongResponse]:
        now = datetime.now(timezone.utc)
        songs: list[SongResponse] = []
        for index, title in enumerate(DEMO_TRACK_TITLES, start=1):
            songs.append(
                SongResponse(
                    id=f"demo-song-{index:03d}",
                    title=title,
                    artist=f"MuseAI Demo Vol. {(index % 4) + 1}",
                    duration=150 + (index * 7 % 80),
                    release_date=now - timedelta(days=index),
                    cover_url=f"https://picsum.photos/seed/museai-song-{index}/600/600",
                    audio_url=(
                        "https://www.soundhelix.com/examples/mp3/"
                        f"SoundHelix-Song-{((index - 1) % 16) + 1}.mp3"
                    ),
                )
            )
        return songs
