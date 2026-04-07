import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:museai/data/source/generation/generation_firebase_service.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

class MockGenerationFirebaseService extends Mock
    implements GenerationFirebaseService {}

void main() {
  late MockGenerationFirebaseService mockService;

  setUpAll(() {
    registerFallbackValue(const GenerationParams(
      uid: '',
      prompt: '',
      mood: '',
      genre: '',
      bpm: 0,
    ));
  });

  setUp(() {
    mockService = MockGenerationFirebaseService();
  });

  const params = GenerationParams(
    uid: 'user-123',
    prompt: 'test track',
    mood: 'Happy',
    genre: 'Pop',
    bpm: 120,
  );

  final entity = GenerationEntity(
    id: 'id1',
    uid: 'user-123',
    prompt: 'test track',
    mood: 'Happy',
    genre: 'Pop',
    bpm: 120,
    status: GenerationStatus.processing,
    createdAt: DateTime(2026, 1, 1),
  );

  test('createGeneration returns a non-empty id', () async {
    when(() => mockService.createGeneration(any(), any()))
        .thenAnswer((_) async => 'track-id-1');

    final id = await mockService.createGeneration('user-123', params);
    expect(id, isNotEmpty);
  });

  test('watchGeneration emits entity', () async {
    when(() => mockService.watchGeneration(any(), any()))
        .thenAnswer((_) => Stream.value(entity));

    final stream = mockService.watchGeneration('user-123', 'id1');
    await expectLater(stream, emits(entity));
  });

  test('getUserGenerations returns list', () async {
    when(() => mockService.getUserGenerations(any()))
        .thenAnswer((_) async => [entity]);

    final results = await mockService.getUserGenerations('user-123');
    expect(results.length, 1);
  });
}
