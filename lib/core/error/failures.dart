import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();
  String get message;
  @override
  List<Object?> get props => [];
}

enum AuthErrorCode {
  invalidEmail,
  invalidCredential,
  weakPassword,
  emailAlreadyInUse,
  unknown,
}

class AuthFailure extends Failure {
  final AuthErrorCode code;
  @override
  final String message;
  const AuthFailure({required this.code, required this.message});
  @override
  List<Object?> get props => [code, message];
}

class SongFailure extends Failure {
  @override
  final String message;
  const SongFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  @override
  final String message;
  const NetworkFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

class GenerationFailure extends Failure {
  @override
  final String message;
  const GenerationFailure({required this.message});
  @override
  List<Object?> get props => [message];
}
