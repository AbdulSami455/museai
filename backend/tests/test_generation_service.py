import wave
from io import BytesIO

from postgrest.exceptions import APIError

from app.services.generation import GenerationService
from app.services.playlist import PlaylistService


def test_build_mock_audio_bytes_returns_valid_wav_bytes():
    audio = GenerationService._build_mock_audio_bytes(bpm=120, duration_seconds=1)
    assert audio.startswith(b"RIFF")

    with wave.open(BytesIO(audio), "rb") as wav_file:
        assert wav_file.getnchannels() == 1
        assert wav_file.getframerate() == 22050
        assert wav_file.getnframes() > 0


def test_build_elevenlabs_prompt_includes_generation_metadata():
    prompt = GenerationService._build_elevenlabs_prompt(
        {
            "prompt": "warm lofi study beat",
            "genre": "Lo-Fi",
            "mood": "Calm",
            "bpm": 92,
            "instruments": ["rhodes", "vinyl crackle"],
        }
    )

    assert "warm lofi study beat" in prompt
    assert "Genre: Lo-Fi" in prompt
    assert "Mood: Calm" in prompt
    assert "Tempo: 92 BPM" in prompt
    assert "Featured instruments: rhodes, vinyl crackle" in prompt


def test_build_cover_svg_embeds_prompt_metadata():
    svg = GenerationService._build_cover_svg(
        {"prompt": "lofi rain", "genre": "Lo-Fi", "mood": "Calm"}
    ).decode("utf-8")
    assert "lofi rain" in svg
    assert "Lo-Fi" in svg
    assert "Calm" in svg


def test_audio_extension_for_content_type_maps_common_audio_types():
    assert GenerationService._audio_extension_for_content_type("audio/mpeg") == "mp3"
    assert GenerationService._audio_extension_for_content_type("audio/wav") == "wav"
    assert GenerationService._audio_extension_for_content_type("audio/ogg") == "ogg"


class _RaisesMissingTableQuery:
    def select(self, *_args, **_kwargs):
        return self

    def eq(self, *_args, **_kwargs):
        return self

    def order(self, *_args, **_kwargs):
        return self

    def execute(self):
        raise APIError(
            {
                "message": "Could not find the table 'public.generations' in the schema cache",
                "code": "PGRST205",
                "hint": None,
                "details": None,
            }
        )


class _RaisesMissingPlaylistTableQuery(_RaisesMissingTableQuery):
    def execute(self):
        raise APIError(
            {
                "message": "Could not find the table 'public.playlists' in the schema cache",
                "code": "PGRST205",
                "hint": None,
                "details": None,
            }
        )


class _FakeDb:
    def __init__(self, query):
        self._query = query

    def table(self, _name):
        return self._query


def test_list_generations_returns_empty_list_when_table_missing():
    service = GenerationService.__new__(GenerationService)
    service.db = _FakeDb(_RaisesMissingTableQuery())
    service.settings = None

    generations = service.list_generations(type("User", (), {"uid": "user-1"})())

    assert generations == []


def test_list_playlists_returns_empty_list_when_table_missing():
    service = PlaylistService.__new__(PlaylistService)
    service.db = _FakeDb(_RaisesMissingPlaylistTableQuery())

    playlists = service.list_playlists(type("User", (), {"uid": "user-1"})())

    assert playlists == []
