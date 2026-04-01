// lib/core/error/app_exceptions.dart

sealed class AppException implements Exception {
  /// Internal message for logging (may contain sensitive details).
  final String message;

  /// User-facing message (safe to display in UI).
  final String userMessage;

  const AppException(this.message, {String? userMessage})
      : userMessage = userMessage ?? 'An unexpected error occurred.';

  @override
  String toString() => message;
}

class ServerUnreachableException extends AppException {
  const ServerUnreachableException(super.message)
      : super(userMessage: 'Could not reach the server. Check the URL and your connection.');
}

class InvalidServerException extends AppException {
  const InvalidServerException(super.message)
      : super(userMessage: 'This does not appear to be a valid Emby server.');
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {String? userMessage})
      : super(
            userMessage:
                userMessage ?? 'Invalid username or password.');
}

class SessionExpiredException extends AppException {
  const SessionExpiredException(super.message)
      : super(userMessage: 'Your session has expired. Please sign in again.');
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.userMessage})
      : super();
}
