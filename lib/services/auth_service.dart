import 'package:engine_auth/models/auth_user.dart';
//import 'package:engine_db_utils/models/log.dart';
import 'package:engine_db_utils/models/result.dart';
//import 'package:engine_db_utils/services/log_service.dart';
import 'package:engine_utils/utils/string_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const String errNull = "Got a null auth user from backend";

abstract class AuthService{

  Future<Result<AuthUser>> registerWithEmailAndPassword({
    @required String email, @required String password});

  Stream<AuthUser> get user;
  Future<AuthUser> getCurrentUser();

  Future<Result<AuthUser>> signInWithEmailAndPassword({final String email,
    final String password});
  Future<Result<void>> signOut();
}



class AuthServiceFactory{

  AuthServiceFactory._();
  static final AuthServiceFactory instance = AuthServiceFactory._();

  AuthService getService(){
    return AuthServiceImpl(auth: FirebaseAuth.instance);
  }
}




class AuthServiceImpl implements AuthService{

  final FirebaseAuth auth;
//  final LogService logger = LoggerFactory.instance.getLogger();


  AuthServiceImpl({@required this.auth});


  AuthUser _mapUser(FirebaseUser user) {
    return user != null
        ? AuthUser.fromFirestore(user)
        : null ;
  }


  @override
  Future<Result<AuthUser>> registerWithEmailAndPassword({
    @required final String email,
    @required final String password }) async {
    try{

      assert(StringUtils.instance.isNotBlank(email));
      assert(StringUtils.instance.isNotBlank(password));

      AuthResult authResult = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );


      if(authResult == null)
        return Result.failure(msg: errNull);

      AuthUser user = _mapUser(authResult.user);

      return user == null
          ? Result.failure(msg: errNull)
          : Result.success(obj: user);


    } catch (e, stacktrace){
      return Result.failure(
        msg: e.toString(),
        stacktrace: stacktrace.toString(),
      );
    }
  }



  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({@required final String email,
    @required final String password})
  async {
    try {
      assert(StringUtils.instance.isNotBlank(email));
      assert(StringUtils.instance.isNotBlank(password));

      AuthResult authResult = await auth
          .signInWithEmailAndPassword(email: email, password: password);

      if(authResult == null || authResult.user == null)
        return Result.failure();

      AuthUser user = AuthUser.fromFirestore(authResult.user);

      return user != null
          ? Result.success(obj: user)
          : Result.failure();

    } catch (e, stacktrace) {
      return Result.failure(
        msg: e.toString(),
        stacktrace: stacktrace.toString()
      );
    }
  }


  @override
  Future<Result> signOut() async {
    try{
      auth.signOut();
      return Result.success();
    } catch (e, stacktrace){
      return Result.failure(
        msg: e.toString(),
        stacktrace: stacktrace.toString(),
      );
    }
  }

  @override
  Future<AuthUser> getCurrentUser() {
    // TODO: implement getCurrentUser
    return null;
  }

  @override
  Stream<AuthUser> get user {
    return auth.onAuthStateChanged.map(_mapUser);
  }

}
