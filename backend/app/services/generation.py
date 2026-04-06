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
from firebase_admin import firestore

from app.config import get_settings
from app.firebase import get_firestore_client
from app.schemas import (
    GenerationCreateRequest,
    GenerationResponse,
    GenerationStatus,
    GenerationUpdateRequest,
)
from app.security import CurrentUser
from app.services.firestore_utils import clean_none, snapshot_to_dict, utcnow
from app.services.storage import delete_file, upload_bytes


class GenerationService:
    def __init__(self) -> None:
        self.db = get_firestore_client()
        self.settings = get_settings()

    def _tracks(self, uid: str):
        return self.db.collection("generations").document(uid).collection("tracks")

    def _playlists(self, uid: str):
        return self.db.collection("playlists").document(uid).collection("lists")

    def _doc(self, uid: str, generation_id: str):
        return self._tracks(uid).document(generation_id)

    def _build_generation_payload(
        self,
        user: CurrentUser,
        payload: GenerationCreateRequest,
        *,
        parent_id: Optional[str] = None,
    ) -> dict:
        now = utcnow()
        return {
            "uid": user.uid,
            "title": None,
            "prompt": payload.prompt,
            "mood": payload.mood,
            "genre": payload.genre,
            "bpm": payload.bpm,
            "instruments": payload.instruments,
            "durationSeconds": payload.duration_seconds,
            "status": GenerationStatus.processing.value,
            "audioUrl": None,
            "coverUrl": None,
            "audioStoragePath": None,
            "coverStoragePath": None,
            "createdAt": now,
            "updatedAt": now,
            "errorMessage": None,
            "parentId": parent_id,
            "isPublic": payload.is_public,
            "shareSlug": uuid.uuid4().hex[:12] if payload.is_public else None,
        }

    def create_generation(
        self,
        user: CurrentUser,
        payload: GenerationCreateRequest,
        background_tasks: BackgroundTasks,
        *,
        parent_id: Optional[str] = None,
    ) -> GenerationResponse:
        doc_ref = self._tracks(user.uid).document()
        doc_ref.set(self._build_generation_payload(user, payload, parent_id=parent_id))
        background_tasks.add_task(self.process_generation_job, user.uid, doc_ref.id)
        return self.get_generation(user, doc_ref.id)

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
                "durationSeconds",
                self.settings.default_track_duration_seconds,
            ),
            is_public=existing.get("isPublic", False),
        )
        return self.create_generation(
            user,
            payload,
            background_tasks,
            parent_id=existing.get("parentId") or generation_id,
        )

    def list_generations(self, user: CurrentUser) -> list[GenerationResponse]:
        docs = (
            self._tracks(user.uid)
            .order_by("createdAt", direction=firestore.Query.DESCENDING)
            .stream()
        )
        return [self._to_generation(snapshot_to_dict(doc)) for doc in docs]

    def get_generation(self, user: CurrentUser, generation_id: str) -> GenerationResponse:
        data = self._ensure_exists(user.uid, generation_id)
        return self._to_generation(data)

    def update_generation(
        self,
        user: CurrentUser,
        generation_id: str,
        payload: GenerationUpdateRequest,
    ) -> GenerationResponse:
        doc_ref = self._doc(user.uid, generation_id)
        existing = self._ensure_exists(user.uid, generation_id)

        update_data = clean_none(
            {
                "title": payload.title,
                "prompt": payload.prompt,
                "isPublic": payload.is_public,
                "shareSlug": (
                    existing.get("shareSlug")
                    or uuid.uuid4().hex[:12]
                    if payload.is_public is True
                    else None
                    if payload.is_public is False
                    else existing.get("shareSlug")
                ),
                "updatedAt": utcnow(),
            }
        )
        doc_ref.update(update_data)
        return self.get_generation(user, generation_id)

    def delete_generation(self, user: CurrentUser, generation_id: str) -> None:
        doc_ref = self._doc(user.uid, generation_id)
        data = self._ensure_exists(user.uid, generation_id)

        delete_file(data.get("audioStoragePath"))
        delete_file(data.get("coverStoragePath"))

        for playlist_doc in self._playlists(user.uid).stream():
            playlist_data = playlist_doc.to_dict() or {}
            track_ids = playlist_data.get("trackIds", [])
            if generation_id in track_ids:
                playlist_doc.reference.update(
                    {
                        "trackIds": [track_id for track_id in track_ids if track_id != generation_id],
                        "updatedAt": utcnow(),
                    }
                )

        doc_ref.delete()

    def get_public_generation(self, share_slug: str) -> GenerationResponse:
        query = (
            self.db.collection_group("tracks")
            .where("shareSlug", "==", share_slug)
            .where("isPublic", "==", True)
            .limit(1)
            .stream()
        )
        doc = next(query, None)
        if doc is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Shared track not found")
        return self._to_generation(snapshot_to_dict(doc))

    def process_generation_job(self, uid: str, generation_id: str) -> None:
        doc_ref = self._doc(uid, generation_id)
        snapshot = doc_ref.get()
        if not snapshot.exists:
            return

        data = snapshot.to_dict() or {}
        doc_ref.update({"status": GenerationStatus.processing.value, "updatedAt": utcnow()})

        try:
            if self.settings.ai_generation_delay_seconds > 0:
                time.sleep(self.settings.ai_generation_delay_seconds)

            if self.settings.ai_provider_mode != "mock":
                raise RuntimeError(
                    "Only mock generation is implemented. Replace process_generation_job "
                    "with your vendor integration before production."
                )

            audio_bytes = self._build_mock_wav(
                bpm=data["bpm"],
                duration_seconds=data.get(
                    "durationSeconds",
                    self.settings.default_track_duration_seconds,
                ),
            )
            cover_bytes = self._build_cover_svg(data)

            audio_path = f"generations/{uid}/{generation_id}/audio.wav"
            cover_path = f"generations/{uid}/{generation_id}/cover.svg"
            audio_url = upload_bytes(audio_path, audio_bytes, "audio/wav")
            cover_url = upload_bytes(cover_path, cover_bytes, "image/svg+xml")

            doc_ref.update(
                {
                    "status": GenerationStatus.completed.value,
                    "audioUrl": audio_url,
                    "coverUrl": cover_url,
                    "audioStoragePath": audio_path,
                    "coverStoragePath": cover_path,
                    "updatedAt": utcnow(),
                    "errorMessage": None,
                }
            )
        except Exception as exc:
            doc_ref.update(
                {
                    "status": GenerationStatus.failed.value,
                    "updatedAt": utcnow(),
                    "errorMessage": str(exc),
                }
            )

    def _ensure_exists(self, uid: str, generation_id: str) -> dict:
        snapshot = self._doc(uid, generation_id).get()
        if not snapshot.exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Generation not found")
        return snapshot_to_dict(snapshot)

    def _to_generation(self, data: dict) -> GenerationResponse:
        return GenerationResponse(
            id=data["id"],
            uid=data["uid"],
            title=data.get("title"),
            prompt=data["prompt"],
            mood=data["mood"],
            genre=data["genre"],
            bpm=int(data["bpm"]),
            instruments=list(data.get("instruments", [])),
            duration_seconds=data.get("durationSeconds"),
            status=GenerationStatus(data["status"]),
            audio_url=data.get("audioUrl"),
            cover_url=data.get("coverUrl"),
            created_at=self._as_datetime(data.get("createdAt")),
            updated_at=self._as_datetime(data.get("updatedAt")),
            error_message=data.get("errorMessage"),
            parent_id=data.get("parentId"),
            is_public=bool(data.get("isPublic", False)),
            share_slug=data.get("shareSlug"),
        )

    @staticmethod
    def _as_datetime(value) -> datetime:
        if isinstance(value, datetime):
            return value
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
