/// Base exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  ServerException(super.message, [super.statusCode]);
}

/// Cache exception
class CacheException extends AppException {
  CacheException(super.message, [super.statusCode]);
}

/// Network exception
class NetworkException extends AppException {
  NetworkException(super.message, [super.statusCode]);
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException(super.message, [super.statusCode]);
}

/// Unauthorized exception
class UnauthorizedException extends AppException {
  UnauthorizedException(super.message, [super.statusCode]);
}

/// Not found exception
class NotFoundException extends AppException {
  NotFoundException(super.message, [super.statusCode]);
}
