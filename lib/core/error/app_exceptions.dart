// lib/core/error/app_exceptions.dart

sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class ServerUnreachableException extends AppException {
  const ServerUnreachableException(super.message);
}

class InvalidServerException extends AppException {
  const InvalidServerException(super.message);
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message);
}

class SessionExpiredException extends AppException {
  const SessionExpiredException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}
