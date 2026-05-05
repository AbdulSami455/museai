from __future__ import annotations

import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import NAMESPACE_URL, uuid5

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.config import get_settings
from app.supabase import require_supabase_client


MOODS = [
    "Energetic",
    "Calm",
    "Happy",
    "Dark",
    "Romantic",
    "Melancholic",
    "Dreamy",
    "Aggressive",
]

GENRES = [
    "Electronic",
    "Pop",
    "Lo-Fi",
    "Hip-Hop",
    "Ambient",
    "Rock",
    "Jazz",
    "Synthwave",
]

ARTISTS = [
    "MuseAI Originals",
    "Neon Workshop",
    "Signal Bloom",
    "Midnight Atlas",
    "Dream Circuit",
    "City Static",
    "Solar Echo",
    "Velvet Transit",
]

INSTRUMENT_SETS = [
    ["synth", "bass", "drums"],
    ["piano", "strings", "pad"],
    ["guitar", "bass", "drums"],
    ["keys", "808", "lead"],
    ["flute", "pad", "percussion"],
]

TRACK_TITLES = [
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
    "Cloud Metro",
    "Afterlight",
    "Amber Frequency",
    "Frost Avenue",
    "Pulse Theory",
    "Ocean Memory",
    "Nova Carousel",
    "Parallel Sunset",
    "City Reverie",
    "Dream Operator",
    "Electric Bloom",
    "Quiet Runway",
    "Moonlit Relay",
    "Aurora Tides",
    "Chrome Meadow",
    "Summer Phantom",
    "Gravity Motel",
    "Soft Voltage",
]

TITLE_SUFFIXES = [
    "Extended Mix",
    "Live Session",
    "After Hours",
    "Club Edit",
    "Studio Cut",
]

PROMPTS = [
    "upbeat night drive with shimmering synths",
    "emotional piano ballad with cinematic rise",
    "lofi beat for coding in the rain",
    "festival anthem with big drops and bass",
    "late-night chill groove with warm pads",
    "dreamy ambient soundscape for focus",
    "romantic city-pop groove with vintage drums",
    "dark trap beat with tense atmosphere",
    "indie rock track with soaring guitars",
    "jazzy sunset lounge arrangement",
]

USER_COUNT = 12
SONG_COUNT = 150
GENERATION_COUNT = 120
PLAYLIST_COUNT = 24


def make_id(kind: str, value: str) -> str:
    return str(uuid5(NAMESPACE_URL, f"museai:{kind}:{value}"))


def iso_days_ago(days_ago: int) -> str:
    return (datetime.now(timezone.utc) - timedelta(days=days_ago)).isoformat()


def build_users() -> list[dict]:
    users: list[dict] = []
    for index in range(1, USER_COUNT + 1):
        users.append(
            {
                "id": f"demo-user-{index:03d}",
                "email": f"demo.user.{index:03d}@museai.local",
                "full_name": f"Demo Producer {index:02d}",
                "photo_url": f"https://picsum.photos/seed/museai-user-{index}/300/300",
                "created_at": iso_days_ago(45 - min(index, 40)),
                "updated_at": iso_days_ago((index % 5) + 1),
            }
        )
    return users


def build_songs() -> list[dict]:
    songs: list[dict] = []
    for index in range(1, SONG_COUNT + 1):
        base_title = TRACK_TITLES[(index - 1) % len(TRACK_TITLES)]
        suffix = TITLE_SUFFIXES[((index - 1) // len(TRACK_TITLES)) % len(TITLE_SUFFIXES)]
        title = base_title if index <= len(TRACK_TITLES) else f"{base_title} {suffix}"
        songs.append(
            {
                "id": make_id("song", str(index)),
                "title": title,
                "artist": ARTISTS[(index - 1) % len(ARTISTS)],
                "duration": 150 + (index * 7 % 80),
                "cover_url": f"https://picsum.photos/seed/museai-song-{index}/600/600",
                "audio_url": f"https://www.soundhelix.com/examples/mp3/SoundHelix-Song-{((index - 1) % 16) + 1}.mp3",
                "release_date": iso_days_ago(index),
            }
        )
    return songs


def build_generations(songs: list[dict]) -> list[dict]:
    generations: list[dict] = []
    user_ids = [f"demo-user-{index:03d}" for index in range(1, USER_COUNT + 1)]
    statuses = ["completed", "completed", "completed", "processing", "failed"]
    for index in range(1, GENERATION_COUNT + 1):
        user_id = user_ids[(index - 1) % len(user_ids)]
        mood = MOODS[(index - 1) % len(MOODS)]
        genre = GENRES[(index - 1) % len(GENRES)]
        prompt = PROMPTS[(index - 1) % len(PROMPTS)]
        track_id = ((index - 1) % SONG_COUNT) + 1
        status = statuses[(index - 1) % len(statuses)]
        title = songs[track_id - 1]["title"]
        generations.append(
            {
                "id": f"demo-generation-{index:03d}",
                "uid": user_id,
                "title": title,
                "prompt": prompt,
                "mood": mood,
                "genre": genre,
                "bpm": 90 + (index * 5 % 60),
                "instruments": INSTRUMENT_SETS[(index - 1) % len(INSTRUMENT_SETS)],
                "duration_seconds": 30,
                "status": status,
                "audio_url": (
                    None
                    if status != "completed"
                    else f"https://www.soundhelix.com/examples/mp3/SoundHelix-Song-{((index - 1) % 16) + 1}.mp3"
                ),
                "cover_url": (
                    None
                    if status == "failed"
                    else f"https://picsum.photos/seed/museai-generation-{index}/600/600"
                ),
                "audio_storage_path": None,
                "cover_storage_path": None,
                "error_message": None if status != "failed" else "Mock generation failed for testing.",
                "parent_id": None if index <= 20 else f"demo-generation-{((index - 1) % 20) + 1:03d}",
                "is_public": index % 3 != 0,
                "share_slug": f"demo-track-{index:03d}",
                "created_at": iso_days_ago(index),
                "updated_at": iso_days_ago(max(index - 1, 0)),
            }
        )
    return generations


def build_playlists() -> list[dict]:
    playlists: list[dict] = []
    user_ids = [f"demo-user-{index:03d}" for index in range(1, USER_COUNT + 1)]
    for index in range(1, PLAYLIST_COUNT + 1):
        user_id = user_ids[(index - 1) % len(user_ids)]
        start = ((index - 1) * 5 % GENERATION_COUNT) + 1
        track_ids = [
            f"demo-generation-{((start + offset - 1) % GENERATION_COUNT) + 1:03d}"
            for offset in range(5)
        ]
        playlists.append(
            {
                "id": f"demo-playlist-{index:03d}",
                "uid": user_id,
                "name": f"Demo Playlist {index}",
                "description": f"Seeded playlist {index} for showcase and testing.",
                "visibility": "public" if index % 2 == 0 else "private",
                "track_ids": track_ids,
                "created_at": iso_days_ago(index + 5),
                "updated_at": iso_days_ago(index),
            }
        )
    return playlists


def main() -> None:
    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise RuntimeError("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before seeding.")

    users = build_users()
    songs = build_songs()
    generations = build_generations(songs)
    playlists = build_playlists()

    client = require_supabase_client()
    try:
        client.table("users").upsert(users).execute()
        client.table("songs").upsert(songs).execute()
        client.table("generations").upsert(generations).execute()
        client.table("playlists").upsert(playlists).execute()
    except Exception as exc:
        raise RuntimeError(
            "Failed to seed demo data. Apply backend/supabase/schema.sql first, "
            "then rerun this script."
        ) from exc

    print(
        json.dumps(
            {
                "seeded_users": len(users),
                "seeded_songs": len(songs),
                "seeded_generations": len(generations),
                "seeded_playlists": len(playlists),
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
