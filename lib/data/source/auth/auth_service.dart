import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';

abstract class AuthService {
  Future<Either<Failure, void>> signIn(UserEntity user);
  Future<Either<Failure, void>> signup(UserEntity user);
}
