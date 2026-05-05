import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/repository/generation/generation_repository_impl.dart';
import 'package:museai/data/source/generation/generation_service.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

class MockGenerationService extends Mock implements GenerationService {}

class FakeGenerationParams extends Fake implements GenerationParams {}

void main() {
  late GenerationRepositoryImpl repository;
  late MockGenerationService mockService;

  setUpAll(() {
    registerFallbackValue(FakeGenerationParams());
  });

  setUp(() {
    mockService = MockGenerationService();
    repository = GenerationRepositoryImpl(mockService);
  });

  const params = GenerationParams(
    uid: 'uid1',
    prompt: 'test prompt',
    mood: 'Happy',
    genre: 'Pop',
    bpm: 120,
  );

  group('createGeneration', () {
    test('returns Right(id) on success', () async {
      when(() => mockService.createGeneration(any(), any()))
          .thenAnswer((_) async => 'track-id-1');

      final result = await repository.createGeneration(params);

      expect(result, const Right('track-id-1'));
    });

    test('returns Left(GenerationFailure) on exception', () async {
      when(() => mockService.createGeneration(any(), any()))
          .thenThrow(Exception('network error'));

      final result = await repository.createGeneration(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<GenerationFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('getUserGenerations', () {
    test('returns Right(list) on success', () async {
      when(() => mockService.getUserGenerations('uid1'))
          .thenAnswer((_) async => []);

      final result = await repository.getUserGenerations('uid1');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected Right'),
        (list) => expect(list, isEmpty),
      );
    });

    test('returns Left(GenerationFailure) on exception', () async {
      when(() => mockService.getUserGenerations('uid1'))
          .thenThrow(Exception('database error'));

      final result = await repository.getUserGenerations('uid1');

      expect(result.isLeft(), true);
    });
  });

  group('watchGeneration', () {
    test('emits Right(entity) for each stream event', () async {
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
      when(() => mockService.watchGeneration('uid1', 'id1'))
          .thenAnswer((_) => Stream.value(entity));

      final result = repository.watchGeneration('uid1', 'id1');

      await expectLater(result, emits(Right(entity)));
    });

    test('emits Left(GenerationFailure) when stream errors', () async {
      when(() => mockService.watchGeneration('uid1', 'id1'))
          .thenAnswer((_) => Stream.error(Exception('stream error')));

      final result = repository.watchGeneration('uid1', 'id1');

      await expectLater(
        result,
        emits(predicate<Either<Failure, GenerationEntity>>(
          (e) => e.isLeft(),
        )),
      );
    });
  });
}
