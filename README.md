# MuseAI

MuseAI is a cross-platform AI music app built with Flutter, FastAPI, and Supabase. It lets users sign in, browse a demo song catalogue, generate original tracks from prompt/mood/genre/BPM input, play tracks in-app, and manage generated music through library and playlist flows.

The repository contains the mobile client, backend API, Supabase database schema, seed data, and automated tests.

## Project Goals

- Make AI-assisted music creation usable from a mobile-first interface.
- Support prompt-driven generation with clear processing, success, and failure states.
- Keep user data isolated through Supabase Auth, Postgres row-level security, and backend authorization.
- Provide a foundation for playlists, remixing, sharing, export, social discovery, and store release.

## Current Implementation

The app currently includes:

- Flutter app structure for Android, iOS, web, macOS, Linux, and Windows targets.
- MuseAI branding, Satoshi fonts, theme switching, splash, onboarding, auth, home, studio, library, playlist, profile, legal, and player screens.
- Supabase-backed authentication setup in Flutter.
- FastAPI backend routes for auth, songs, generations, playlists, public sharing, and account deletion.
- Generation flow that creates a backend job, polls status, and stores completed audio/cover assets.
- AI provider modes:
  - `mock`: offline WAV preview generation for local development.
  - `elevenlabs`: ElevenLabs Music API integration when credentials are configured.
- Supabase schema with tables, indexes, and RLS policies.
- Flutter tests for Cubits, repositories, use cases, splash behavior, and generation services.
- Backend pytest coverage for security and generation behavior.

Some production items remain open, including live Supabase validation, full production AI verification, export/download UI, social sign-in, release hardening, and store readiness. See [milestones.md](milestones.md).

## Architecture

```text
Flutter app
  presentation/  pages, widgets, Cubits, UI state
  domain/        entities, repository contracts, use cases
  data/          models, repository implementations, services
  core/          theme, assets, app config, failures

FastAPI backend
  app/api.py       HTTP routes
  app/services/   auth, users, songs, generations, playlists, storage
  app/schemas.py  request/response contracts
  app/security.py bearer token verification
  supabase/       schema and seed data

Supabase
  Auth       user identity and access tokens
  Postgres   users, songs, generations, playlists, pending_signups
  Storage    generated audio and cover assets
```

The Flutter app authenticates with Supabase, sends the Supabase access token to FastAPI, and the backend verifies the token before reading or mutating user-owned rows.

## Main User Flows

1. **Startup and auth**
   - `lib/main.dart` validates required Dart defines, initializes HydratedBloc and Supabase, registers dependencies, then opens `SplashPage`.
   - Auth screens use Supabase-backed services and route signed-in users into the app.

2. **Home and playback**
   - Home loads songs through `BackendSongService`.
   - The player uses `SongPlayerCubit` and `just_audio` to load either catalogue songs or generated tracks.

3. **AI generation**
   - Studio collects prompt, mood, genre, and BPM.
   - `StudioCubit` calls `CreateGenerationUsecase`.
   - `SupabaseGenerationService` posts to `/api/v1/generations`.
   - FastAPI creates a `generations` row and runs the generation worker.
   - Flutter polls `/api/v1/generations/{id}` until the status is `completed` or `failed`.

4. **Library and playlists**
   - Library and playlist Cubits use generation and playlist use cases.
   - Backend playlist routes support create, update, delete, add track, remove track, and reorder.

5. **Public sharing groundwork**
   - Public generations can receive a `share_slug`.
   - `/api/v1/public/generations/{share_slug}` returns public track data and owner details.

## Repository Map

| Path | Purpose |
|---|---|
| `lib/main.dart` | Flutter bootstrap and root `MaterialApp` |
| `lib/service_locator.dart` | `get_it` dependency registration |
| `lib/core/configs/app_config.dart` | Required runtime config keys |
| `lib/presentation/` | Screens, widgets, and Cubit state management |
| `lib/domain/` | Entities, use cases, and repository contracts |
| `lib/data/` | Models, data sources, and repository implementations |
| `backend/app/main.py` | FastAPI app setup |
| `backend/app/api.py` | API route definitions |
| `backend/app/services/` | Backend business logic |
| `backend/supabase/schema.sql` | Database schema, indexes, and RLS policies |
| `backend/supabase/seed.sql` | Demo seed data |
| `test/` | Flutter unit and widget tests |
| `backend/tests/` | Backend pytest suite |
| `assets/` | Fonts, images, vectors, and branding assets |

## Runtime Configuration

Flutter requires these Dart defines:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "BACKEND_BASE_URL": "http://127.0.0.1:8000"
}
```

Start from the example file:

```bash
cp flutter.env.example.json flutter.env.json
```

Then run:

```bash
flutter pub get
flutter run --dart-define-from-file=flutter.env.json
```

Do not commit real secrets. The checked-in `flutter.env.example.json` contains placeholders only.

## Backend Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
cp .env.example .env
uvicorn app.main:app --reload
```

Important backend environment values:

```text
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_ANON_KEY=
SUPABASE_STORAGE_BUCKET=museai-assets
AI_PROVIDER_MODE=mock
ELEVENLABS_API_KEY=
ALLOW_INSECURE_DEV_TOKENS=false
```

Use `AI_PROVIDER_MODE=mock` for offline development. Use `AI_PROVIDER_MODE=elevenlabs` with `ELEVENLABS_API_KEY` for real music generation.

Apply `backend/supabase/schema.sql` to the target Supabase project before using Supabase-backed routes. Seed demo data with:

```bash
cd backend
python scripts/seed_demo_data.py
```

## API Overview

The backend mounts routes under `/api/v1`.

| Area | Routes |
|---|---|
| Health | `GET /health` |
| Songs | `GET /songs` |
| Auth | `GET /auth/me`, `POST /auth/signup`, `POST /auth/signup/start`, `POST /auth/signup/verify`, `POST /auth/login`, `POST /auth/bootstrap-profile`, `POST /auth/password-reset-link`, `POST /auth/resend-verification`, `DELETE /auth/account` |
| Generations | `GET /generations`, `POST /generations`, `GET /generations/{id}`, `PATCH /generations/{id}`, `DELETE /generations/{id}`, `POST /generations/{id}/retry`, `POST /generations/{id}/remix` |
| Public | `GET /public/generations/{share_slug}` |
| Playlists | `GET /playlists`, `POST /playlists`, `GET /playlists/{id}`, `PATCH /playlists/{id}`, `DELETE /playlists/{id}`, `POST /playlists/{id}/tracks`, `DELETE /playlists/{id}/tracks/{track_id}`, `POST /playlists/{id}/reorder` |

Authenticated routes expect:

```text
Authorization: Bearer <supabase-access-token>
```

When `ALLOW_INSECURE_DEV_TOKENS=true`, local development can use:

```text
Authorization: Bearer dev:user-123:user@example.com
```

## Tests

Run Flutter tests:

```bash
flutter test
```

Run backend tests:

```bash
cd backend
pytest tests
```

See [testing_strategy.md](testing_strategy.md) for the full verification plan and release gates.

## Documentation

- [backend/README.md](backend/README.md) explains the backend service, configuration, API behavior, and Supabase requirements.
- [testing_strategy.md](testing_strategy.md) explains the test pyramid, commands, and milestone coverage expectations.
- [milestones.md](milestones.md) tracks production readiness across Flutter, backend, Supabase, AI generation, library, sharing, auth, accessibility, and release work.

