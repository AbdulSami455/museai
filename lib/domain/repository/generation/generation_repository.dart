import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

abstract class GenerationRepository {
  Future<Either<Failure, String>> createGeneration(GenerationParams params);
  Stream<Either<Failure, GenerationEntity>> watchGeneration(
      String uid, String generationId);
  Future<Either<Failure, List<GenerationEntity>>> getUserGenerations(
      String uid);
  Future<Either<Failure, GenerationEntity>> updateGeneration(
    String generationId, {
    String? title,
    String? prompt,
    bool? isPublic,
  });
  Future<Either<Failure, void>> deleteGeneration(String generationId);
}
