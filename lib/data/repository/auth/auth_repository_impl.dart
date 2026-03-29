import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/auth/auth_firebase_service.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';
import 'package:museai/domain/repository/auth/auth_repository.dart';
import 'package:museai/service_locator.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<Either<Failure, void>> signIn(UserEntity user) async {
    return await sl<AuthFirebaseService>().signIn(user);
  }

  @override
  Future<Either<Failure, void>> signUp(UserEntity user) async {
    return await sl<AuthFirebaseService>().signup(user);
  }
}
