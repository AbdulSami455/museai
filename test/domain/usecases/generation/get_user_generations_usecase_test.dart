import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';
import 'package:museai/domain/usecases/generation/get_user_generations_usecase.dart';

class MockGenerationRepository extends Mock implements GenerationRepository {}

void main() {
  late GetUserGenerationsUsecase usecase;
  late MockGenerationRepository mockRepo;

  setUp(() {
    mockRepo = MockGenerationRepository();
    usecase = GetUserGenerationsUsecase(mockRepo);
  });

  test('returns Right(list) on success', () async {
    when(() => mockRepo.getUserGenerations(any()))
        .thenAnswer((_) async => const Right([]));

    final result = await usecase('uid1');
    expect(result.isRight(), true);
  });

  test('returns Left(GenerationFailure) on failure', () async {
    when(() => mockRepo.getUserGenerations(any()))
        .thenAnswer((_) async => const Left(GenerationFailure(message: 'error')));

    final result = await usecase('uid1');
    expect(result.isLeft(), true);
  });

  test('handles empty list', () async {
    when(() => mockRepo.getUserGenerations(any()))
        .thenAnswer((_) async => const Right(<GenerationEntity>[]));

    final result = await usecase('uid1');
    result.fold(
      (f) => fail('expected Right'),
      (list) => expect(list, isEmpty),
    );
  });
}
