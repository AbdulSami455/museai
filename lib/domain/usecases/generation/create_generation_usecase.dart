import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

class CreateGenerationUsecase {
  final GenerationRepository _repository;
  CreateGenerationUsecase(this._repository);

  Future<Either<Failure, String>> call(GenerationParams params) {
    return _repository.createGeneration(params);
  }
}
