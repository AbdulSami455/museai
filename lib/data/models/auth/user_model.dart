// ignore_for_file: overridden_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';

class UserModel extends UserEntity {
  @override
  final String? uid;
  @override
  final String? fullName;
  @override
  final String? email;

  const UserModel({this.uid, this.fullName, this.email})
      : super(email: email, uid: uid, fullName: fullName);

  Map<String,dynamic> toJson(){
    return {
      'fullName':fullName,
      'email':email
    };
  }

  factory UserModel.fromSnapshot(DocumentSnapshot snap){
    var snapshot = snap.data() as Map<String, dynamic>;
    return UserModel(
      uid: snapshot['uid'],
      fullName: snapshot['fullName'],
      email: snapshot['email']
    );
  }
}
