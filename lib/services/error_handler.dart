import 'package:engine_auth/models/auth_error_keys.dart';
import 'package:engine_auth/models/auth_status.dart';
import 'package:engine_auth/models/auth_user.dart';
import 'package:engine_db_utils/models/log.dart';
import 'package:engine_db_utils/models/result.dart';



class ErrorHandler{
  Result<AuthUser> handleError({Result<AuthUser> result, error}){

    if(result == null)
      result = Result.failure();

    if(error == null)
      return result;

    if(result.log == null)
      result.log = Log();

    String errorMessage;
    String code;


    switch (error.code) {
      case "ERROR_NETWORK_ERROR":
        code = AuthErrorKeys.auth_network_error;
        errorMessage = "Your email address appears to be malformed.";
        break;
      case "ERROR_INVALID_EMAIL":
        code = AuthErrorKeys.auth_invalid_email;
        errorMessage = "Your email address appears to be malformed.";
        break;
      case "ERROR_WRONG_PASSWORD":
        code = AuthErrorKeys.auth_wrong_password;
        errorMessage = "Your password is wrong.";
        break;
      case "ERROR_USER_NOT_FOUND":
        code = AuthErrorKeys.auth_user_not_found;
        errorMessage = "User with this email doesn't exist.";
        break;
      case "ERROR_USER_DISABLED":
        code = AuthErrorKeys.auth_user_disabled;
        errorMessage = "User with this email has been disabled.";
        break;
      case "ERROR_TOO_MANY_REQUESTS":
        code = AuthErrorKeys.auth_too_many_requests;
        errorMessage = "Too many requests. Try again later.";
        break;
      case "ERROR_OPERATION_NOT_ALLOWED":
        code = AuthErrorKeys.auth_operation_not_allowed;
        errorMessage = "Signing in with Email and Password is not enabled.";
        break;
      case "ERROR_USER_TOKEN_EXPIRED":
        code = AuthErrorKeys.auth_user_token_expired;
        errorMessage = "Signing in with Email and Password is not enabled."; // TODO
        break;
      default:
        code = AuthErrorKeys.auth_undefined;
        errorMessage = "An undefined Error happened.";
    }

    result.log.errorCodes = [code];
    result.log.translationKey = code;
    result.log.msg = errorMessage;
    return result;
  }
}


