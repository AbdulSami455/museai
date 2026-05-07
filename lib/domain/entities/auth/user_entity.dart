// This entity represents core business data for authentication.

import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String? uid;
  final String? fullName;
  final String? email;
  //Not in database
  final String? password;

  const UserEntity({this.uid, this.fullName, this.email, this.password});

  @override
  List<Object?> get props => [uid, fullName, email];
}
