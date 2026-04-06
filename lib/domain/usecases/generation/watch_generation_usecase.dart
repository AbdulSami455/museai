import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';

class WatchGenerationParams {
  final String uid;
  final String generationId;
  const WatchGenerationParams({required this.uid, required this.generationId});
}

class WatchGenerationUsecase {
  final GenerationRepository _repository;
  WatchGenerationUsecase(this._repository);

  Stream<Either<Failure, GenerationEntity>> call(WatchGenerationParams params) {
    return _repository.watchGeneration(params.uid, params.generationId);
  }
}
