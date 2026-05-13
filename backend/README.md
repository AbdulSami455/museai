# MuseAI FastAPI Backend

This backend is the server-side API for the MuseAI Flutter app. It verifies Supabase users, exposes song/library/playlist/auth endpoints, starts AI generation jobs, stores generated assets, and returns signed or public URLs for playback.

## Responsibilities

- Verify Supabase bearer tokens for authenticated requests.
- Provide local `dev:<uid>[:email]` tokens when explicitly enabled for development.
- Bootstrap and manage user profiles.
- Support signup verification, login, password reset links, verification resend, and account deletion.
- Serve the song catalogue used by the Flutter home screen.
- Create, poll, update, retry, remix, share, and delete generation jobs.
- Generate audio through either a mock local generator or ElevenLabs Music API.
- Store generated audio and cover assets in Supabase Storage or local storage fallback.
- Manage playlists and playlist track order.

## Runtime Shape

```text
app/main.py
  creates FastAPI app
  configures CORS
  mounts /api/v1 routes
  mounts /assets for local storage fallback

app/api.py
  defines health, auth, songs, generations, public, and playlist routes

app/services/
  user.py        auth/profile/account operations
  song.py        catalogue reads
  generation.py  generation lifecycle and AI provider calls
  playlist.py    playlist CRUD and track membership
  storage.py     Supabase/local storage helpers

app/security.py
  bearer token verification and CurrentUser model

app/config.py
  environment-driven settings
```

## Data Model

The Supabase schema is stored at `backend/supabase/schema.sql`.

| Table | Purpose |
|---|---|
| `users` | App profile rows keyed by Supabase user id |
| `songs` | Seed/demo catalogue songs |
| `generations` | User-created AI tracks, status, parameters, storage paths, sharing data |
| `playlists` | User playlist metadata and ordered `track_ids` |
| `pending_signups` | Temporary signup verification records |

RLS is enabled for all tables. Users can access their own rows, authenticated users can read songs, and public generation reads are limited through the backend public route.

## Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
cp .env.example .env
uvicorn app.main:app --reload
```

The app runs at `http://127.0.0.1:8000` by default. API routes are under `/api/v1`, for example:

```text
http://127.0.0.1:8000/api/v1/health
```

## Environment

Common settings:

```text
PROJECT_NAME=MuseAI Backend
API_PREFIX=/api/v1
APP_BASE_URL=http://127.0.0.1:8000
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_ANON_KEY=
SUPABASE_STORAGE_BUCKET=museai-assets
SIGNED_ASSET_URL_TTL_SECONDS=3600

AI_PROVIDER_MODE=mock
AI_GENERATION_DELAY_SECONDS=3
DEFAULT_TRACK_DURATION_SECONDS=30

ELEVENLABS_API_KEY=
ELEVENLABS_BASE_URL=https://api.elevenlabs.io
ELEVENLABS_MUSIC_MODEL_ID=music_v1
ELEVENLABS_OUTPUT_FORMAT=

ALLOW_INSECURE_DEV_TOKENS=false
LOCAL_STORAGE_DIR=local_storage

BREVO_API_KEY=
BREVO_SENDER_EMAIL=
BREVO_SENDER_NAME=MuseAI
```

Use `AI_PROVIDER_MODE=mock` for local/offline testing. Use `AI_PROVIDER_MODE=elevenlabs` only after adding `ELEVENLABS_API_KEY`.

If Supabase URL or service role key is missing, generated assets are served from the local `/assets` mount. Production should use Supabase configuration and storage.

## Supabase Setup

1. Create or open a Supabase project.
2. Apply `backend/supabase/schema.sql` in the SQL editor or migration workflow.
3. Create the configured storage bucket, default `museai-assets`.
4. Add service role and anon keys to `backend/.env`.
5. Seed demo songs if needed:

```bash
cd backend
python scripts/seed_demo_data.py
```

## Authentication

Most routes require:

```text
Authorization: Bearer <supabase-access-token>
```

For local development only, set:

```text
ALLOW_INSECURE_DEV_TOKENS=true
```

Then call authenticated routes with:

```text
Authorization: Bearer dev:user-123:user@example.com
```

Do not enable insecure dev tokens in production.

## API Surface

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Backend liveness check |
| `GET` | `/songs` | List catalogue songs |
| `GET` | `/auth/me` | Get current user profile |
| `POST` | `/auth/signup` | Direct signup |
| `POST` | `/auth/signup/start` | Start code-based signup verification |
| `POST` | `/auth/signup/verify` | Verify signup code |
| `POST` | `/auth/login` | Login |
| `POST` | `/auth/bootstrap-profile` | Create/update profile row for current user |
| `POST` | `/auth/password-reset-link` | Generate password reset link |
| `POST` | `/auth/resend-verification` | Resend verification email |
| `DELETE` | `/auth/account` | Delete current user data and assets |
| `GET` | `/generations` | List current user's generated tracks |
| `POST` | `/generations` | Create generation job |
| `GET` | `/generations/{id}` | Fetch one generation |
| `PATCH` | `/generations/{id}` | Rename/update prompt/share state |
| `DELETE` | `/generations/{id}` | Delete generation and remove it from playlists |
| `POST` | `/generations/{id}/retry` | Retry generation using existing parameters |
| `POST` | `/generations/{id}/remix` | Create child generation from an existing track |
| `GET` | `/public/generations/{share_slug}` | Fetch public shared generation |
| `GET` | `/playlists` | List playlists |
| `POST` | `/playlists` | Create playlist |
| `GET` | `/playlists/{id}` | Fetch playlist |
| `PATCH` | `/playlists/{id}` | Update playlist metadata |
| `DELETE` | `/playlists/{id}` | Delete playlist |
| `POST` | `/playlists/{id}/tracks` | Add generation to playlist |
| `DELETE` | `/playlists/{id}/tracks/{track_id}` | Remove generation from playlist |
| `POST` | `/playlists/{id}/reorder` | Replace playlist track order |

## Generation Lifecycle

1. Flutter posts prompt, mood, genre, BPM, duration, instruments, and sharing preference to `POST /generations`.
2. Backend inserts a `generations` row with `status=processing`.
3. FastAPI background task runs `GenerationService.process_generation_job`.
4. Provider mode decides how audio is produced:
   - `mock` creates a short WAV preview.
   - `elevenlabs` calls ElevenLabs Music API.
5. Backend creates SVG cover art, uploads audio and cover assets, and updates the row to `completed`.
6. On provider/storage failure, the row becomes `failed` with `error_message`.
7. Flutter polls `GET /generations/{id}` until it can play the result or show an error.

## Tests

```bash
cd backend
pytest tests
```

Backend tests cover security behavior and generation service behavior. Broader release validation should include a live Supabase project and a real AI provider run.

