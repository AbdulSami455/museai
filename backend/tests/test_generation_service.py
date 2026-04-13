import wave
from io import BytesIO

from app.services.generation import GenerationService


def test_build_mock_wav_returns_valid_wav_bytes():
    audio = GenerationService._build_mock_wav(bpm=120, duration_seconds=1)
    assert audio.startswith(b"RIFF")

    with wave.open(BytesIO(audio), "rb") as wav_file:
        assert wav_file.getnchannels() == 1
        assert wav_file.getframerate() == 22050
        assert wav_file.getnframes() > 0


def test_build_cover_svg_embeds_prompt_metadata():
    svg = GenerationService._build_cover_svg(
        {"prompt": "lofi rain", "genre": "Lo-Fi", "mood": "Calm"}
    ).decode("utf-8")
    assert "lofi rain" in svg
    assert "Lo-Fi" in svg
    assert "Calm" in svg
