// This use case handles one focused action in authentication.

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/core/usecase/usecase.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';
import 'package:museai/domain/repository/auth/auth_repository.dart';

class SignUpUsecase implements Usecase<Either<Failure, void>, UserEntity> {
  final AuthRepository _repository;
  SignUpUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call({UserEntity? params}) {
    return _repository.signUp(params!);
  }
}
