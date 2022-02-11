import 'package:engine_auth/models/auth_user.dart';
import 'package:engine_auth/services/auth_provider.dart';
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

  Future<AuthUser?> get currentAuthUser;

  AuthUser? toAuthUser(User? u);

  Future<AuthUser> registerWithEmailAndPassword(
      {required String email, required String password});

  Future<AuthUser> signInWithEmailAndPassword(
      {required final String email, required final String password});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<AuthUser> signInAnonymously();

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> convertUserWithEmail(
      {required final String email, required final String password});
}

class AuthServiceImpl implements AuthService {
  final Reader _reader;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthServiceImpl(this._reader);

  AuthUser _mapUser(User? user) => AuthUser(id: user?.uid, email: user?.email);

  @override
  Future<AuthUser> registerWithEmailAndPassword({
    required final String email,
    required final String password,
  }) async {
    assert(StringUtils.instance.isNotBlank(email));
    assert(StringUtils.instance.isNotBlank(password));

    UserCredential credentialResult = await _reader(authRepoProvider)
        .createUserWithEmailAndPassword(email: email, password: password);

    if (credentialResult.user == null) throw ArgumentError(errNull);

    return _mapUser(credentialResult.user!);
  }

  @override
  Future<AuthUser> convertUserWithEmail(
      {required final String email, required final String password}) async {
    if (_reader(authRepoProvider).currentUser == null)
      throw ArgumentError('The auth.currentUser is null');

    final User currentUser = _reader(authRepoProvider).currentUser!;
    final AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: password);

    User? user = (await currentUser.linkWithCredential(credential)).user;
    if (user == null)
      throw ArgumentError('A null user was received after attempting'
          ' to link a uid to an email & a password.');

    return _mapUser(user);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account == null)
      throw ArgumentError('Signing with Google account has resulted'
          ' in a null value.');

    final GoogleSignInAuthentication googleAuth = await account.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

    User? user =
        (await _reader(authRepoProvider).signInWithCredential(credential)).user;
    if (user == null)
      throw ArgumentError('A null user was received after attempting'
          ' to link a uid to an email & a password.');

    return _mapUser(user);
  }

  @override
  Future<void> signOut() async {
    await _reader(authRepoProvider).signOut();
  }

  @override
  Stream<AuthUser?> get user {
    return _reader(authRepoProvider).authStateChanges().map(_mapUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _reader(authRepoProvider).sendPasswordResetEmail(email: email);
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    UserCredential signInResult =
        await _reader(authRepoProvider).signInAnonymously();

    if (signInResult.user == null)
      throw ArgumentError('signInAnonymously() received null user');

    return AuthUser(
        id: signInResult.user!.uid, email: signInResult.user!.email);
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword(
      {required final String email, required final String password}) async {
    assert(StringUtils.instance.isNotBlank(email));
    assert(StringUtils.instance.isNotBlank(password));

    UserCredential credentialResult = await _reader(authRepoProvider)
        .signInWithEmailAndPassword(email: email, password: password);

    if (credentialResult.user == null)
      throw ArgumentError('signInWithEmailAndPassword got a null user');

    return AuthUser(
        id: credentialResult.user!.uid, email: credentialResult.user!.email);
  }

  @override
  Future<AuthUser> get currentAuthUser async {
    final fbUser = _reader(authRepoProvider).currentUser;
    return _mapUser(fbUser);
  }

  @override
  AuthUser toAuthUser(User? u) {
    return _mapUser(u);
  }
}
