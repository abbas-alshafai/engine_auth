import 'package:firebase_auth/firebase_auth.dart';

class AuthUser{

  String uid;
  String email;

  AuthUser.fromFirestore(FirebaseUser user){
    this.uid = user.uid;
    this.email = user.email;
  }

}
