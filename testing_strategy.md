# MuseAI Testing Strategy

This document explains how to verify the MuseAI Flutter app, FastAPI backend, Supabase data layer, and AI generation flow.

## Testing Principles

- Test user-visible behavior and contracts before implementation details.
- Keep most checks fast and deterministic.
- Mock Supabase, HTTP, audio, and AI providers in unit tests.
- Use a dedicated Supabase development project or local stack for integration tests.
- Run at least one real provider generation before release because mock generation does not prove production AI behavior.
- Do not test Flutter, Supabase SDK, `just_audio`, FastAPI, or HTTPX internals.

## Test Pyramid

```text
          Device / E2E
      Integration / API
   Widget / Cubit / Repository
 Unit / Entity / Mapper / Use Case
```

| Layer | Target |
|---|---|
| Domain use cases and entities | 90% |
| Data repositories, models, services | 80% |
| Presentation Cubits | 80% |
| Pages and widgets | Critical flows only |
| Backend services and API | 85% |

## Existing Test Areas

Flutter tests currently cover:

- Splash routing behavior.
- `StudioCubit` state transitions.
- `SongPlayerCubit` dependency behavior.
- `NewsSongCubit` behavior.
- Generation use cases: create, watch, list.
- Generation repository and stub service behavior.
- Auth failure mapping.

Backend tests currently cover:

- Security/token behavior.
- Generation service behavior.

## Flutter Verification

Run all Flutter tests:

```bash
flutter test
```

Run a targeted test:

```bash
flutter test test/data/repository/generation_repository_impl_test.dart
```

Run static analysis:

```bash
flutter analyze
```

High-value Flutter coverage:

- `SplashPage` chooses auth or onboarding route correctly.
- Auth screens show validation and backend errors.
- Studio handles idle, submitting, processing, completed, and failed states.
- Generation repository maps service errors into domain failures.
- Library shows generated tracks newest first.
- Playlist Cubits create, rename, delete, add, remove, and reorder tracks.
- Player loads both `SongEntity` and `GenerationEntity`.
- Legal/profile/settings routes render without crashing.

## Backend Verification

Run all backend tests:

```bash
cd backend
pytest tests
```

High-value backend coverage:

- Valid Supabase tokens are accepted.
- Invalid tokens are rejected.
- Local `dev:` tokens work only when `ALLOW_INSECURE_DEV_TOKENS=true`.
- Missing Supabase tables return useful setup errors.
- Generation rows transition from `processing` to `completed` or `failed`.
- Retry and remix create new rows with correct source relationship.
- Playlist CRUD enforces current-user ownership.
- Account deletion removes user rows and generated assets.
- Public generation route only returns tracks marked public.

## Integration Environment

Use integration tests when behavior depends on real infrastructure:

- Supabase Auth session creation and refresh.
- RLS policy enforcement for users, generations, and playlists.
- Supabase Storage uploads, deletes, signed URLs, and bucket policies.
- FastAPI token verification against real Supabase keys.
- Flutter-to-backend generation polling.

Recommended integration setup:

1. Use a dedicated Supabase dev project or local Supabase stack.
2. Apply `backend/supabase/schema.sql`.
3. Seed deterministic data from `backend/supabase/seed.sql` or `backend/scripts/seed_demo_data.py`.
4. Use unique user ids/emails per test run.
5. Clean up generated rows and storage paths after the run.

## End-to-End Release Flows

Before a release candidate, verify these flows on representative Android and iOS devices:

1. Install fresh app.
2. Sign up, verify account if enabled, and land in the app.
3. Sign out and sign back in.
4. Relaunch app and confirm session persistence.
5. Load home song catalogue.
6. Play/pause/seek a catalogue song.
7. Create an AI generation from Studio.
8. Confirm generation reaches `completed` and opens in player.
9. Confirm failed generation shows a readable error and retry path.
10. Rename/delete a generated track from Library.
11. Create playlist, add track, remove track, reorder track, delete playlist.
12. Toggle public sharing and open public shared URL/API response.
13. Reset password.
14. Delete account and verify user data is gone.

## Milestone Coverage

| Milestone | Required checks |
|---|---|
| Codebase Health | `flutter analyze`, app boot smoke tests, auth smoke tests |
| Supabase Migration | live Supabase auth, songs load, RLS isolation checks |
| AI Generation Core | create/watch/play generation flow, provider failure handling |
| Library and Playlists | playlist CRUD, generated track listing, navigation from library to player |
| Remix, Export, Sharing | remix parent link, public sharing, download/share file validation |
| Auth and Onboarding | signup, login, reset, profile bootstrap, account deletion |
| Polish and Accessibility | contrast, screen reader labels, tap target size, loading/empty/error states |
| Pre-Launch | Android release bundle, Xcode archive/TestFlight, physical device regression |

## Performance and Reliability Gates

- Warm Library load target: under 1 second when cached.
- UI response target: under 2 seconds for normal screen transitions.
- Generation target: completed playable track within 90 seconds in production conditions.
- Backend generation job error rate target: below 1% over a 48-hour staging window.
- App crash-free target: above 99.5% before public release.

## Exit Rule

A feature is complete only when:

- Unit or Cubit tests cover normal and failure behavior.
- Integration tests cover infrastructure-dependent behavior where relevant.
- User-facing errors are readable.
- Security boundaries are tested for current-user ownership.
- The matching milestone exit criteria in [milestones.md](milestones.md) are satisfied.

