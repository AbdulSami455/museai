import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';

class GetUserGenerationsUsecase {
  final GenerationRepository _repository;
  GetUserGenerationsUsecase(this._repository);

  Future<Either<Failure, List<GenerationEntity>>> call(String uid) {
    return _repository.getUserGenerations(uid);
  }
}
