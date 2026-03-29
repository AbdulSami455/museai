import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:museai/core/configs/const/firebase_const.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/models/auth/user_model.dart';
import 'package:museai/data/source/auth/auth_firebase_service.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';

class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<Either<Failure, void>> signIn(UserEntity user) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user.email!, password: user.password!);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapSignInError(e));
    }
  }

  @override
  Future<Either<Failure, void>> signup(UserEntity user) async {
    try {
      final data = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email!,
        password: user.password!,
      );
      final userData = UserModel(email: user.email, fullName: user.fullName).toJson();
      await FirebaseFirestore.instance
          .collection(FirebaseConst.users)
          .doc(data.user?.uid)
          .set(userData);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapSignUpError(e));
    }
  }

  AuthFailure _mapSignInError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthFailure(
            code: AuthErrorCode.invalidEmail,
            message: 'The email address is badly formatted');
      case 'invalid-credential':
        return const AuthFailure(
            code: AuthErrorCode.invalidCredential,
            message: 'Wrong password provided');
      default:
        return AuthFailure(
            code: AuthErrorCode.unknown,
            message: e.message ?? 'Unknown error');
    }
  }

  AuthFailure _mapSignUpError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return const AuthFailure(
            code: AuthErrorCode.weakPassword,
            message: 'The password provided is too weak');
      case 'email-already-in-use':
        return const AuthFailure(
            code: AuthErrorCode.emailAlreadyInUse,
            message: 'An account already exists with that email');
      default:
        return AuthFailure(
            code: AuthErrorCode.unknown,
            message: e.message ?? 'Unknown error');
    }
  }
}
