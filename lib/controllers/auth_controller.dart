import 'dart:async';

import 'package:engine_auth/models/auth_user.dart';
import 'package:engine_auth/services/auth_provider.dart';
import 'package:engine_auth/services/auth_service.dart';
import 'package:engine_db_utils/models/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

//
// final authController = StateNotifierProvider.family<StateNotifier<AuthUser?>, AuthController, bool>(
//     (ref, bool activateAnonymousUsers) => AuthController(ref.read,
//         activateAnonymousUsers: activateAnonymousUsers));
//

class AuthControllerAnonymous extends AuthController {
  AuthControllerAnonymous(reader) : super(reader, activateAnonymousUsers: true);
}

class AuthController extends StateNotifier<AuthUser?> {
  final Reader _reader;
  final bool activateAnonymousUsers;

  StreamSubscription<User?>? _streamSubscription;

  AuthController(this._reader, {this.activateAnonymousUsers = false})
      : super(null) {
    _streamSubscription?.cancel();
    _streamSubscription = _reader(authRepoProvider)
        .authStateChanges()
        .listen((u) => state = _reader(authServiceProvider).mapFbUser(u));
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<Result<AuthUser?>> get currentAuthUser async{
    return await _reader(authServiceProvider).currentAuthUser;
  }

  void appStarted() async {
    final result = await _reader(authServiceProvider).currentAuthUser;

    if (activateAnonymousUsers && result.obj == null)
      await _reader(authServiceProvider).signInAnonymously();
  }

  Future<Result<void>> signOut() async {
    return await _reader(authServiceProvider).signOut();
  }

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return await _reader(authServiceProvider).sendPasswordResetEmail(email);
  }

  Future<Result<AuthUser>> signInAnonymously() async {
    return await _reader(authServiceProvider).signInAnonymously();
  }

  Future<Result<AuthUser>> signInWithGoogle() async {
    return await _reader(authServiceProvider).signInWithGoogle();
  }

  Future<Result<AuthUser>> convertUserWithEmail(
      {required final String email, required final String password}) async {
    return await _reader(authServiceProvider)
        .convertUserWithEmail(email: email, password: password);
  }

  Future<Result<AuthUser>> signInWithEmailAndPassword(
      {required final String email, required final String password}) async {
    return await _reader(authServiceProvider)
        .signInWithEmailAndPassword(email: email, password: password);
  }
}
