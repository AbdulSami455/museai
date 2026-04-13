# MuseAI — Production Milestone Plan

> **Purpose:** A phased roadmap from current scaffolding to a production-grade, publicly releasable application.
> **Date:** 2026-03-29
> **Current state:** Core app structure, email/password auth, song catalogue playback, and placeholder data. No AI generation, no playlists, no social features.

---

## How to Read This Document

Each milestone has a **goal** (what done looks like), a list of **tasks** split by who owns them (Flutter team vs. Backend), and **exit criteria** — the specific, verifiable conditions that must be true before moving to the next milestone. Do not advance until all exit criteria pass.

Backend note:

- The backend architecture is now **FastAPI + Firebase Admin + Firestore + Storage**, not Firebase Cloud Functions.
- Wherever older tasks mention "Cloud Function", interpret that as the FastAPI generation pipeline or background job unless explicitly noted otherwise.

---

## Milestone 0 — Codebase Health (1 week)

**Goal:** Fix foundational issues that will compound in cost if left until later. No new features — only stabilisation.

### Flutter team tasks

- [X] Rename Dart package from `spotify_clone` to `museai` in `pubspec.yaml` and all import paths
- [X] Switch use cases and repository implementations from service-locator internal pulls (`sl<>` inside methods) to constructor injection
- [X] Replace `Either<String, dynamic>` with typed `Failure` classes (`AuthFailure`, `NetworkFailure`)
- [X] Add `FirebaseAuth.instance.currentUser` check in `SplashPage` to route returning users directly to home
- [X] Register `SongPlayerCubit` in `service_locator.dart` as a lazy singleton
- [X] Remove silent placeholder fallback from `SongFirebaseServiceImpl` — surface real errors as `Left` values
- [X] Update `MaterialApp` title and all user-visible strings from "Spotify Clone" to "MuseAI"

### Backend tasks

- [X] Initialise `backend/` directory with FastAPI scaffold, environment config, and local run documentation
- [X] Add Firebase Admin integration for Auth, Firestore, and Storage in the backend service
- [ ] Configure production Firebase Admin credentials and Storage bucket for non-dev environments
- [ ] Confirm Flutter app can reach the backend health endpoint and continue connecting to Firebase project without errors

### Exit criteria

- [ ] `flutter analyze` produces zero errors and zero warnings
- [ ] App installs and runs on Android and iOS without crashes
- [ ] Sign-up, sign-in, and sign-out all work end-to-end
- [ ] Returning users land on home page without re-authenticating
- [ ] All import paths use `package:museai/...`

---

## Milestone 1 — AI Generation Core (3 weeks)

**Goal:** A user can type a prompt, select mood/genre/BPM, tap Generate, and receive a playable AI-generated track within 60 seconds. This is the product's core value proposition.

### Flutter tasks

- [ ] Add `GenerationEntity` and `GenerationModel` matching the Firestore schema in `backend_dev_guide.md`
- [ ] Add `GenerationRepository` (abstract) and `GenerationRepositoryImpl` (reads/writes Firestore `generations` subcollection)
- [ ] Add `GenerationFirebaseService` and `GenerationFirebaseServiceImpl`
- [ ] Add use cases: `CreateGenerationUsecase`, `WatchGenerationUsecase`, `GetUserGenerationsUsecase`
- [ ] Register all new classes in `service_locator.dart`
- [ ] Add `StudioCubit` with states: `StudioIdle`, `StudioSubmitting`, `StudioProcessing`, `StudioCompleted`, `StudioFailed`
- [ ] Build Studio page: prompt `TextField`, mood chips, genre chips, BPM slider, instrument multi-select, Generate button
- [ ] Build generation progress widget: animated spinner, status text from Firestore stream, retry button, auto-navigate to player on completion
- [ ] Extend `SongPlayerCubit.loadSong()` to accept a `GenerationEntity` in addition to `SongEntity`
- [ ] Add `FirebaseConst.generations` and `FirebaseConst.playlists` constants

### Backend tasks

- [X] Implement FastAPI endpoints for generation create/list/get/update/delete
- [X] Implement backend generation actions for retry and remix
- [X] Implement background generation processing in FastAPI with a mock provider for end-to-end flow
- [X] Implement storage upload pipeline for generated audio and cover assets with Firebase Storage or local dev fallback
- [X] Persist generation documents under `generations/{uid}/tracks/{trackId}`
- [ ] Replace the mock generator with real AI parameter mapping and provider integration with retries
- [ ] Set `AI_MUSIC_API_KEY` and any vendor secrets via environment variables or a secret manager in production
- [ ] Deploy Firestore security rules for `generations` subcollection if the Flutter client still reads or writes it directly
- [ ] Deploy Storage rules for generated asset paths if the client accesses Storage directly
- [ ] Add end-to-end API tests: create generation request → background job runs → completed document exposes valid `audioUrl`

### Exit criteria

- [ ] User can submit a generation request from the Studio page
- [ ] UI shows `processing` spinner while the backend generation job runs
- [ ] On completion, the generated track auto-loads in the player and plays
- [ ] On failure, a human-readable error message is shown with a retry button
- [ ] Generation completes in under 90 seconds for a 30-second track on a production network
- [ ] Firestore security rules prevent a user from reading another user's generations (verified manually)
- [ ] FastAPI logs show no unhandled exceptions during generation processing

---

## Milestone 2 — Library and Playlists (2 weeks)

**Goal:** Users can manage their generated tracks — browse their history, rename tracks, add to playlists, and delete.

### Flutter tasks

- [ ] Build My Library page: `StreamBuilder` on `generations/{uid}/tracks`, sorted by `createdAt` descending, with swipe-to-delete and pull-to-refresh
- [ ] Build track row widget: cover art, title (derived from prompt), mood/genre chips, relative date, duration
- [ ] Build Playlist list page and Playlist detail page with reorderable track list
- [ ] Add use cases: `GetPlaylistsUsecase`, `CreatePlaylistUsecase`, `AddTrackToPlaylistUsecase`, `DeletePlaylistUsecase`
- [ ] Add `LibraryCubit` and `PlaylistCubit` with appropriate states
- [ ] Add "Add to playlist" bottom sheet in the player and track row long-press menu
- [ ] Implement track rename (update Firestore `prompt` field or add a separate `title` field)
- [ ] Add bottom navigation bar: **Create** (Studio) | **Library** | **Discover** (home/catalogue)
- [ ] Wire routing for all flows: Studio → progress → player, Library → player, Playlist → player

### Backend tasks

- [X] Implement playlist CRUD endpoints in FastAPI
- [X] Implement playlist track add/remove/reorder endpoints
- [X] Ensure deleting a generation removes it from all user playlists
- [ ] Deploy Firestore security rules for `playlists` subcollection if playlists remain client-accessible
- [ ] Confirm Firestore indexes for `generations` queries (ordered by `createdAt`) and any playlist-related lookups

### Exit criteria

- [ ] Library shows all user's generated tracks, newest first
- [ ] User can delete a track from the library (also removes from all playlists)
- [ ] User can create, rename, and delete playlists
- [ ] User can add and remove tracks from playlists
- [ ] Empty states display correctly (first-time user with no tracks or playlists)
- [ ] Navigation between Create / Library / Discover feels seamless with no navigation stack issues

---

## Milestone 3 — Remix, Export, and Sharing (2 weeks)

**Goal:** Users can iterate on generated tracks (remix with modified params), download as MP3, and share to other apps.

### Flutter tasks

- [ ] Add **Remix** button on player page — navigates to Studio pre-filled with parent track's params, sets `parentId` on new generation
- [ ] Implement MP3 download using `path_provider` + `dart:io` — save `audio.mp3` to device Downloads folder
- [ ] Add download permission handling for Android (`READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`) and iOS (`NSPhotoLibraryAddUsageDescription`)
- [ ] Implement share using `share_plus` — share the audio file or a deep link
- [ ] Add share and download buttons to both the player page and the track row context menu
- [ ] Show download progress indicator and success/failure toast
- [ ] Add `parentId` display in player ("Remixed from: [original prompt]") when applicable

### Backend tasks

- [X] Support remix generations with `parentId` through the same backend pipeline
- [X] Generate long-lived signed URLs for stored assets when Firebase Storage is used
- [ ] Replace mock WAV generation with provider-returned export format suitable for production download/sharing
- [ ] Verify royalty-free export rights with the final AI music provider terms of service

### Exit criteria

- [ ] Remix flow creates a new generation doc with correct `parentId` and all pre-filled params
- [ ] Tapping Download saves a valid `.mp3` file to the device that plays in the system media player
- [ ] Tapping Share opens the native share sheet with the audio file attached
- [ ] Download and share work on both Android and iOS
- [ ] Exported files are royalty-free (verified with AI API terms of service)

---

## Milestone 4 — Auth Completion and Onboarding (1 week)

**Goal:** Complete the authentication surface and first-run experience so new users are immediately productive.

### Flutter tasks

- [ ] Add Google Sign-In (using `firebase_auth` + `google_sign_in` packages)
- [ ] Add Apple Sign-In (required for App Store if Google Sign-In is offered)
- [ ] Add password reset flow: email field → sends Firebase reset email → success state
- [ ] Add profile / settings screen: display name, email, theme toggle, sign-out, privacy policy link, terms link
- [ ] Revamp the Get Started / splash screens with MuseAI-specific copy and illustrations — remove all generic streaming app imagery
- [ ] Add in-app Privacy Policy and Terms of Service screens (can be WebView pointing to hosted pages)
- [ ] Add account deletion flow (required by App Store and Play Store policies)

### Backend tasks

- [X] Implement password reset link generation endpoint
- [X] Implement profile bootstrap endpoint for authenticated users
- [X] Implement account deletion endpoint: delete `generations/{uid}/**`, `playlists/{uid}/**`, generated assets, and the Auth user
- [ ] Enable Google sign-in in Firebase Authentication console
- [ ] Enable Apple sign-in in Firebase Authentication console
- [ ] Configure Apple Sign-In service ID in Firebase (requires Apple Developer account)
- [ ] Confirm user bootstrap flow works for email, Google, and Apple sign-ins

### Exit criteria

- [ ] New users can sign up with email, Google, or Apple
- [ ] Existing users can sign in with any of the three methods
- [ ] Password reset email is sent and received successfully
- [ ] Account deletion removes all user data from Firestore and Storage within 60 seconds
- [ ] First-run users see MuseAI-branded onboarding — no references to Spotify or generic streaming

---

## Milestone 5 — Performance, Polish, and Accessibility (2 weeks)

**Goal:** The app feels fast, looks intentional, and is usable by people with disabilities. Addresses all non-functional requirements.

### Flutter tasks

- [ ] Add `shimmer` loading skeletons to Library and Discover screens (replace plain spinners)
- [ ] Add `hive` or `isar` local cache for Library metadata — tracks load instantly on reopen, then sync from Firestore
- [ ] Implement offline state detection and show a banner when the device is offline
- [ ] Audit all `Semantics` labels on interactive elements for screen reader support
- [ ] Ensure all tap targets are at least 48×48 dp
- [ ] Verify colour contrast ratio meets WCAG AA (4.5:1) for all text — update `app_colors.dart` as needed
- [ ] Apply consistent theming: update `app_theme.dart` with MuseAI-specific colours, chip styles, and player chrome
- [ ] Audit and fix all `TODO` and `FIXME` comments in the codebase
- [ ] Fix typo in `auth_firebase_service_impl.dart`: `"Not user found"` → `"No user found"`
- [ ] Add `flutter_test` unit tests for all use cases
- [ ] Add widget tests for Studio, Library, and Player pages

### Backend tasks

- [ ] Add Firestore indexes for all collection queries used by the app (verify no missing index warnings in logs)
- [ ] Add API/service layer tests for FastAPI routes, generation pipeline transitions, and failure paths
- [ ] Review and tighten Firestore and Storage security rules — run the Firebase Security Rules unit test suite where relevant
- [ ] Add request logging, generation latency metrics, and error monitoring for the FastAPI service
- [ ] Add abuse protection for public API traffic (rate limiting, proxy rules, or App Check-compatible validation strategy)
- [ ] Set up backend error alerting and latency monitoring in the hosting platform / Google Cloud Monitoring

### Exit criteria

- [ ] Library page renders in under 1 second on a warm start (local cache hit)
- [ ] All UI elements pass WCAG AA contrast check
- [ ] Screen reader can navigate all primary flows without unlabelled elements
- [ ] `flutter test` passes with > 70% code coverage on domain and data layers
- [ ] Zero Firebase security rules test failures
- [ ] Backend generation error rate < 1% over 48-hour period in staging

---

## Milestone 6 — Pre-Launch Hardening (1 week)

**Goal:** The app is ready for submission to the App Store and Play Store.

### Flutter tasks

- [ ] Update `pubspec.yaml` version to `1.0.0+1` and ensure build number increments correctly in CI
- [ ] Add `app_icon` for all required sizes (iOS and Android) — no placeholder icons
- [ ] Add `splash_screen` matching brand colours
- [ ] Configure Android `build.gradle` with correct `applicationId` (`com.museai.app` or similar)
- [ ] Configure iOS `Info.plist` with correct bundle ID, usage descriptions for microphone (if any), and media library
- [ ] Test on minimum supported OS versions: Android 9 (API 28) and iOS 15
- [ ] Perform a full regression test of all milestone features on a physical device
- [ ] Enable ProGuard / R8 obfuscation for Android release build

### Backend tasks

- [ ] Deploy FastAPI service to the chosen hosting platform (for example Cloud Run, Render, Railway, or Fly.io)
- [ ] Ensure Firebase project/billing supports outbound AI provider calls and storage traffic
- [ ] Set Firebase budget alert at a defined monthly spend limit
- [ ] Set backend concurrency / instance limits to cap AI API spend
- [ ] Review all secret values are stored securely — no plaintext secrets in committed config files
- [ ] Finalise auth hardening for production clients
- [ ] Perform a load test: simulate 50 concurrent generation requests and confirm all complete successfully

### Exit criteria

- [ ] App passes Android `bundle tool` validation and Google Play pre-launch report with no crashes
- [ ] App passes Xcode archive and TestFlight upload with no provisioning or entitlement errors
- [ ] Privacy Policy and Terms of Service URLs resolve and load correctly in-app
- [ ] All third-party licences are declared in the app's About / Legal screen
- [ ] AI music API terms of service permit royalty-free commercial use of generated tracks (confirm in writing)

---

## Milestone 7 — Social Feed (Post-Launch v1.1)

**Goal:** Users can share generated tracks to an in-app public feed and discover tracks made by others.

This milestone is deferred to after initial launch. Scope TBD based on user feedback.

High-level scope:

- Public `feed` Firestore collection with user-shared posts
- Feed page with infinite scroll
- Like / comment on posts
- Follow other users
- Notifications via Firebase Cloud Messaging (FCM)

---

## Summary Timeline

| Milestone                               | Duration            | Owner             |
| --------------------------------------- | ------------------- | ----------------- |
| 0 — Codebase Health                    | 1 week              | Flutter + Backend |
| 1 — AI Generation Core                 | 3 weeks             | Flutter + Backend |
| 2 — Library and Playlists              | 2 weeks             | Flutter + Backend |
| 3 — Remix, Export, Sharing             | 2 weeks             | Flutter           |
| 4 — Auth Completion and Onboarding     | 1 week              | Flutter + Backend |
| 5 — Performance, Polish, Accessibility | 2 weeks             | Flutter + Backend |
| 6 — Pre-Launch Hardening               | 1 week              | Flutter + Backend |
| **Total to launch**               | **~12 weeks** |                   |
| 7 — Social Feed (v1.1)                 | Post-launch         | Flutter + Backend |

---

## Definition of "Production Grade"

An application is considered production grade when it meets all of the following:

- **Functional:** All Milestone 1–4 exit criteria pass
- **Reliable:** Backend generation error rate < 1%; app crash-free rate > 99.5% (measured in Firebase Crashlytics)
- **Performant:** P95 generation latency < 90 seconds; UI response < 2 seconds for all screen loads
- **Secure:** All data access enforced by Firestore/Storage security rules; App Check enabled; no plaintext secrets in any codebase
- **Accessible:** WCAG AA contrast compliance; all interactive elements labelled for screen readers
- **Compliant:** Privacy Policy and Terms of Service published; account deletion available; GDPR-compliant data handling; AI API royalty-free usage confirmed
- **Submittable:** App Store and Play Store listing complete; passes review guidelines for both stores
