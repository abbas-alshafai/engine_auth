import 'package:firebase_auth/firebase_auth.dart';

class AuthUser{

  String id;
  String email;

  AuthUser.fromFirestore(User user){
    this.id = user.uid;
    this.email = user.email;
  }

}
