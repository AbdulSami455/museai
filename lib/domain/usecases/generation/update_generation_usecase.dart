// This use case handles one focused action in music generation.

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';

class UpdateGenerationUsecase {
  final GenerationRepository _repository;

  UpdateGenerationUsecase(this._repository);

  Future<Either<Failure, GenerationEntity>> call(
    String generationId, {
    String? title,
    String? prompt,
    bool? isPublic,
  }) {
    return _repository.updateGeneration(
      generationId,
      title: title,
      prompt: prompt,
      isPublic: isPublic,
    );
  }
}
