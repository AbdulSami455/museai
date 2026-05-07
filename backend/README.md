# MuseAI FastAPI Backend

This service provides a production-ready backend for the MuseAI Flutter app using:

- `FastAPI` for HTTP APIs
- `Supabase Auth` for identity verification
- `Supabase Postgres` for app data
- `Supabase Storage` for generated audio and cover assets

## Features

- Supabase bearer token verification with a local `dev:<uid>[:email]` fallback
- User profile bootstrap and password-reset link generation
- Song catalogue read APIs
- AI track generation with background processing
- ElevenLabs music generation via `POST /v1/music`
- Library CRUD for user generations
- Remix, retry, rename, and public sharing controls
- Playlist CRUD and track membership management
- Account deletion that removes user data and stored assets

## Table layout

```text
users
songs
generations
playlists
```

## Quick start

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
cp .env.example .env
uvicorn app.main:app --reload
```

Required music generation env vars:

```text
ELEVENLABS_API_KEY=your-elevenlabs-api-key
AI_PROVIDER_MODE=elevenlabs
```

Seed demo songs into Supabase:

```bash
cd backend
python scripts/seed_demo_data.py
```

## Auth in local development

If `ALLOW_INSECURE_DEV_TOKENS=true`, you can call authenticated routes with:

```text
Authorization: Bearer dev:user-123:user@example.com
```

## Important notes

- `AI_PROVIDER_MODE=elevenlabs` uses the ElevenLabs Music API and reads credentials from `backend/.env`.
- `AI_PROVIDER_MODE=mock` is still available as an offline fallback and generates a short WAV preview plus SVG cover art.
- The backend assumes the Flutter app will sign users in with Supabase Auth and send the Supabase access token to FastAPI.
- Optional branded verification emails can be sent through Brevo by setting `BREVO_API_KEY` and sender env vars.
