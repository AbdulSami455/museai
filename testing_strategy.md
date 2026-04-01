# MuseAI — Testing Strategy

> **Audience:** Flutter team and backend developer.
> **Last updated:** 2026-03-29
> **Companion document:** `milestones.md`

---

## 1. Philosophy and Testing Pyramid

```
         ┌─────────────────┐
         │    E2E Tests     │  ← Few. Full user flows on a real device.
         ├─────────────────┤
         │ Integration Tests│  ← Some. Firebase emulator, Cloud Function pipeline.
         ├─────────────────┤
         │   Widget Tests   │  ← Many. Page rendering, Cubit state → UI.
         ├─────────────────┤
         │   Unit Tests     │  ← Most. Use cases, repos, cubits, mappers.
         └─────────────────┘
```

**Guiding rules:**

- Test behaviour, not implementation. Test what a function returns given inputs — not which private methods it calls.
- Every use case gets a unit test. Every Cubit gets unit tests for each state transition. Every Firebase service gets an integration test against the emulator.
- Widget tests cover the happy path and the two most common error states for each page.
- E2E tests cover only the three most critical user journeys: sign-up → generate → play, sign-in returning user, and export/download.
- Do not test framework code (Flutter widgets themselves, Firebase SDK internals, `just_audio` internals).

**Coverage targets:**

| Layer | Target |
|-------|--------|
| Domain (use cases, entities) | 90% |
| Data (repositories, services) | 80% |
| Presentation (Cubits) | 80% |
| Presentation (Pages/Widgets) | Key flows only |
| Cloud Functions (Python) | 85% |

---

## 2. Tooling

### Flutter

| Tool | Purpose |
|------|---------|
| `flutter_test` (built-in) | Unit and widget tests |
| `bloc_test` | Cubit state sequence testing |
| `mocktail` | Mocking dependencies (no `sl<>` in tests) |
| `fake_cloud_firestore` | In-memory Firestore for repository tests |
| `firebase_auth_mocks` | Mock Firebase Auth for auth service tests |
| `integration_test` (built-in) | E2E tests on real device or emulator |

Install:
```yaml
# pubspec.yaml dev_dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  fake_cloud_firestore: ^2.4.0
  firebase_auth_mocks: ^0.13.0
  integration_test:
    sdk: flutter
```

### Backend (Python)

| Tool | Purpose |
|------|---------|
| `pytest` | Unit and integration tests |
| `pytest-mock` | Mocking the AI API client |
| `firebase-admin` + emulator | Integration tests against local Firestore/Storage |
| `responses` library | HTTP mock for AI API calls in unit tests |

Install:
```bash
pip install pytest pytest-mock responses
```

### Running tests

```bash
# Flutter — all unit and widget tests
cd museai && flutter test

# Flutter — specific file
flutter test test/domain/usecases/auth/signin_usecase_test.dart

# Flutter — E2E on connected device
flutter test integration_test/

# Backend — all Python tests
cd backend/functions && pytest tests/

# Backend — with coverage report
pytest tests/ --cov=. --cov-report=term-missing
```

---

## 3. Test File Structure

### Flutter

```
museai/test/
├── domain/
│   └── usecases/
│       ├── auth/
│       │   ├── signin_usecase_test.dart
│       │   └── signup_usecase_test.dart
│       ├── song/
│       │   └── get_news_song_test.dart
│       └── generation/
│           ├── create_generation_usecase_test.dart
│           └── watch_generation_usecase_test.dart
├── data/
│   ├── repository/
│   │   ├── auth_repository_impl_test.dart
│   │   ├── song_repository_impl_test.dart
│   │   └── generation_repository_impl_test.dart
│   └── source/
│       ├── auth_firebase_service_test.dart
│       └── generation_firebase_service_test.dart
├── presentation/
│   ├── auth/
│   │   └── auth_cubit_test.dart
│   ├── studio/
│   │   └── studio_cubit_test.dart
│   ├── home/
│   │   └── news_song_cubit_test.dart
│   └── song_player/
│       └── song_player_cubit_test.dart
└── widgets/
    ├── studio_page_test.dart
    ├── library_page_test.dart
    └── song_player_page_test.dart

museai/integration_test/
├── auth_flow_test.dart
├── generation_flow_test.dart
└── export_flow_test.dart
```

### Backend

```
backend/functions/tests/
├── unit/
│   ├── test_param_mapper.py
│   ├── test_ai_client.py
│   └── test_storage_uploader.py
└── integration/
    ├── test_orchestrator.py
    └── test_generation_trigger.py
```

---

## 4. Milestone 0 — Codebase Health

### Goal of testing in this milestone
Confirm that refactoring tasks (package rename, DI fix, typed errors, auth state listener) do not break existing behaviour. Every existing flow must still work after the changes.

---

### Task: Rename package `spotify_clone` → `museai`

**Type:** Smoke test (manual)

**What to test:** After the rename, `flutter pub get` and `flutter run` succeed. All screens load without `Package not found` errors.

**How:**
```bash
flutter clean && flutter pub get && flutter run
```

**Pass criteria:** App starts, splash screen appears, no red-screen error about missing packages.

---

### Task: Switch to constructor injection in use cases and repositories

**Type:** Unit test

**What to test:** Use cases can be instantiated with a mock repository and call through to it correctly. No `GetIt` context required.

**Example test — `signin_usecase_test.dart`:**
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:museai/domain/repository/auth/auth_repository.dart';
import 'package:museai/domain/usecases/auth/signin_usecase.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late SignInUsecase usecase;

  setUp(() {
    mockRepo = MockAuthRepository();
    usecase = SignInUsecase(mockRepo); // constructor injection
  });

  test('returns Right on successful sign-in', () async {
    final user = UserEntity(email: 'a@b.com', password: 'pass123');
    when(() => mockRepo.signIn(user))
        .thenAnswer((_) async => const Right('Signin was Successful'));

    final result = await usecase.call(params: user);
    expect(result.isRight(), true);
    verify(() => mockRepo.signIn(user)).called(1);
  });

  test('returns Left with AuthFailure on invalid credentials', () async {
    final user = UserEntity(email: 'a@b.com', password: 'wrong');
    when(() => mockRepo.signIn(user))
        .thenAnswer((_) async => Left(AuthFailure.invalidCredentials));

    final result = await usecase.call(params: user);
    expect(result.isLeft(), true);
  });
}
```

**Pass criteria:** Tests pass without `GetIt` being initialised.

---

### Task: Replace `Either<String, dynamic>` with typed `Failure` classes

**Type:** Unit test

**What to test:** Each failure path returns the correct typed `Failure` subclass, not a raw string.

**Example test:**
```dart
test('signIn returns AuthFailure.invalidCredentials for wrong password', () async {
  // arrange: mock throws FirebaseAuthException with 'invalid-credential'
  when(() => mockAuthService.signIn(any()))
      .thenAnswer((_) async => Left(AuthFailure.invalidCredentials));

  final result = await authRepo.signIn(testUser);

  result.fold(
    (failure) => expect(failure, isA<AuthFailure>()),
    (_) => fail('Expected Left but got Right'),
  );
});
```

**Pass criteria:** `failure` is always a typed class, never a `String`.

---

### Task: Add `authStateChanges()` listener in SplashPage

**Type:** Widget test

**What to test:** When Firebase Auth emits a logged-in user, the SplashPage navigates to HomePage. When it emits `null`, it navigates to AuthPage.

**Example test:**
```dart
testWidgets('navigates to HomePage when user is already signed in', (tester) async {
  final mockAuth = MockFirebaseAuth(signedIn: true);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
      child: const MaterialApp(home: SplashPage()),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(HomePage), findsOneWidget);
});

testWidgets('navigates to AuthPage when no user is signed in', (tester) async {
  final mockAuth = MockFirebaseAuth(signedIn: false);
  await tester.pumpWidget(/* ... */);
  await tester.pumpAndSettle();
  expect(find.byType(AuthPage), findsOneWidget);
});
```

---

### Task: Register `SongPlayerCubit` in `service_locator.dart`

**Type:** Unit test

**What to test:** `sl<SongPlayerCubit>()` returns the same instance on repeated calls (lazy singleton). No second `AudioPlayer` instance is created.

```dart
test('SongPlayerCubit is registered as lazy singleton', () {
  final instance1 = sl<SongPlayerCubit>();
  final instance2 = sl<SongPlayerCubit>();
  expect(identical(instance1, instance2), true);
});
```

---

### Task: Remove silent placeholder fallback in `SongFirebaseServiceImpl`

**Type:** Unit test

**What to test:** On Firestore error, the service returns `Left(NetworkFailure)` — not `Right(PlaceholderSongs.items)`.

```dart
test('returns Left on Firestore exception, not placeholder data', () async {
  when(() => mockFirestore.collection(any())).thenThrow(Exception('network error'));

  final result = await songService.getNewsSongs();

  expect(result.isLeft(), true);
  result.fold(
    (failure) => expect(failure, isA<NetworkFailure>()),
    (_) => fail('Should not return Right on exception'),
  );
});
```

---

### Milestone 0 — Exit Criteria Tests

| Check | How to verify |
|-------|--------------|
| `flutter analyze` zero warnings | `flutter analyze` in CI |
| App starts on Android and iOS | Manual smoke test + CI `flutter build apk` |
| Sign-up works end-to-end | Widget test against Firebase emulator |
| Sign-in works end-to-end | Widget test against Firebase emulator |
| Returning user bypasses auth | Widget test with `MockFirebaseAuth(signedIn: true)` |
| All imports use `package:museai/` | `grep -r "spotify_clone" lib/` returns empty |

---

## 5. Milestone 1 — AI Generation Core

### Goal of testing
Verify the complete path from the Flutter app writing a "pending" doc all the way to a playable `audioUrl` appearing in Firestore. This is the most complex and highest-risk milestone.

---

### Flutter tasks

#### Task: `GenerationEntity` and `GenerationModel`

**Type:** Unit test

**What to test:** `GenerationModel.fromSnapshot()` correctly deserialises all fields including nullable ones. Handles missing optional fields without throwing.

```dart
test('fromSnapshot maps all fields correctly', () {
  final fakeSnap = FakeDocumentSnapshot({
    'status': 'completed',
    'prompt': 'lo-fi beat',
    'mood': 'calm',
    'genre': 'lo-fi',
    'bpm': 75,
    'instruments': ['piano'],
    'durationSeconds': 30,
    'audioUrl': 'https://storage.example.com/audio.mp3',
    'coverUrl': 'https://storage.example.com/cover.jpg',
    'errorMessage': null,
    'parentId': null,
    'createdAt': Timestamp.now(),
    'completedAt': Timestamp.now(),
  });

  final model = GenerationModel.fromSnapshot(fakeSnap);
  expect(model.status, 'completed');
  expect(model.audioUrl, 'https://storage.example.com/audio.mp3');
  expect(model.parentId, isNull);
});

test('fromSnapshot does not throw when optional fields are absent', () {
  final fakeSnap = FakeDocumentSnapshot({
    'status': 'pending',
    'prompt': 'test',
    'createdAt': Timestamp.now(),
  });
  expect(() => GenerationModel.fromSnapshot(fakeSnap), returnsNormally);
});
```

---

#### Task: `GenerationRepositoryImpl` and `GenerationFirebaseServiceImpl`

**Type:** Integration test (against `fake_cloud_firestore`)

**What to test:** `createGeneration()` writes the correct document structure. `watchGeneration()` emits updated entities when the Firestore doc changes.

```dart
test('createGeneration writes pending doc to correct Firestore path', () async {
  final fakeFirestore = FakeFirebaseFirestore();
  final service = GenerationFirebaseServiceImpl(firestore: fakeFirestore);

  await service.createGeneration(uid: 'user1', entity: testGeneration);

  final snap = await fakeFirestore
      .collection('generations').doc('user1')
      .collection('tracks').doc(testGeneration.id)
      .get();

  expect(snap.exists, true);
  expect(snap.data()?['status'], 'pending');
});

test('watchGeneration stream emits when status changes', () async {
  final fakeFirestore = FakeFirebaseFirestore();
  // ... set up doc, listen to stream, update doc, verify emission
});
```

---

#### Task: `StudioCubit` state transitions

**Type:** Unit test using `bloc_test`

**What to test:** Every state transition: `StudioIdle → StudioSubmitting → StudioProcessing → StudioCompleted` and the failure path `StudioSubmitting → StudioFailed`.

```dart
blocTest<StudioCubit, StudioState>(
  'emits [Submitting, Processing] when generation is created and pending',
  build: () {
    when(() => mockCreateUsecase.call(params: any(named: 'params')))
        .thenAnswer((_) async => Right(testGeneration));
    when(() => mockWatchUsecase.call(params: any(named: 'params')))
        .thenAnswer((_) => Stream.value(Right(processingGeneration)));
    return StudioCubit(mockCreateUsecase, mockWatchUsecase);
  },
  act: (cubit) => cubit.submitGeneration(testParams),
  expect: () => [
    isA<StudioSubmitting>(),
    isA<StudioProcessing>(),
  ],
);

blocTest<StudioCubit, StudioState>(
  'emits [Submitting, Failed] when createGeneration returns Left',
  build: () {
    when(() => mockCreateUsecase.call(params: any(named: 'params')))
        .thenAnswer((_) async => Left(NetworkFailure()));
    return StudioCubit(mockCreateUsecase, mockWatchUsecase);
  },
  act: (cubit) => cubit.submitGeneration(testParams),
  expect: () => [isA<StudioSubmitting>(), isA<StudioFailed>()],
);

blocTest<StudioCubit, StudioState>(
  'emits Completed when Firestore doc transitions to completed',
  // ... stream emits completed entity
);
```

---

#### Task: Studio page widget

**Type:** Widget test

**What to test:** Generate button is disabled when required fields are empty. Spinner shows during `StudioProcessing`. Error banner shows during `StudioFailed` with retry button.

```dart
testWidgets('Generate button is disabled with no prompt', (tester) async {
  await tester.pumpWidget(buildStudioPage(state: StudioIdle()));
  final button = tester.widget<ElevatedButton>(find.text('Generate'));
  expect(button.onPressed, isNull);
});

testWidgets('shows spinner when in StudioProcessing state', (tester) async {
  await tester.pumpWidget(buildStudioPage(state: StudioProcessing()));
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('shows error with retry button when in StudioFailed state', (tester) async {
  await tester.pumpWidget(buildStudioPage(state: StudioFailed('An unexpected error occurred. Please try again.')));
  expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);
});
```

---

#### Task: `SongPlayerCubit.loadSong()` accepts `GenerationEntity`

**Type:** Unit test

**What to test:** `loadSong` works when given a `GenerationEntity` with a valid `audioUrl`. Emits `SongPlayerLoaded`. Emits `SongPlayerFailure` for an invalid URL.

```dart
test('loadSong emits SongPlayerLoaded for completed generation', () async {
  final cubit = SongPlayerCubit(mockAudioPlayer: mockPlayer);
  when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
  when(() => mockPlayer.play()).thenAnswer((_) async {});

  await cubit.loadSong(completedGeneration);

  expect(cubit.state, isA<SongPlayerLoaded>());
});

test('loadSong emits SongPlayerFailure when audioUrl is null', () async {
  final cubit = SongPlayerCubit(mockAudioPlayer: mockPlayer);
  await cubit.loadSong(pendingGeneration); // no audioUrl yet
  expect(cubit.state, isA<SongPlayerFailure>());
});
```

---

### Backend tasks

#### Task: `param_mapper.py`

**Type:** Unit test

**What to test:** All known mood/genre combinations produce non-empty `style` strings. BPM and duration pass through unchanged. Unknown mood/genre values do not throw — they produce a graceful fallback.

```python
# tests/unit/test_param_mapper.py
from functions.param_mapper import map_to_api_params

def test_calm_lofi_maps_correctly():
    result = map_to_api_params(
        mood="calm", genre="lo-fi", bpm=75,
        instruments=["piano"], duration_seconds=30, prompt=""
    )
    assert result["bpm"] == 75
    assert result["duration"] == 30
    assert "lo-fi" in result["style"]
    assert "ambient" in result["style"]
    assert result["make_instrumental"] is True

def test_prompt_overrides_default():
    result = map_to_api_params(
        mood="calm", genre="lo-fi", bpm=75,
        instruments=[], duration_seconds=30,
        prompt="rainy day coffee shop"
    )
    assert result["prompt"] == "rainy day coffee shop"

def test_unknown_mood_does_not_raise():
    result = map_to_api_params(
        mood="undefined_mood", genre="pop", bpm=120,
        instruments=[], duration_seconds=30, prompt=""
    )
    assert isinstance(result, dict)

def test_instruments_included_in_style():
    result = map_to_api_params(
        mood="happy", genre="pop", bpm=120,
        instruments=["guitar", "drums"], duration_seconds=30, prompt=""
    )
    assert "guitar" in result["style"]
    assert "drums" in result["style"]
```

---

#### Task: `ai_client.py`

**Type:** Unit test (HTTP mocked with `responses` library)

**What to test:** Successful API call returns `(audio_bytes, cover_bytes)`. API error (4xx/5xx) raises `GenerationError`. Polling timeout (job never completes) raises `GenerationError`. Retry decorator fires on transient errors.

```python
# tests/unit/test_ai_client.py
import responses as resp_mock
import pytest
from functions.ai_client import generate_track, GenerationError

@resp_mock.activate
def test_successful_generation():
    # Mock job submission
    resp_mock.add(resp_mock.POST, "https://api.example-ai-music.com/v1/generate",
                  json={"id": "job-123"}, status=200)
    # Mock status poll — immediately complete
    resp_mock.add(resp_mock.GET, "https://api.example-ai-music.com/v1/jobs/job-123",
                  json={"status": "complete",
                        "audio_url": "https://cdn.example.com/audio.mp3",
                        "image_url": "https://cdn.example.com/cover.jpg"}, status=200)
    resp_mock.add(resp_mock.GET, "https://cdn.example.com/audio.mp3",
                  body=b"audio_data", status=200)
    resp_mock.add(resp_mock.GET, "https://cdn.example.com/cover.jpg",
                  body=b"image_data", status=200)

    audio, cover = generate_track({"prompt": "test", "bpm": 80})
    assert audio == b"audio_data"
    assert cover == b"image_data"

@resp_mock.activate
def test_api_error_raises_generation_error():
    resp_mock.add(resp_mock.POST, "https://api.example-ai-music.com/v1/generate",
                  status=429, body="rate limit exceeded")
    with pytest.raises(GenerationError, match="API error 429"):
        generate_track({"prompt": "test"})

@resp_mock.activate
def test_job_failure_raises_generation_error():
    resp_mock.add(resp_mock.POST, "https://api.example-ai-music.com/v1/generate",
                  json={"id": "job-fail"}, status=200)
    resp_mock.add(resp_mock.GET, "https://api.example-ai-music.com/v1/jobs/job-fail",
                  json={"status": "failed", "error": "content_policy_violation"}, status=200)
    with pytest.raises(GenerationError, match="content_policy_violation"):
        generate_track({"prompt": "test"})
```

---

#### Task: `orchestrator.py` — full pipeline

**Type:** Integration test (Firebase emulator)

**What to test:** Given a "pending" Firestore doc, `run_generation_pipeline()` updates the doc through `processing` and then `completed`. On `GenerationError`, doc ends in `failed` with `errorMessage` set.

```python
# tests/integration/test_orchestrator.py
import os
import pytest
from unittest.mock import patch
import firebase_admin
from firebase_admin import firestore

os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"

@pytest.fixture(autouse=True)
def setup_firebase():
    if not firebase_admin._apps:
        firebase_admin.initialize_app(options={"projectId": "test-project"})
    yield
    # clean up test docs after each test

def _track_ref(uid, tid):
    db = firestore.client()
    return db.collection("generations").document(uid).collection("tracks").document(tid)

def test_pipeline_sets_completed_on_success():
    ref = _track_ref("user1", "track1")
    ref.set({"status": "pending", "prompt": "test", "mood": "calm",
             "genre": "lo-fi", "bpm": 75, "instruments": [], "durationSeconds": 30})

    with patch("functions.orchestrator.generate_track",
               return_value=(b"audio", b"cover")), \
         patch("functions.orchestrator.upload_audio",
               return_value="https://storage.example.com/audio.mp3"), \
         patch("functions.orchestrator.upload_cover",
               return_value="https://storage.example.com/cover.jpg"):
        from functions.orchestrator import run_generation_pipeline
        run_generation_pipeline("user1", "track1", ref.get().to_dict())

    result = ref.get().to_dict()
    assert result["status"] == "completed"
    assert result["audioUrl"] == "https://storage.example.com/audio.mp3"
    assert result["errorMessage"] is None

def test_pipeline_sets_failed_on_generation_error():
    from functions.ai_client import GenerationError
    ref = _track_ref("user1", "track2")
    ref.set({"status": "pending", "prompt": "test", "mood": "calm",
             "genre": "lo-fi", "bpm": 75, "instruments": [], "durationSeconds": 30})

    with patch("functions.orchestrator.generate_track",
               side_effect=GenerationError("API error 429")):
        from functions.orchestrator import run_generation_pipeline
        run_generation_pipeline("user1", "track2", ref.get().to_dict())

    result = ref.get().to_dict()
    assert result["status"] == "failed"
    assert "API error 429" in result["errorMessage"]

def test_pipeline_transitions_through_processing():
    """Status must be 'processing' before the AI call completes."""
    statuses_seen = []
    ref = _track_ref("user1", "track3")
    ref.set({"status": "pending", "prompt": "test", "mood": "calm",
             "genre": "lo-fi", "bpm": 75, "instruments": [], "durationSeconds": 30})

    original_generate = __import__("functions.ai_client", fromlist=["generate_track"]).generate_track

    def capturing_generate(params):
        statuses_seen.append(ref.get().to_dict()["status"])
        return original_generate(params)

    with patch("functions.orchestrator.generate_track", side_effect=capturing_generate), \
         patch("functions.orchestrator.upload_audio", return_value="https://x.com/a.mp3"), \
         patch("functions.orchestrator.upload_cover", return_value="https://x.com/c.jpg"):
        from functions.orchestrator import run_generation_pipeline
        run_generation_pipeline("user1", "track3", ref.get().to_dict())

    assert "processing" in statuses_seen
```

---

#### Task: Security rules for `generations` subcollection

**Type:** Firebase Security Rules unit tests

**What to test:** User can `create` with `status: "pending"`. User cannot `update` or `delete`. User cannot read another user's tracks.

```javascript
// firestore.rules.test.js — run with firebase emulators:exec
const { assertSucceeds, assertFails, initializeTestEnvironment } = require('@firebase/rules-unit-testing');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({ projectId: 'test-project', firestore: { rules } });
});

test('user can create generation with status pending', async () => {
  const db = testEnv.authenticatedContext('user1').firestore();
  await assertSucceeds(
    db.collection('generations').doc('user1')
      .collection('tracks').doc('t1')
      .set({ status: 'pending', prompt: 'test', createdAt: new Date() })
  );
});

test('user cannot create generation with status processing', async () => {
  const db = testEnv.authenticatedContext('user1').firestore();
  await assertFails(
    db.collection('generations').doc('user1')
      .collection('tracks').doc('t2')
      .set({ status: 'processing' })
  );
});

test('user cannot update their own generation (only functions can)', async () => {
  const db = testEnv.authenticatedContext('user1').firestore();
  await assertFails(
    db.collection('generations').doc('user1')
      .collection('tracks').doc('t1')
      .update({ status: 'completed' })
  );
});

test('user cannot read another user\'s generations', async () => {
  const db = testEnv.authenticatedContext('user2').firestore();
  await assertFails(
    db.collection('generations').doc('user1')
      .collection('tracks').doc('t1')
      .get()
  );
});
```

---

### Milestone 1 — Exit Criteria Tests

| Check | Test type | How |
|-------|-----------|-----|
| Generation doc created with `status: pending` | Integration | `fake_cloud_firestore` write + read |
| Cloud Function fires within 5 seconds of doc creation | E2E | Firebase emulator + `test_trigger.py` |
| `status` transitions: pending → processing → completed | Integration | `test_orchestrator.py` |
| `audioUrl` is a valid HTTPS URL | Integration | `assert audioUrl.startswith("https://")` |
| `just_audio` loads the URL without error | E2E | Flutter integration test on device |
| UI shows spinner during processing | Widget test | `StudioProcessing` state → `CircularProgressIndicator` |
| UI shows error + retry on failure | Widget test | `StudioFailed` state → error text + retry button |
| Generation completes in under 90 seconds | E2E | Timed integration test |
| User cannot read another user's tracks | Security rules test | `assertFails` |

---

## 6. Milestone 2 — Library and Playlists

### Task: `GetUserGenerationsUsecase`

**Type:** Unit test

**What to test:** Returns a stream of `GenerationEntity` list ordered by `createdAt` descending. Returns empty list (not error) when collection is empty.

```dart
test('returns stream of generations sorted by createdAt descending', () async {
  final entities = [newerGeneration, olderGeneration];
  when(() => mockRepo.getUserGenerations(uid: 'u1'))
      .thenAnswer((_) => Stream.value(Right(entities)));

  final stream = usecase.call(params: 'u1');
  await expectLater(stream, emits(Right<Failure, List<GenerationEntity>>(entities)));
});

test('returns empty list when user has no generations', () async {
  when(() => mockRepo.getUserGenerations(uid: 'u1'))
      .thenAnswer((_) => Stream.value(const Right([])));

  final stream = usecase.call(params: 'u1');
  await expectLater(stream, emits(const Right<Failure, List<GenerationEntity>>([])));
});
```

---

### Task: My Library page

**Type:** Widget test

**What to test:** Track list renders when `LibraryLoaded` state. Empty state illustration shows when `LibraryEmpty` state. Error banner shows on `LibraryError`.

```dart
testWidgets('renders track list when LibraryLoaded', (tester) async {
  await tester.pumpWidget(buildLibraryPage(state: LibraryLoaded(tracks: [testTrack1, testTrack2])));
  expect(find.byType(TrackRowWidget), findsNWidgets(2));
});

testWidgets('shows empty state when LibraryEmpty', (tester) async {
  await tester.pumpWidget(buildLibraryPage(state: LibraryEmpty()));
  expect(find.text('No tracks yet'), findsOneWidget);
  expect(find.text('Create your first track'), findsOneWidget);
});

testWidgets('swipe to delete shows confirmation then removes track', (tester) async {
  await tester.pumpWidget(buildLibraryPage(state: LibraryLoaded(tracks: [testTrack1])));
  await tester.drag(find.byType(TrackRowWidget), const Offset(-300, 0));
  await tester.pumpAndSettle();
  expect(find.text('Delete'), findsOneWidget);
  await tester.tap(find.text('Delete'));
  verify(() => mockCubit.deleteTrack(testTrack1.id)).called(1);
});
```

---

### Task: Playlist CRUD — `PlaylistCubit`

**Type:** Unit test using `bloc_test`

**What to test:** Create, rename, delete, add track, remove track — each emits correct state sequence.

```dart
blocTest<PlaylistCubit, PlaylistState>(
  'emits PlaylistLoaded with new playlist after create',
  build: () {
    when(() => mockCreateUsecase.call(params: any(named: 'params')))
        .thenAnswer((_) async => Right(newPlaylist));
    return PlaylistCubit(mockCreateUsecase, mockDeleteUsecase, mockAddTrackUsecase);
  },
  act: (cubit) => cubit.createPlaylist(name: 'My Chill Mix'),
  expect: () => [isA<PlaylistCreating>(), isA<PlaylistLoaded>()],
);

blocTest<PlaylistCubit, PlaylistState>(
  'emits PlaylistError when delete fails',
  build: () {
    when(() => mockDeleteUsecase.call(params: any(named: 'params')))
        .thenAnswer((_) async => Left(NetworkFailure()));
    return PlaylistCubit(mockCreateUsecase, mockDeleteUsecase, mockAddTrackUsecase);
  },
  act: (cubit) => cubit.deletePlaylist('playlist-1'),
  expect: () => [isA<PlaylistDeleting>(), isA<PlaylistError>()],
);
```

---

### Task: Firestore indexes for `generations` queries

**Type:** Integration test

**What to test:** Query `generations/{uid}/tracks` ordered by `createdAt` descending does not throw a missing index error.

```python
def test_generations_query_ordered_by_created_at():
    db = firestore.client()
    # This will throw if the index is missing
    results = db.collection("generations").document("user1") \
                .collection("tracks") \
                .order_by("createdAt", direction=firestore.Query.DESCENDING) \
                .limit(20).get()
    assert isinstance(results, list)
```

---

### Milestone 2 — Exit Criteria Tests

| Check | Test type | How |
|-------|-----------|-----|
| Library shows tracks newest first | Widget test | `LibraryLoaded` with two tracks, verify order |
| Delete track removes from Firestore | Integration | Write doc, delete, verify `exists == false` |
| Playlist create/rename/delete works | Cubit unit test | `bloc_test` sequences |
| Add/remove track from playlist updates `trackIds` | Integration | `fake_cloud_firestore` verify array |
| Empty state shows for new users | Widget test | `LibraryEmpty` state renders illustration |
| Navigation between tabs has no stack issues | E2E | Integration test: tap tabs repeatedly, no crash |

---

## 7. Milestone 3 — Remix, Export, and Sharing

### Task: Remix creates new generation with `parentId`

**Type:** Integration test

**What to test:** When a user remixes track `track-abc`, the new generation doc has `parentId: "track-abc"` and all pre-filled params from the original.

```dart
test('remix creates new generation with parentId set', () async {
  final fakeFirestore = FakeFirebaseFirestore();
  final service = GenerationFirebaseServiceImpl(firestore: fakeFirestore);

  await service.createGeneration(
    uid: 'user1',
    entity: remixEntity.copyWith(parentId: 'track-abc'),
  );

  final docs = await fakeFirestore
      .collection('generations').doc('user1')
      .collection('tracks')
      .where('parentId', isEqualTo: 'track-abc')
      .get();

  expect(docs.docs.length, 1);
  expect(docs.docs.first.data()['parentId'], 'track-abc');
});
```

---

### Task: MP3 download saves valid file

**Type:** Integration test (device)

**What to test:** After tapping Download, a file named `audio.mp3` appears in the device's Downloads directory and is greater than 0 bytes.

```dart
testWidgets('download saves mp3 file to device', (tester) async {
  // This test requires a connected device or emulator
  await tester.pumpWidget(buildPlayerPage(generation: completedGeneration));
  await tester.tap(find.byIcon(Icons.download));
  await tester.pumpAndSettle();

  final dir = await getExternalStorageDirectory();
  final file = File('${dir!.path}/audio.mp3');
  expect(await file.exists(), true);
  expect(await file.length(), greaterThan(0));
});
```

---

### Task: `audioUrl` signed URLs are long-lived

**Type:** Unit test (backend)

**What to test:** The signed URL expiry passed to `generate_signed_url()` is at least 3650 days (10 years).

```python
def test_upload_audio_uses_long_lived_signed_url(mocker):
    mock_bucket = mocker.patch("functions.storage_uploader.storage.bucket")
    mock_blob = mocker.MagicMock()
    mock_bucket.return_value.blob.return_value = mock_blob
    mock_blob.generate_signed_url.return_value = "https://signed-url"

    from functions.storage_uploader import upload_audio
    upload_audio(b"audio_data", "generations/user1/track1")

    call_kwargs = mock_blob.generate_signed_url.call_args.kwargs
    assert call_kwargs["expiration"].days >= 3650
```

---

### Milestone 3 — Exit Criteria Tests

| Check | Test type | How |
|-------|-----------|-----|
| Remix doc has correct `parentId` | Integration | Firestore write + field assertion |
| Download saves valid `.mp3` on Android | Device integration test | File existence + size check |
| Download saves valid `.mp3` on iOS | Device integration test | Same on iOS simulator |
| Share sheet opens with audio attached | E2E (manual) | Tap Share, verify native sheet appears |
| Signed URLs do not expire within 10 years | Unit test | Expiry duration assertion |
| AI API TOS permit royalty-free export | Manual check | Review API terms document |

---

## 8. Milestone 4 — Auth Completion and Onboarding

### Task: Google Sign-In

**Type:** Widget test + integration test

**What to test:** Google sign-in button triggers the Google sign-in flow. On success, user is routed to HomePage. On cancellation, user stays on AuthPage.

```dart
testWidgets('Google sign-in button is present on auth page', (tester) async {
  await tester.pumpWidget(buildAuthPage());
  expect(find.text('Continue with Google'), findsOneWidget);
});

test('signInWithGoogle returns Right on success', () async {
  when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleAccount);
  // ...
  final result = await authService.signInWithGoogle();
  expect(result.isRight(), true);
});

test('signInWithGoogle returns Left when user cancels', () async {
  when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null); // user dismissed
  final result = await authService.signInWithGoogle();
  expect(result.isLeft(), true);
});
```

---

### Task: Account deletion Cloud Function

**Type:** Integration test (Firebase emulator)

**What to test:** After deletion, `users/{uid}` doc is gone, `generations/{uid}/**` docs are gone, `playlists/{uid}/**` docs are gone, and the Firebase Auth user is deleted.

```python
def test_account_deletion_removes_all_user_data():
    db = firestore.client()
    uid = "delete-test-user"

    # Seed test data
    db.collection("users").document(uid).set({"email": "test@test.com"})
    db.collection("generations").document(uid).collection("tracks").document("t1").set({"status": "completed"})
    db.collection("playlists").document(uid).collection("lists").document("p1").set({"name": "Test"})

    # Call deletion function
    from functions.main import delete_user_account
    delete_user_account(uid)

    assert not db.collection("users").document(uid).get().exists
    assert len(db.collection("generations").document(uid).collection("tracks").get()) == 0
    assert len(db.collection("playlists").document(uid).collection("lists").get()) == 0
```

---

### Task: Password reset flow

**Type:** Widget test

**What to test:** Entering an email and tapping "Send reset link" calls `sendPasswordResetEmail`. Success state shows confirmation message. Invalid email shows inline validation error.

```dart
testWidgets('shows confirmation after successful reset email', (tester) async {
  when(() => mockAuth.sendPasswordResetEmail(email: 'a@b.com'))
      .thenAnswer((_) async {});
  await tester.pumpWidget(buildPasswordResetPage());
  await tester.enterText(find.byType(TextField), 'a@b.com');
  await tester.tap(find.text('Send reset link'));
  await tester.pumpAndSettle();
  expect(find.text('Check your email'), findsOneWidget);
});

testWidgets('shows error for invalid email format', (tester) async {
  await tester.pumpWidget(buildPasswordResetPage());
  await tester.enterText(find.byType(TextField), 'not-an-email');
  await tester.tap(find.text('Send reset link'));
  await tester.pump();
  expect(find.text('Enter a valid email address'), findsOneWidget);
});
```

---

### Milestone 4 — Exit Criteria Tests

| Check | Test type | How |
|-------|-----------|-----|
| Google sign-in routes to HomePage | Widget test | Mock Google flow → `HomePage` found |
| Apple sign-in routes to HomePage | Widget test | Mock Apple flow → `HomePage` found |
| Password reset email is sent | Unit test | Verify `sendPasswordResetEmail` called |
| Account deletion removes all Firestore data | Integration | Emulator: seed → delete → assert no docs |
| Account deletion removes Auth user | Integration | Emulator: assert user no longer exists |
| Onboarding has no "Spotify" references | Static analysis | `grep -r "spotify" lib/` returns empty |

---

## 9. Milestone 5 — Performance, Polish, and Accessibility

### Task: Local cache (Hive) for Library metadata

**Type:** Unit test

**What to test:** On Library open, cached tracks are emitted immediately before Firestore responds. If Firestore returns newer data, the cache is updated.

```dart
test('emits cached data first, then updates from Firestore', () async {
  when(() => mockCache.getTracks()).thenReturn([cachedTrack]);
  when(() => mockRepo.getUserGenerations(uid: any(named: 'uid')))
      .thenAnswer((_) => Stream.fromFuture(
            Future.delayed(const Duration(milliseconds: 100), () => Right([fresherTrack]))
          ));

  final cubit = LibraryCubit(mockRepo, mockCache);
  await cubit.loadLibrary('user1');

  await expectLater(
    cubit.stream,
    emitsInOrder([
      LibraryLoaded(tracks: [cachedTrack]),   // from cache
      LibraryLoaded(tracks: [fresherTrack]),  // from Firestore
    ]),
  );
});
```

---

### Task: WCAG AA contrast compliance

**Type:** Automated accessibility test

**What to test:** Text-on-background colour combinations in `app_colors.dart` meet 4.5:1 contrast ratio.

```dart
test('primary text on background meets WCAG AA contrast', () {
  final textColor = AppColors.primaryText;       // e.g. Color(0xFF1A1A1A)
  final bgColor = AppColors.background;          // e.g. Color(0xFFFFFFFF)
  final ratio = contrastRatio(textColor, bgColor);
  expect(ratio, greaterThanOrEqualTo(4.5),
      reason: 'Text contrast ratio must be at least 4.5:1 for WCAG AA');
});

double contrastRatio(Color fg, Color bg) {
  final l1 = relativeLuminance(fg);
  final l2 = relativeLuminance(bg);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}
```

---

### Task: Semantics labels on interactive elements

**Type:** Widget test

**What to test:** Key interactive elements have `Semantics` labels readable by screen readers.

```dart
testWidgets('Generate button has semantic label', (tester) async {
  await tester.pumpWidget(buildStudioPage(state: StudioIdle()));
  final semantics = tester.getSemantics(find.text('Generate'));
  expect(semantics.label, isNotEmpty);
});

testWidgets('Track row has accessible label with title and duration', (tester) async {
  await tester.pumpWidget(buildTrackRow(track: testTrack));
  final semantics = tester.getSemantics(find.byType(TrackRowWidget));
  expect(semantics.label, contains(testTrack.prompt));
});
```

---

### Task: Firebase App Check enforcement

**Type:** Manual + security test

**What to test:** Firestore reads from a non-app client (e.g., `curl` with a valid Firebase Auth token but no App Check token) are rejected.

```bash
# Should return 403 after App Check enforcement is enabled
curl -X GET \
  "https://firestore.googleapis.com/v1/projects/{id}/databases/(default)/documents/users/test" \
  -H "Authorization: Bearer $FIREBASE_ID_TOKEN"
# Expected: 403 Forbidden
```

---

### Task: Cloud Function error alerting

**Type:** Alerting configuration check (manual)

**What to test:** In Google Cloud Monitoring, an alert policy exists that fires when `on_generation_created` error rate exceeds 5% over a 5-minute window. Verify by manually triggering a test error and confirming the alert fires.

---

### Milestone 5 — Exit Criteria Tests

| Check | Test type | How |
|-------|-----------|-----|
| Library renders in < 1s (cache hit) | Performance test | Measure time from cubit load to first emit |
| All text passes WCAG AA contrast (4.5:1) | Unit test | `contrastRatio()` assertion for each colour pair |
| Interactive elements have semantic labels | Widget test | `getSemantics()` assertions |
| `flutter test` coverage > 70% (domain + data) | Coverage report | `flutter test --coverage` |
| Zero security rules test failures | Rules unit test | `firebase emulators:exec --only firestore "npm test"` |
| Function error rate < 1% over 48 hours | Monitoring | Cloud Monitoring dashboard |

---

## 10. Milestone 6 — Pre-Launch Hardening

### Task: App builds without error for Android and iOS release

**Type:** CI build test

```bash
# Android release build
cd museai && flutter build apk --release
# Expected: exit code 0, APK file created

# iOS archive (requires macOS + Xcode)
flutter build ipa --release
# Expected: exit code 0, IPA file created
```

---

### Task: Test on minimum supported OS versions

**Type:** E2E on device/emulator

**What to test:** App installs and all Milestone 1 flows work on Android API 28 (Android 9) and iOS 15.

---

### Task: Load test — 50 concurrent generation requests

**Type:** Load test (backend)

**What to test:** 50 simultaneous "pending" docs are written to Firestore. All 50 complete within 10 minutes. No Cloud Function crashes. No AI API rate limit errors (if API supports the concurrency).

```python
# load_test.py
import concurrent.futures
from firebase_admin import firestore
import uuid

def write_generation(i):
    db = firestore.client()
    uid = f"load-test-user-{i}"
    tid = str(uuid.uuid4())
    db.collection("generations").document(uid).collection("tracks").document(tid).set({
        "status": "pending",
        "prompt": f"load test track {i}",
        "mood": "calm", "genre": "lo-fi", "bpm": 75,
        "instruments": [], "durationSeconds": 30,
        "createdAt": firestore.SERVER_TIMESTAMP,
    })
    return uid, tid

with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
    jobs = list(executor.map(write_generation, range(50)))

# Then poll all 50 docs until status != "pending" and assert all are "completed"
```

---

### Milestone 6 — Exit Criteria Tests

| Check | Test type | How |
|-------|-----------|-----|
| Android release build succeeds | CI | `flutter build apk --release` |
| iOS release archive succeeds | CI (macOS runner) | `flutter build ipa --release` |
| App works on Android 9 (API 28) | Device test | Manual regression on emulator |
| App works on iOS 15 | Device test | Manual regression on iOS 15 simulator |
| Privacy Policy URL loads in-app | E2E | Navigate to About → tap Privacy Policy → WebView loads |
| All 50 concurrent generations complete | Load test | `load_test.py` → all docs reach `completed` |
| No plaintext secrets in any config file | Security scan | `grep -r "AI_MUSIC_API_KEY" .` returns only `.env` and Secret Manager references |
| App Check in enforce mode | Manual | Non-app client `curl` returns 403 |

---

## 11. Continuous Integration Setup

Add this to your CI pipeline (GitHub Actions example):

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  flutter-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: cd museai && flutter pub get
      - run: cd museai && flutter analyze
      - run: cd museai && flutter test --coverage
      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep "lines" | grep -o '[0-9.]*%' | head -1 | tr -d '%')
          if (( $(echo "$COVERAGE < 70" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 70% threshold"
            exit 1
          fi

  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: cd backend/functions && pip install -r requirements.txt pytest pytest-mock responses
      - name: Start Firebase emulator and run tests
        run: |
          npm install -g firebase-tools
          firebase emulators:exec --only firestore \
            "cd backend/functions && pytest tests/ --cov=. --cov-fail-under=85"

  security-rules-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install -g firebase-tools
      - run: cd backend && firebase emulators:exec --only firestore "npm test"
```

---

## 12. Quick Reference — Test Commands

```bash
# Flutter — all tests
cd museai && flutter test

# Flutter — with coverage
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html

# Flutter — single file
flutter test test/domain/usecases/auth/signin_usecase_test.dart

# Flutter — E2E on device
flutter test integration_test/generation_flow_test.dart

# Backend — unit tests only
cd backend/functions && pytest tests/unit/

# Backend — integration tests (requires emulator running)
firebase emulators:start --only firestore,storage &
pytest tests/integration/

# Security rules tests
firebase emulators:exec --only firestore "npm test"

# Static analysis — check for leftover Spotify references
grep -r "spotify" museai/lib/ --include="*.dart"

# Static analysis — check for leftover spotify_clone package imports
grep -r "spotify_clone" museai/lib/ --include="*.dart"
```
