/// Low-level exceptions thrown inside the data layer.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred']);
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Local database error']);
}

final class ConflictException extends AppException {
  const ConflictException(this.noteId, [super.message = 'Sync conflict detected']);

  final String noteId;
}

final class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out']);
}

final class UnexpectedException extends AppException {
  const UnexpectedException([super.message = 'Unexpected error occurred']);
}
