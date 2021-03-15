import 'package:engine_auth/models/auth_user.dart';
import 'package:engine_auth/services/error_handler.dart';
import 'package:engine_db_utils/models/log.dart';
import 'package:engine_db_utils/models/result.dart';
import 'package:engine_utils/utils/string_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String errNull = "Got a null auth user from backend";

abstract class AuthService{

  Future<Result<AuthUser>> registerWithEmailAndPassword({
    required String email, required String password});

  Stream<AuthUser> get user;

  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required final String email,
    required final String password});
  Future<Result<void>> signOut();
  Future<Result<void>> sendPasswordResetEmail(String email);
  Future<Result<AuthUser>> signInAnonymously();
  Future<Result<AuthUser>> signInWithGoogle();
  Future<Result<AuthUser>> convertUserWithEmail({required final String email,
    required final String password});
  FirebaseAuth getFbAuth();
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();


  AuthServiceImpl({required this.auth});

  FirebaseAuth getFbAuth() => auth;

  AuthUser _mapUser(User? user) {
    return AuthUser(
      id: user?.uid ,
        email: user?.email
    );
  }


  @override
  Future<Result<AuthUser>> registerWithEmailAndPassword({
    required final String email,
    required final String password }) async {
    try{

      assert(StringUtils.instance.isNotBlank(email));
      assert(StringUtils.instance.isNotBlank(password));

      UserCredential credentialResult = await auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password
          );

      if(credentialResult.user == null)
        return Result.failure(msg: errNull);

      AuthUser user = _mapUser(credentialResult.user!);

      return Result.success(obj: user);

    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
        result: Result.failure(
          log: Log(

            stacktrace: stacktrace,
          )
        ),
        error: e
      );
    }
  }

  @override
  Future<Result<AuthUser>> convertUserWithEmail({required final String email,
    required final String password}) async{
    try{

      if(auth.currentUser == null)
        return Result.failure(msg: 'The auth.currentUser is null');

      final User currentUser = auth.currentUser!;
      final AuthCredential credential = EmailAuthProvider
          .credential(email: email, password: password);

      User? user = (await currentUser.linkWithCredential(credential)).user;
      if(user == null)
        return Result.failure(msg: 'A null user was received after attempting'
            ' to link a uid to an email & a password.');

      return Result.success(obj: _mapUser(user));
    }
    catch(e, stacktrace){
      return ErrorHandler().handleError(
          result: Result.failure(
              log: Log(
                  stacktrace: stacktrace
              )
          ),
          error: e
      );
    }
  }

  @override
  Future<Result<AuthUser>> signInWithGoogle() async{
    try{
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if(account == null)
        return Result.failure(msg: 'Signing with Google account has resulted'
            ' in a null value.');

      final GoogleSignInAuthentication googleAuth = await account.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken
      );

      User? user = (await auth.signInWithCredential(credential)).user;
      if(user == null)
        return Result.failure(msg: 'A null user was received after attempting'
            ' to link a uid to an email & a password.');

      return Result.success(obj: _mapUser(user));
    }
    catch(e, stacktrace){
      return ErrorHandler().handleError(
          result: Result.failure(
              log: Log(
                  stacktrace: stacktrace
              )
          ),
          error: e
      );
    }
  }







  @override
  Future<Result> signOut() async {
    try{
      auth.signOut();
      return Result.success();
    } catch (e, stacktrace){
      return ErrorHandler().handleError(
        result: Result.failure(
          log: Log(
            stacktrace: stacktrace
          )
        ),
        error: e
      );
    }
  }


  @override
  Stream<AuthUser> get user {
    return auth.authStateChanges().map(_mapUser);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try{
      await auth.sendPasswordResetEmail(email: email);
      return Result.success();
    } catch (e, stacktrace){
      return ErrorHandler().handleError(
        result: Result.failure(
          msg: e.toString(),
          stacktrace: stacktrace
        ),
        error: e);
    }
  }

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    try {
      UserCredential signInResult = await auth.signInAnonymously();

      if(signInResult.user == null)
        return Result.failure();

      AuthUser user = AuthUser(
        id: signInResult.user!.uid, email: signInResult.user!.email
      );

      return Result.success(obj: user);

    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(
              log: Log(
                  stacktrace: stacktrace
              )
          ),
          error: e
      );
    }
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required final String email,
    required final String password
  })
  async {
    try {
      assert(StringUtils.instance.isNotBlank(email));
      assert(StringUtils.instance.isNotBlank(password));


      UserCredential credentialResult = await auth
          .signInWithEmailAndPassword(email: email, password: password);

      if(credentialResult.user == null)
        return Result.failure();

      AuthUser user = AuthUser(
          id: credentialResult.user!.uid,
          email: credentialResult.user!.email
      );

      return Result.success(obj: user);

    } catch (e, stacktrace) {
      return ErrorHandler().handleError(
          result: Result.failure(
              log: Log(
                  stacktrace: stacktrace
              )
          ),
          error: e
      );
    }
  }
}
