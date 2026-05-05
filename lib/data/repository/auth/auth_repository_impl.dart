import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/auth/auth_service.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';
import 'package:museai/domain/repository/auth/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthService _service;
  AuthRepositoryImpl(this._service);

  @override
  Future<Either<Failure, void>> signIn(UserEntity user) async {
    return await _service.signIn(user);
  }

  @override
  Future<Either<Failure, void>> signUp(UserEntity user) async {
    return await _service.signup(user);
  }
}
