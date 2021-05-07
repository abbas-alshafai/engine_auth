import 'package:engine_auth/models/auth_user.dart';
import 'package:engine_auth/services/auth_provider.dart';
import 'package:engine_auth/services/error_handler.dart';
import 'package:engine_db_utils/models/log.dart';
import 'package:engine_db_utils/models/result.dart';
import 'package:engine_utils/utils/string_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// TODO move to auth error keys
const String errNull = "Got a null auth user from backend";


final authServiceProvider =
    Provider<AuthService>((ref) => AuthServiceImpl(ref.read));


abstract class AuthService {
  Stream<AuthUser?> get user;

  Future<Result<AuthUser?>> get currentUser;

  AuthUser? mapFbUser(User? u);

  Future<Result<AuthUser>> registerWithEmailAndPassword(
      {required String email, required String password});

  Future<Result<AuthUser>> signInWithEmailAndPassword(
      {required final String email, required final String password});

  Future<Result<void>> signOut();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<AuthUser>> signInAnonymously();

  Future<Result<AuthUser>> signInWithGoogle();

  Future<Result<AuthUser>> convertUserWithEmail(
      {required final String email, required final String password});
// FirebaseAuth getFbAuth();
}

/// TODO: deprecated as we are using [authServiceProvider]
/*
class AuthServiceFactory {
  AuthServiceFactory._();

  static final AuthServiceFactory instance = AuthServiceFactory._();

  AuthService getService() {
    return AuthServiceImpl(authRepoProvider);
  }
}
 */

class AuthServiceImpl implements AuthService {
  final Reader _reader;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthServiceImpl(this._reader);

  // FirebaseAuth getFbAuth() => auth;

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;

    return AuthUser(id: user.uid, email: user.email);
  }

  @override
  Future<Result<AuthUser>> registerWithEmailAndPassword(
      {required final String email, required final String password}) async {
    try {
      assert(StringUtils.instance.isNotBlank(email));
      assert(StringUtils.instance.isNotBlank(password));

      UserCredential credentialResult = await _reader(authRepoProvider)
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credentialResult.user == null) return Result.failure(msg: errNull);

      AuthUser? user = _mapUser(credentialResult.user!);

      return Result.success(obj: user);
    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(
              log: Log(
            stacktrace: stacktrace,
          )),
          error: e);
    }
  }

  @override
  Future<Result<AuthUser>> convertUserWithEmail(
      {required final String email, required final String password}) async {
    try {
      if (_reader(authRepoProvider).currentUser == null)
        return Result.failure(msg: 'The auth.currentUser is null');

      final User currentUser = _reader(authRepoProvider).currentUser!;
      final AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);

      User? user = (await currentUser.linkWithCredential(credential)).user;
      if (user == null)
        return Result.failure(
            msg: 'A null user was received after attempting'
                ' to link a uid to an email & a password.');

      return Result.success(obj: _mapUser(user));
    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(log: Log(stacktrace: stacktrace)), error: e);
    }
  }

  @override
  Future<Result<AuthUser>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null)
        return Result.failure(
            msg: 'Signing with Google account has resulted'
                ' in a null value.');

      final GoogleSignInAuthentication googleAuth =
          await account.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

      User? user =
          (await _reader(authRepoProvider).signInWithCredential(credential))
              .user;
      if (user == null)
        return Result.failure(
            msg: 'A null user was received after attempting'
                ' to link a uid to an email & a password.');

      return Result.success(obj: _mapUser(user));
    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(log: Log(stacktrace: stacktrace)), error: e);
    }
  }

  @override
  Future<Result> signOut() async {
    try {
      _reader(authRepoProvider).signOut();
      return Result.success();
    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(log: Log(stacktrace: stacktrace)), error: e);
    }
  }

  @override
  Stream<AuthUser?> get user {
    return _reader(authRepoProvider).authStateChanges().map(_mapUser);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _reader(authRepoProvider).sendPasswordResetEmail(email: email);
      return Result.success();
    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(msg: e.toString(), stacktrace: stacktrace),
          error: e);
    }
  }

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    try {
      UserCredential signInResult =
          await _reader(authRepoProvider).signInAnonymously();

      if (signInResult.user == null) return Result.failure();

      AuthUser user =
          AuthUser(id: signInResult.user!.uid, email: signInResult.user!.email);

      return Result.success(obj: user);
    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(log: Log(stacktrace: stacktrace)), error: e);
    }
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword(
      {required final String email, required final String password}) async {
    try {
      assert(StringUtils.instance.isNotBlank(email));
      assert(StringUtils.instance.isNotBlank(password));

      UserCredential credentialResult = await _reader(authRepoProvider)
          .signInWithEmailAndPassword(email: email, password: password);

      if (credentialResult.user == null) return Result.failure();

      AuthUser user = AuthUser(
          id: credentialResult.user!.uid, email: credentialResult.user!.email);

      return Result.success(obj: user);
    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(log: Log(stacktrace: stacktrace)), error: e);
    }
  }

  @override
  Future<Result<AuthUser?>> get currentUser async {
    try {
      final fbUser = _reader(authRepoProvider).currentUser;
      return Result.success(obj: _mapUser(fbUser));
    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(log: Log(stacktrace: stacktrace)), error: e);
    }
  }

  @override
  AuthUser? mapFbUser(User? u) {
    return _mapUser(u);
  }
}
