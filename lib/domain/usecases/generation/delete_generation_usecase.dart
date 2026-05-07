import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';

class DeleteGenerationUsecase {
  final GenerationRepository _repository;

  DeleteGenerationUsecase(this._repository);

  Future<Either<Failure, void>> call(String generationId) {
    return _repository.deleteGeneration(generationId);
  }
}
