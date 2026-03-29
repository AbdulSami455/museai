import 'package:dartz/dartz.dart';
import 'package:museai/core/usecase/usecase.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';
import 'package:museai/domain/repository/auth/auth_repository.dart';
import 'package:museai/service_locator.dart';

class SignUpUsecase implements Usecase<Either, UserEntity> {
  @override
  Future<Either> call({UserEntity? params}) {
    return sl<AuthRepository>().signUp(params!);
  }
}
