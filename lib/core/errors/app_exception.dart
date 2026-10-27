sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class AppAuthException extends AppException {
  const AppAuthException(super.message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}

class DuplicateException extends AppException {
  final String? attendanceId;
  final DateTime? originalScanTime;
  const DuplicateException({
    String message = 'Already marked',
    this.attendanceId,
    this.originalScanTime,
  }) : super(message);
}

class SessionClosedException extends AppException {
  const SessionClosedException([super.message = 'Session is not open']);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
