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

## Auth in local development

If `ALLOW_INSECURE_DEV_TOKENS=true`, you can call authenticated routes with:

```text
Authorization: Bearer dev:user-123:user@example.com
```

## Important notes

- `AI_PROVIDER_MODE=mock` generates a short WAV preview plus SVG cover art so the full flow works without an external AI vendor.
- In production, replace the mock provider in `app/services/generation.py` with a real provider call and keep credentials in environment variables or Secret Manager.
- The backend assumes the Flutter app will sign users in with Supabase Auth and send the Supabase access token to FastAPI.
