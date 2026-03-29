import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:museai/core/configs/const/firebase_const.dart';
import 'package:museai/data/models/auth/user_model.dart';
import 'package:museai/data/source/auth/auth_firebase_service.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';

class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<Either> signIn(UserEntity user) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user.email!, password: user.password!);

      return const Right('Signin was Successful');
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'invalid-email') {
        message = 'Not user found for that email';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user';
      }

      return Left(message);
    }
  }

  @override
  Future<Either> signup(UserEntity user) async {
    try {
      var firestore = FirebaseFirestore.instance;
      var data = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email!,
        password: user.password!,
      );
      var userData =
          UserModel(email: user.email, fullName: user.fullName).toJson();
      await firestore
          .collection(FirebaseConst.users)
          .doc(data.user?.uid)
          .set(userData);

      return const Right('Signup was Successful');
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }
      return Left(message);
    }
  }
}
