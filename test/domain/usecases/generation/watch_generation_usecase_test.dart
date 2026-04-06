import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';
import 'package:museai/domain/usecases/generation/watch_generation_usecase.dart';

class MockGenerationRepository extends Mock implements GenerationRepository {}

void main() {
  late WatchGenerationUsecase usecase;
  late MockGenerationRepository mockRepo;

  setUp(() {
    mockRepo = MockGenerationRepository();
    usecase = WatchGenerationUsecase(mockRepo);
  });

  test('emits Right(entity) from stream', () async {
    final entity = GenerationEntity(
      id: 'id1',
      uid: 'uid1',
      prompt: 'test',
      mood: 'Happy',
      genre: 'Pop',
      bpm: 120,
      status: GenerationStatus.processing,
      createdAt: DateTime(2026, 1, 1),
    );

    when(() => mockRepo.watchGeneration(any(), any()))
        .thenAnswer((_) => Stream.value(Right(entity)));

    const params = WatchGenerationParams(uid: 'uid1', generationId: 'id1');
    final stream = usecase(params);

    await expectLater(stream, emits(Right(entity)));
  });
}
