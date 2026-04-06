import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';
import 'package:museai/domain/usecases/generation/create_generation_usecase.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

class MockGenerationRepository extends Mock implements GenerationRepository {}

void main() {
  late CreateGenerationUsecase usecase;
  late MockGenerationRepository mockRepo;

  setUp(() {
    mockRepo = MockGenerationRepository();
    usecase = CreateGenerationUsecase(mockRepo);
  });

  const params = GenerationParams(
    uid: 'uid1',
    prompt: 'upbeat summer track',
    mood: 'Happy',
    genre: 'Pop',
    bpm: 128,
  );

  setUpAll(() {
    registerFallbackValue(params);
  });

  test('returns Right(id) on success', () async {
    when(() => mockRepo.createGeneration(any()))
        .thenAnswer((_) async => const Right('new-track-id'));

    final result = await usecase(params);
    expect(result, const Right('new-track-id'));
  });

  test('returns Left(GenerationFailure) on failure', () async {
    when(() => mockRepo.createGeneration(any()))
        .thenAnswer((_) async => const Left(GenerationFailure(message: 'error')));

    final result = await usecase(params);
    expect(result.isLeft(), true);
  });
}
