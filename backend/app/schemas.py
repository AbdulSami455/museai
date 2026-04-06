from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class GenerationStatus(str, Enum):
    processing = "processing"
    completed = "completed"
    failed = "failed"


class PlaylistVisibility(str, Enum):
    private = "private"
    public = "public"


class ProfileBootstrapRequest(BaseModel):
    full_name: Optional[str] = Field(default=None, max_length=120)


class PasswordResetLinkRequest(BaseModel):
    email: str


class PasswordResetLinkResponse(BaseModel):
    reset_link: str


class UserProfileResponse(BaseModel):
    uid: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    photo_url: Optional[str] = None
    created_at: Optional[datetime] = None


class SongResponse(BaseModel):
    id: str
    title: str
    artist: Optional[str] = None
    duration: Optional[float] = None
    release_date: Optional[datetime] = None
    cover_url: Optional[str] = None
    audio_url: Optional[str] = None


class GenerationCreateRequest(BaseModel):
    prompt: str = Field(min_length=3, max_length=500)
    mood: str = Field(min_length=2, max_length=50)
    genre: str = Field(min_length=2, max_length=50)
    bpm: int = Field(ge=40, le=220)
    instruments: list[str] = Field(default_factory=list)
    duration_seconds: int = Field(default=30, ge=10, le=180)
    is_public: bool = False


class GenerationUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, max_length=120)
    prompt: Optional[str] = Field(default=None, min_length=3, max_length=500)
    is_public: Optional[bool] = None


class GenerationRetryRequest(BaseModel):
    keep_prompt: bool = True


class GenerationResponse(BaseModel):
    id: str
    uid: str
    title: Optional[str] = None
    prompt: str
    mood: str
    genre: str
    bpm: int
    instruments: list[str] = Field(default_factory=list)
    duration_seconds: Optional[int] = None
    status: GenerationStatus
    audio_url: Optional[str] = None
    cover_url: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    error_message: Optional[str] = None
    parent_id: Optional[str] = None
    is_public: bool = False
    share_slug: Optional[str] = None


class PublicGenerationResponse(BaseModel):
    track: GenerationResponse
    owner: Optional[UserProfileResponse] = None


class PlaylistCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=280)
    visibility: PlaylistVisibility = PlaylistVisibility.private


class PlaylistUpdateRequest(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=280)
    visibility: Optional[PlaylistVisibility] = None


class PlaylistTrackMutationRequest(BaseModel):
    track_id: str


class PlaylistReorderRequest(BaseModel):
    track_ids: list[str]


class PlaylistResponse(BaseModel):
    id: str
    uid: str
    name: str
    description: Optional[str] = None
    visibility: PlaylistVisibility = PlaylistVisibility.private
    track_ids: list[str] = Field(default_factory=list)
    created_at: datetime
    updated_at: Optional[datetime] = None
