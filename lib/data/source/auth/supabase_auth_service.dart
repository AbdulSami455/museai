// This service handles external or data operations for authentication.

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/auth/auth_service.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';

class SupabaseAuthService implements AuthService {
  final SupabaseClient _client;

  SupabaseAuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Either<Failure, void>> signIn(UserEntity user) async {
    try {
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: user.password!,
      );
      await _bootstrapProfile(fullName: user.fullName);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthError(e));
    } catch (e) {
      return Left(AuthFailure(
        code: AuthErrorCode.unknown,
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> signup(UserEntity user) async {
    try {
      final response = await _client.auth.signUp(
        email: user.email!,
        password: user.password!,
        data: {'full_name': user.fullName},
      );
      if (response.session != null) {
        await _bootstrapProfile(fullName: user.fullName);
      }
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapSignUpError(e));
    } catch (e) {
      return Left(AuthFailure(
        code: AuthErrorCode.unknown,
        message: e.toString(),
      ));
    }
  }

  AuthFailure _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('email not confirmed') || msg.contains('confirm')) {
      return const AuthFailure(
        code: AuthErrorCode.unknown,
        message: 'Please verify your email before signing in.',
      );
    }
    if (msg.contains('invalid') ||
        msg.contains('credentials') ||
        msg.contains('password')) {
      return const AuthFailure(
        code: AuthErrorCode.invalidCredential,
        message: 'Invalid email or password',
      );
    }
    if (msg.contains('email')) {
      return const AuthFailure(
        code: AuthErrorCode.invalidEmail,
        message: 'The email address is badly formatted',
      );
    }
    return AuthFailure(code: AuthErrorCode.unknown, message: e.message);
  }

  AuthFailure _mapSignUpError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already exists') ||
        msg.contains('duplicate')) {
      return const AuthFailure(
        code: AuthErrorCode.emailAlreadyInUse,
        message: 'An account already exists with that email',
      );
    }
    if (msg.contains('password') && msg.contains('weak') ||
        msg.contains('characters')) {
      return const AuthFailure(
        code: AuthErrorCode.weakPassword,
        message: 'The password provided is too weak',
      );
    }
    return AuthFailure(code: AuthErrorCode.unknown, message: e.message);
  }

  Future<void> _bootstrapProfile({String? fullName}) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return;

    final payload = <String, dynamic>{
      'id': authUser.id,
      'email': authUser.email,
      'full_name': fullName ??
          authUser.userMetadata?['full_name'] ??
          authUser.userMetadata?['name'],
      'photo_url': authUser.userMetadata?['avatar_url'],
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }..removeWhere((_, value) => value == null);

    try {
      await _client.from('users').upsert(payload, onConflict: 'id');
    } catch (_) {
      // Auth should still succeed even if the app schema has not been applied yet.
    }
  }
}
