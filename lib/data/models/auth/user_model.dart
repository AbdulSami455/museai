// ignore_for_file: overridden_fields

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

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['id'] as String?,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
    );
  }
}
