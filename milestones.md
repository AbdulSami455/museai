# MuseAI — Production Milestone Plan

> **Purpose:** A phased roadmap from current scaffolding to a production-grade, publicly releasable application.
> **Updated:** 2026-05-07
> **Current state:** Core app structure, MuseAI branding, Supabase auth/session handling, song catalogue playback, Studio generation flow, FastAPI + Supabase backend APIs for auth/generations/playlists, schema + RLS definitions, and basic backend tests are in place. The main remaining gaps are live Supabase environment verification, production AI generation integration, library/playlists UI, export/share flows, and release hardening.

---

## How to Read This Document

Each milestone has a **goal**, a list of **tasks** split by team (Flutter / Backend) with their GitHub issue numbers, and **exit criteria**. Tasks link to issues — use the issue number to find the PR that closes it. Do not advance until all exit criteria pass.

---

## Milestone 0 — Codebase Health 🔄 (refactor complete, runtime validation pending)

**Goal:** Fix foundational issues that will compound in cost if left until later. No new features — only stabilisation.

### Flutter tasks

- [x] #11 Rename Dart package from `spotify_clone` to `museai`
- [x] #12 Switch to constructor injection in use cases and repositories
- [x] #13 Replace `Either<String, dynamic>` with typed `Failure` classes
- [x] #14 Add auth session check in `SplashPage` (completed in the Supabase auth flow rewrite in #114)
- [x] #15 Register `SongPlayerCubit` as lazy singleton in `service_locator`
- [x] #16 Remove silent placeholder fallback from `SongServiceImpl` (rewritten for Supabase in #115)
- [x] #17 Rebrand user-visible strings from "Spotify Clone" to "MuseAI"

### Backend tasks

- [x] #18 Initialise `backend/` directory *(superseded by #111 Supabase migration)*
- [x] #19 Deploy initial security rules for users and songs *(superseded by #111)*

### Exit criteria

- [x] `flutter analyze` produces zero errors and zero warnings
- [ ] App installs and runs on Android and iOS without crashes
- [ ] Sign-up, sign-in, and sign-out all work end-to-end
- [ ] Returning users land on home page without re-authenticating
- [x] All import paths use `package:museai/...`

---

## Milestone 1.5 — Supabase Migration 🔄 (Flutter complete, backend integration mostly in place)

**Goal:** Complete the Supabase migration across the entire stack. Prerequisite for all further backend work.

### Flutter tasks

- [x] #113 Finalise `supabase_flutter` setup in `pubspec.yaml` + `main.dart`
- [x] #114 Rewrite the auth data source for Supabase Auth + fix `SplashPage`
- [x] #115 Rewrite the song data source and `SongModel` for Supabase
- [x] #116 Rewrite `GenerationModel` and `GenerationStubService` for Supabase
- [x] #117 Replace legacy backend-specific test helpers with Supabase test helpers
- [ ] #20 Confirm Flutter app connects to Supabase project without errors
- [x] #109 Swap `GenerationStubService` for `SupabaseGenerationService`

### Backend tasks

- [x] Supabase-backed FastAPI routes exist for auth, songs, generations, and playlists
- [x] Supabase schema, indexes, and RLS policies are defined in `backend/supabase/schema.sql`
- [ ] Apply schema/migrations to the target Supabase project and verify from a live environment
- [ ] Replace the mock backend generation worker with a production AI provider integration
- [ ] End-to-end test: deployed generation flow completes via Supabase-backed backend within 60s

### Exit criteria

- [ ] Flutter app boots and authenticates against Supabase with no errors
- [ ] `songs` table data loads on the home screen
- [ ] Generation create → backend job runs → completed row with valid `audio_url` within 60s

---

## Milestone 1 — AI Generation Core 🔄 (core flow implemented, production-grade validation pending)

**Goal:** A user can type a prompt, select mood/genre/BPM, tap Generate, and receive a playable AI-generated track within 60 seconds. The create/watch flow is implemented; the remaining work is production AI integration and end-to-end validation.

### Flutter tasks

- [x] #21 Add `GenerationEntity` and `GenerationModel`
- [x] #22 Add `GenerationRepository` (abstract) and `GenerationRepositoryImpl`
- [x] #23 Add `GenerationSupabaseService` and `GenerationSupabaseServiceImpl`
- [x] #24 Add use cases: `CreateGenerationUsecase`, `WatchGenerationUsecase`, `GetUserGenerationsUsecase`
- [x] #25 Register all generation classes in `service_locator.dart`
- [x] #26 Add `StudioCubit` with `Idle / Submitting / Processing / Completed / Failed` states
- [x] #27 Build Studio page UI
- [x] #28 Build generation progress widget
- [x] #29 Extend `SongPlayerCubit.loadSong()` to accept `GenerationEntity`
- [x] #30 Add collection path constants (`generations`, `playlists`) to avoid raw strings

### Backend tasks

- [x] Generation create/list/get/retry/remix APIs are implemented in `backend/app/api.py`
- [x] Background generation processing updates rows from `processing` to `completed` / `failed`
- [ ] Replace mock WAV generation with the production AI provider
- [ ] End-to-end test: generation completes within 60s in a deployed environment

### Exit criteria

- [x] User can submit a generation request from the Studio page
- [x] UI shows `processing` spinner while the backend job runs
- [ ] On completion, the generated track auto-loads in the player and plays
- [ ] On failure, a human-readable error message is shown with a retry button
- [ ] Generation completes in under 90 seconds for a 30-second track on a production network
- [ ] Supabase RLS prevents a user from reading another user's generations (verified manually)

---

## Milestone 2 — Library and Playlists 🔄 (backend groundwork done, Flutter UI pending)

**Goal:** Users can manage their generated tracks — browse history, rename tracks, add to playlists, and delete.

### Flutter tasks

- [ ] #40 Build My Library page
- [ ] #41 Build track row widget
- [ ] #42 Build Playlist list page and Playlist detail page
- [ ] #43 Add playlist and library use cases
- [ ] #44 Add `LibraryCubit` and `PlaylistCubit` with states
- [ ] #45 Add "Add to playlist" bottom sheet
- [ ] #46 Implement track rename
- [ ] #47 Add bottom navigation bar: **Create** | **Library** | **Discover**
- [ ] #48 Wire routing for all M2 flows

### Backend tasks

- [x] #121 Add Postgres indexes for `generations` and `playlists` queries
- [x] Playlist CRUD and track membership APIs are implemented
- [x] Generation deletion removes the track from all playlists

### Exit criteria

- [ ] Library shows all user's generated tracks, newest first
- [ ] User can delete a track from the library (also removes from all playlists)
- [ ] User can create, rename, and delete playlists
- [ ] User can add and remove tracks from playlists
- [ ] Empty states display correctly for first-time users
- [ ] Navigation between Create / Library / Discover feels seamless

---

## Milestone 3 — Remix, Export, and Sharing 🔄 (backend remix/share groundwork done)

**Goal:** Users can iterate on generated tracks (remix), download as MP3, and share to other apps.

### Flutter tasks

- [ ] #51 Add Remix button on player page
- [ ] #52 Implement MP3 download to device
- [ ] #53 Add download permission handling (Android + iOS)
- [ ] #54 Implement share via `share_plus`
- [ ] #55 Add share and download buttons to player and track row context menu
- [ ] #56 Show `parentId` in player for remixed tracks

### Backend tasks

- [x] #57 Remix generations reuse the same backend generation pipeline with `parent_id`
- [x] #58 `audio_url` values are served as signed Supabase Storage URLs

### Exit criteria

- [ ] Remix flow creates a new generation doc with correct `parentId` and pre-filled params
- [ ] Tapping Download saves a valid `.mp3` to the device
- [ ] Tapping Share opens the native share sheet with the audio file attached
- [ ] Download and share work on both Android and iOS

---

## Milestone 4 — Auth Completion and Onboarding 🔄 (verification flow and branding partly done)

**Goal:** Complete the authentication surface and first-run experience.

### Flutter tasks

- [ ] #59 Add Google Sign-In
- [ ] #60 Add Apple Sign-In
- [ ] #61 Add password reset flow
- [ ] #62 Add profile / settings screen
- [x] #63 Revamp Get Started / splash screens with MuseAI branding
- [ ] #64 Add in-app Privacy Policy and Terms of Service screens
- [ ] #65 Add account deletion flow

### Backend tasks

- [ ] #66 Enable Google and Apple sign-in in Supabase Auth dashboard
- [x] #120 Implement account deletion backend flow *(served via `/auth/account`)*

### Exit criteria

- [ ] New users can sign up with email, Google, or Apple
- [ ] Existing users can sign in with any of the three methods
- [ ] Password reset email is sent and received successfully
- [ ] Account deletion removes all user data within 60 seconds
- [x] First-run users see MuseAI-branded onboarding — no references to Spotify

---

## Milestone 5 — Performance, Polish, and Accessibility

**Goal:** The app feels fast, looks intentional, and is usable by people with disabilities.

### Flutter tasks

- [ ] #68 Add shimmer loading skeletons to Library and Discover screens
- [ ] #69 Add local cache for Library metadata (hive or isar)
- [ ] #70 Implement offline state detection and banner
- [ ] #71 Audit all `Semantics` labels for screen reader support
- [ ] #72 Ensure all tap targets are at least 48×48 dp
- [ ] #73 Verify and fix WCAG AA colour contrast (4.5:1)
- [ ] #74 Apply consistent MuseAI theming (`app_theme.dart`)
- [ ] #75 Fix typo: `'Not user found'` → `'No user found'`
- [ ] #76 Add unit tests for all use cases
- [ ] #77 Add widget tests for Studio, Library, and Player pages

### Backend tasks

- [ ] #122 Add Postgres indexes for all remaining collection queries
- [ ] #123 Review and tighten Supabase RLS policies and Storage policies
- [ ] #124 Set up logging and monitoring for backend generation jobs
- [ ] #125 Enforce Supabase RLS in production and audit anonymous access

### Exit criteria

- [ ] Library page renders in under 1 second on a warm start (local cache hit)
- [ ] All UI elements pass WCAG AA contrast check
- [ ] Screen reader can navigate all primary flows without unlabelled elements
- [ ] `flutter test` passes with > 70% code coverage on domain and data layers
- [ ] Zero Supabase RLS test failures
- [ ] Backend generation job error rate < 1% over a 48-hour period in staging

---

## Milestone 6 — Pre-Launch Hardening 🔄 (version bump done; release hardening pending)

**Goal:** The app is ready for submission to the App Store and Play Store.

### Flutter tasks

- [x] #83 Update `pubspec.yaml` version to `1.0.0+1`
- [ ] #84 Add app icons for all required iOS and Android sizes
- [ ] #85 Add splash screen matching brand colours
- [ ] #86 Configure Android `build.gradle` with correct `applicationId`
- [ ] #87 Configure iOS `Info.plist` with bundle ID and usage descriptions
- [ ] #88 Test on minimum supported OS: Android 9 (API 28) and iOS 15
- [ ] #89 Full regression test on physical device
- [ ] #90 Enable ProGuard / R8 obfuscation for Android release build

### Backend tasks

- [ ] #126 Set Supabase usage alerts and monitor free tier limits
- [ ] #127 Configure backend worker concurrency and rate limits
- [ ] #128 Load test: 50 concurrent generation requests via Supabase
- [ ] #129 Verify Supabase production project is on correct plan and region
- [ ] #130 Verify all secrets are stored in Supabase secrets and not hardcoded

### Exit criteria

- [ ] App passes Android bundle tool validation with no crashes
- [ ] App passes Xcode archive and TestFlight upload with no errors
- [ ] Privacy Policy and Terms of Service URLs resolve and load correctly in-app
- [ ] All third-party licences declared in the About / Legal screen
- [ ] AI music API terms of service permit royalty-free commercial use (confirmed in writing)

---

## Milestone 7 — Social Feed (Post-Launch v1.1)

**Goal:** Users can share generated tracks to an in-app public feed and discover tracks made by others.

*Deferred to after initial launch. Scope TBD based on user feedback.*

High-level scope:
- Public `feed` table with user-shared posts
- Feed page with infinite scroll
- Like / comment on posts
- Follow other users
- Push notifications

---

## Summary Timeline

| Milestone | Duration | Owner | Status |
|---|---|---|---|
| 0 — Codebase Health | 1 week | Flutter + Backend | 🔄 Refactor complete; device/auth runtime validation still open |
| 1.5 — Supabase Migration | 2 weeks | Flutter + Backend | 🔄 Flutter complete; live Supabase verification and production backend path still open |
| 1 — AI Generation Core | 3 weeks | Flutter + Backend | 🔄 Request/process/play flow exists; production AI integration and E2E validation still open |
| 2 — Library and Playlists | 2 weeks | Flutter + Backend | 🔄 Backend APIs/indexes done; Flutter library/playlists work still open |
| 3 — Remix, Export, Sharing | 2 weeks | Flutter | 🔄 Backend remix/public URL groundwork done; Flutter export/share UX still open |
| 4 — Auth Completion and Onboarding | 1 week | Flutter + Backend | 🔄 Email verification and branding done; social sign-in, reset, settings, deletion UI still open |
| 5 — Performance, Polish, Accessibility | 2 weeks | Flutter + Backend | ⬜ Mostly still open |
| 6 — Pre-Launch Hardening | 1 week | Flutter + Backend | 🔄 Version bumped; release configuration and store-readiness still open |
| **Total to launch** | **~14 weeks** | | |
| 7 — Social Feed (v1.1) | Post-launch | Flutter + Backend | ⬜ Deferred |

---

## Definition of "Production Grade"

- **Functional:** All M1–M4 exit criteria pass
- **Reliable:** Backend generation job error rate < 1%; app crash-free rate > 99.5%
- **Performant:** P95 generation latency < 90s; UI response < 2s for all screen loads
- **Secure:** Supabase RLS enforced on all tables; no plaintext secrets in any codebase
- **Accessible:** WCAG AA contrast; all interactive elements labelled for screen readers
- **Compliant:** Privacy Policy + ToS published; account deletion available; GDPR-compliant
- **Submittable:** App Store and Play Store listing complete; passes review guidelines
