# MuseAI — Testing Strategy

> **Audience:** Flutter team and backend developer.
> **Last updated:** 2026-05-05
> **Companion document:** `milestones.md`

---

## 1. Principles

- Test behaviour, not implementation details.
- Prefer fast unit tests first, then add widget, integration, and E2E coverage only where risk justifies the cost.
- Keep Flutter tests independent from global service locators by injecting collaborators directly.
- Treat Supabase as infrastructure: mock it in unit tests, isolate it in integration tests, and verify end-to-end flows separately.
- Do not test framework internals such as Flutter widgets, Supabase SDK internals, or `just_audio` internals.

---

## 2. Test Pyramid

```text
        E2E / Device Tests
    Integration / Backend API Tests
      Widget / Cubit / Repository
     Unit / Mapper / Use Case Tests
```

### Coverage targets

| Layer | Target |
|-------|--------|
| Domain (use cases, entities) | 90% |
| Data (repositories, mappers, services) | 80% |
| Presentation (Cubits) | 80% |
| Presentation (pages/widgets) | Critical flows only |
| Backend services/API | 85% |

---

## 3. Tooling

### Flutter

| Tool | Purpose |
|------|---------|
| `flutter_test` | Unit and widget tests |
| `bloc_test` | Cubit state sequence testing |
| `mocktail` | Mocking dependencies |
| `integration_test` | Device or emulator E2E flows |

### Backend

| Tool | Purpose |
|------|---------|
| `pytest` | Unit and API tests |
| `httpx` test helpers / mocks | Mocking external HTTP calls |
| Dedicated Supabase dev project or local stack | Integration environment |

---

## 4. What To Test

### Flutter unit tests

- All use cases return the correct `Failure` or success value.
- Repository implementations map service failures into domain failures correctly.
- Entity and model mapping is covered for nullable and optional fields.
- `StudioCubit`, `SongPlayerCubit`, and auth-related Cubits cover their main state transitions.

### Flutter widget tests

- Splash routing for authenticated vs unauthenticated users.
- Auth screens render validation and backend error states correctly.
- Studio flow handles idle, submitting, processing, completed, and failed states.
- Song player renders track metadata and playback controls without crashing.

### Flutter integration / E2E

- Sign up or sign in, land on the correct home screen, and keep session state after relaunch.
- Create a generation request and observe it move to a playable completed state.
- Open a generated track in the player and confirm playback UI loads correctly.

### Backend tests

- Auth token verification handles valid Supabase tokens, invalid tokens, and local dev tokens.
- Generation service persists the correct row shape and transitions `processing -> completed` or `failed`.
- Playlist CRUD enforces per-user isolation and stable ordering rules.
- User deletion removes rows plus stored assets for that user.
- Storage helpers return valid signed/public asset URLs and surface provider failures clearly.

---

## 5. Environment Strategy

### Local fast feedback

- Run Flutter unit and widget tests without real network access.
- Run backend unit tests with mocked Supabase and storage interactions.

### Integration environment

- Use a dedicated Supabase development project or local Supabase stack.
- Seed deterministic `users`, `songs`, `generations`, and `playlists` fixtures before integration runs.
- Keep test data isolated per run so repeated executions do not share state.

### Release gating

- Android and iOS smoke tests must pass on real devices or representative emulators.
- Generation latency and failure handling must be validated against the real backend path before release.

---

## 6. Milestone Mapping

### Milestone 0 — Codebase Health

- `flutter analyze`
- Auth happy-path widget tests
- App boot smoke tests on Android and iOS

### Milestone 1.5 / 1 — Supabase Migration and AI Generation Core

- Auth session persistence tests
- Song catalogue load tests against Supabase-backed data
- Generation create/watch/play flow tests
- Backend generation pipeline tests, including failure states

### Milestone 2 — Library and Playlists

- Playlist CRUD unit and API tests
- Generated track listing order and filtering tests
- Player navigation from library views

### Milestone 3 — Remix, Export, and Sharing

- Remix creates a linked child generation
- Shared/public track visibility rules
- Export/download response validation

### Milestone 4 — Auth Completion and Onboarding

- Password reset link generation
- Profile bootstrap and account deletion
- Returning-user and first-run onboarding flows

### Milestone 5 / 6 — Polish and Pre-Launch

- Performance regression checks
- Accessibility smoke tests
- End-to-end release checklist on supported devices

---

## 7. Commands

```bash
# Flutter
flutter test

# Targeted Flutter file
flutter test test/data/repository/generation_repository_impl_test.dart

# Backend
cd backend && pytest tests
```

---

## 8. Exit Criteria

- New features ship with tests at the appropriate layer.
- High-risk flows have at least one integration or E2E path.
- No milestone is considered complete until its documented exit criteria in `milestones.md` pass.
