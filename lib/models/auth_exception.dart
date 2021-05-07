
// TODO currently not used
class AuthException implements Exception {
  final String message;
  final StackTrace stackTrace;

  AuthException({
    this.message = 'An auth error occurred.',
    required this.stackTrace,
  });

  @override
  String toString() {
    return 'AuthException {\nmessage: $message'
        '\nstackTrace: ${stackTrace.toString()}'
        '\n}';
  }
}
