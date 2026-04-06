from __future__ import annotations

import io
import math
import struct
import time
import uuid
import wave
from datetime import datetime
from typing import Optional

from fastapi import BackgroundTasks, HTTPException, status

from app.config import get_settings
from app.schemas import (
    GenerationCreateRequest,
    GenerationResponse,
    GenerationStatus,
    GenerationUpdateRequest,
)
from app.security import CurrentUser
from app.services.firestore_utils import clean_none, utcnow
from app.services.storage import create_signed_url, delete_file, upload_bytes
from app.supabase import require_supabase_client


class GenerationService:
    def __init__(self) -> None:
        self.db = require_supabase_client()
        self.settings = get_settings()

    def _build_generation_payload(
        self,
        user: CurrentUser,
        payload: GenerationCreateRequest,
        *,
        generation_id: str,
        parent_id: Optional[str] = None,
    ) -> dict:
        now = utcnow().isoformat()
        return {
            "id": generation_id,
            "uid": user.uid,
            "title": None,
            "prompt": payload.prompt,
            "mood": payload.mood,
            "genre": payload.genre,
            "bpm": payload.bpm,
            "instruments": payload.instruments,
            "duration_seconds": payload.duration_seconds,
            "status": GenerationStatus.processing.value,
            "audio_url": None,
            "cover_url": None,
            "audio_storage_path": None,
            "cover_storage_path": None,
            "created_at": now,
            "updated_at": now,
            "error_message": None,
            "parent_id": parent_id,
            "is_public": payload.is_public,
            "share_slug": uuid.uuid4().hex[:12] if payload.is_public else None,
        }

    def create_generation(
        self,
        user: CurrentUser,
        payload: GenerationCreateRequest,
        background_tasks: BackgroundTasks,
        *,
        parent_id: Optional[str] = None,
    ) -> GenerationResponse:
        generation_id = str(uuid.uuid4())
        self.db.table("generations").insert(
            self._build_generation_payload(
                user,
                payload,
                generation_id=generation_id,
                parent_id=parent_id,
            )
        ).execute()
        background_tasks.add_task(self.process_generation_job, user.uid, generation_id)
        return self.get_generation(user, generation_id)

    def remix_generation(
        self,
        user: CurrentUser,
        source_id: str,
        payload: GenerationCreateRequest,
        background_tasks: BackgroundTasks,
    ) -> GenerationResponse:
        self._ensure_exists(user.uid, source_id)
        return self.create_generation(
            user,
            payload,
            background_tasks,
            parent_id=source_id,
        )

    def retry_generation(
        self,
        user: CurrentUser,
        generation_id: str,
        background_tasks: BackgroundTasks,
    ) -> GenerationResponse:
        existing = self._ensure_exists(user.uid, generation_id)
        payload = GenerationCreateRequest(
            prompt=existing["prompt"],
            mood=existing["mood"],
            genre=existing["genre"],
            bpm=existing["bpm"],
            instruments=existing.get("instruments", []),
            duration_seconds=existing.get(
                "duration_seconds",
                self.settings.default_track_duration_seconds,
            ),
            is_public=existing.get("is_public", False),
        )
        return self.create_generation(
            user,
            payload,
            background_tasks,
            parent_id=existing.get("parent_id") or generation_id,
        )

    def list_generations(self, user: CurrentUser) -> list[GenerationResponse]:
        response = (
            self.db.table("generations")
            .select("*")
            .eq("uid", user.uid)
            .order("created_at", desc=True)
            .execute()
        )
        return [self._to_generation(row) for row in (response.data or [])]

    def get_generation(self, user: CurrentUser, generation_id: str) -> GenerationResponse:
        return self._to_generation(self._ensure_exists(user.uid, generation_id))

    def update_generation(
        self,
        user: CurrentUser,
        generation_id: str,
        payload: GenerationUpdateRequest,
    ) -> GenerationResponse:
        existing = self._ensure_exists(user.uid, generation_id)
        update_data = clean_none(
            {
                "title": payload.title,
                "prompt": payload.prompt,
                "is_public": payload.is_public,
                "share_slug": (
                    existing.get("share_slug")
                    or uuid.uuid4().hex[:12]
                    if payload.is_public is True
                    else None
                    if payload.is_public is False
                    else existing.get("share_slug")
                ),
                "updated_at": utcnow().isoformat(),
            }
        )
        self.db.table("generations").update(update_data).eq("id", generation_id).eq(
            "uid", user.uid
        ).execute()
        return self.get_generation(user, generation_id)

    def delete_generation(self, user: CurrentUser, generation_id: str) -> None:
        data = self._ensure_exists(user.uid, generation_id)
        delete_file(data.get("audio_storage_path"))
        delete_file(data.get("cover_storage_path"))

        playlists = (
            self.db.table("playlists").select("*").eq("uid", user.uid).execute().data or []
        )
        for playlist in playlists:
            track_ids = list(playlist.get("track_ids", []))
            if generation_id in track_ids:
                track_ids = [track_id for track_id in track_ids if track_id != generation_id]
                self.db.table("playlists").update(
                    {"track_ids": track_ids, "updated_at": utcnow().isoformat()}
                ).eq("id", playlist["id"]).eq("uid", user.uid).execute()

        self.db.table("generations").delete().eq("id", generation_id).eq("uid", user.uid).execute()

    def get_public_generation(self, share_slug: str) -> GenerationResponse:
        response = (
            self.db.table("generations")
            .select("*")
            .eq("share_slug", share_slug)
            .eq("is_public", True)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Shared track not found",
            )
        return self._to_generation(rows[0])

    def process_generation_job(self, uid: str, generation_id: str) -> None:
        data = self._ensure_exists(uid, generation_id)
        self.db.table("generations").update(
            {"status": GenerationStatus.processing.value, "updated_at": utcnow().isoformat()}
        ).eq("id", generation_id).eq("uid", uid).execute()

        try:
            if self.settings.ai_generation_delay_seconds > 0:
                time.sleep(self.settings.ai_generation_delay_seconds)

            if self.settings.ai_provider_mode != "mock":
                raise RuntimeError(
                    "Only mock generation is implemented. Replace process_generation_job "
                    "with your vendor integration before production."
                )

            audio_bytes = self._build_mock_wav(
                bpm=int(data["bpm"]),
                duration_seconds=int(
                    data.get("duration_seconds", self.settings.default_track_duration_seconds)
                ),
            )
            cover_bytes = self._build_cover_svg(data)

            audio_path = "generations/{}/{}.wav".format(uid, generation_id)
            cover_path = "generations/{}/{}.svg".format(uid, generation_id)
            audio_url = upload_bytes(audio_path, audio_bytes, "audio/wav")
            cover_url = upload_bytes(cover_path, cover_bytes, "image/svg+xml")

            self.db.table("generations").update(
                {
                    "status": GenerationStatus.completed.value,
                    "audio_url": audio_url,
                    "cover_url": cover_url,
                    "audio_storage_path": audio_path,
                    "cover_storage_path": cover_path,
                    "updated_at": utcnow().isoformat(),
                    "error_message": None,
                }
            ).eq("id", generation_id).eq("uid", uid).execute()
        except Exception as exc:
            self.db.table("generations").update(
                {
                    "status": GenerationStatus.failed.value,
                    "updated_at": utcnow().isoformat(),
                    "error_message": str(exc),
                }
            ).eq("id", generation_id).eq("uid", uid).execute()

    def _ensure_exists(self, uid: str, generation_id: str) -> dict:
        response = (
            self.db.table("generations")
            .select("*")
            .eq("id", generation_id)
            .eq("uid", uid)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        if not rows:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Generation not found")
        return rows[0]

    def _to_generation(self, data: dict) -> GenerationResponse:
        audio_url = data.get("audio_url")
        cover_url = data.get("cover_url")
        audio_storage_path = data.get("audio_storage_path")
        cover_storage_path = data.get("cover_storage_path")

        try:
            if audio_storage_path:
                audio_url = create_signed_url(audio_storage_path)
            if cover_storage_path:
                cover_url = create_signed_url(cover_storage_path)
        except Exception:
            # Fall back to the stored URL if the signer is temporarily unavailable.
            pass

        return GenerationResponse(
            id=data["id"],
            uid=data["uid"],
            title=data.get("title"),
            prompt=data["prompt"],
            mood=data["mood"],
            genre=data["genre"],
            bpm=int(data["bpm"]),
            instruments=list(data.get("instruments", [])),
            duration_seconds=data.get("duration_seconds"),
            status=GenerationStatus(data["status"]),
            audio_url=audio_url,
            cover_url=cover_url,
            created_at=self._as_datetime(data.get("created_at")),
            updated_at=self._as_datetime(data.get("updated_at")),
            error_message=data.get("error_message"),
            parent_id=data.get("parent_id"),
            is_public=bool(data.get("is_public", False)),
            share_slug=data.get("share_slug"),
        )

    @staticmethod
    def _as_datetime(value) -> datetime:
        if isinstance(value, datetime):
            return value
        if isinstance(value, str):
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        return utcnow()

    @staticmethod
    def _build_mock_wav(*, bpm: int, duration_seconds: int) -> bytes:
        sample_rate = 22050
        frequency = max(120, min(880, int(220 + (bpm - 40) * 2)))
        amplitude = 16000
        frames = io.BytesIO()
        total_frames = sample_rate * duration_seconds

        with wave.open(frames, "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(sample_rate)
            for index in range(total_frames):
                value = int(
                    amplitude
                    * math.sin(2 * math.pi * frequency * (index / sample_rate))
                    * 0.5
                )
                wav_file.writeframesraw(struct.pack("<h", value))

        return frames.getvalue()

    @staticmethod
    def _build_cover_svg(data: dict) -> bytes:
        prompt = str(data.get("prompt", "MuseAI")).replace("&", "&amp;")
        genre = str(data.get("genre", "Unknown")).replace("&", "&amp;")
        mood = str(data.get("mood", "Unknown")).replace("&", "&amp;")
        svg = f"""
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#111827" />
      <stop offset="100%" stop-color="#9333ea" />
    </linearGradient>
  </defs>
  <rect width="1024" height="1024" fill="url(#grad)" />
  <circle cx="260" cy="250" r="180" fill="#f59e0b" opacity="0.35" />
  <circle cx="760" cy="700" r="240" fill="#22d3ee" opacity="0.25" />
  <text x="80" y="760" font-size="40" fill="#ffffff" font-family="Arial">MuseAI</text>
  <text x="80" y="830" font-size="64" fill="#ffffff" font-family="Arial">{genre} • {mood}</text>
  <text x="80" y="900" font-size="32" fill="#e5e7eb" font-family="Arial">{prompt[:60]}</text>
</svg>
"""
        return svg.strip().encode("utf-8")
