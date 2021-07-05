import 'dart:async';

import 'package:engine_auth/models/auth_user.dart';
import 'package:engine_auth/services/auth_provider.dart';
import 'package:engine_auth/services/auth_service.dart';
import 'package:engine_db_utils/models/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';





// class AuthControllerAnonymous extends AuthController {
//   AuthControllerAnonymous(reader) : super(reader, activateAnonymousUsers: true);
// }


class AuthController extends StateNotifier<AuthUser?> {

  final Reader read;
  final bool activateAnonymousUsers;

  StreamSubscription<User?>? _authStateChangesSubscription;

  AuthController(this.read, {this.activateAnonymousUsers = false})
      : super(null) {
    _authStateChangesSubscription?.cancel();
    _authStateChangesSubscription = read(authRepoProvider)
        .authStateChanges()
        .listen((u) => state = read(authServiceProvider).toAuthUser(u));
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }

  Stream<AuthUser?> get authStateChanges => read(authServiceProvider).user;

  Future<Result<AuthUser?>> get currentAuthUser async{
    return await read(authServiceProvider).currentAuthUser;
  }

  Future<Result<void>> signOut() async {
    return await read(authServiceProvider).signOut();
  }

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return await read(authServiceProvider).sendPasswordResetEmail(email);
  }

  Future<Result<AuthUser>> signInAnonymously() async {
    return await read(authServiceProvider).signInAnonymously();
  }

  void onAppStart() async {
    final result = await read(authServiceProvider).currentAuthUser;

    if (activateAnonymousUsers && result.obj == null)
      await read(authServiceProvider).signInAnonymously();
  }

  Future<Result<AuthUser>> signInWithGoogle() async {
    return await read(authServiceProvider).signInWithGoogle();
  }

  Future<Result<AuthUser>> convertUserWithEmail(
      {required final String email, required final String password}) async {
    return await read(authServiceProvider)
        .convertUserWithEmail(email: email, password: password);
  }

  Future<Result<AuthUser>> signInWithEmailAndPassword(
      {required final String email, required final String password}) async {
    return await read(authServiceProvider)
        .signInWithEmailAndPassword(email: email, password: password);
  }
}


