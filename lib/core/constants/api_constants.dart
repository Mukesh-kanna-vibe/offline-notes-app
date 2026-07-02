/// Remote API configuration for MockAPI.io.
abstract final class ApiConstants {
  /// MockAPI project: Offline Notes API
  static const String baseUrl =
      'https://6a44fae7aab3faec3f6927cf.mockapi.io';

  static const String notesEndpoint = '/notes';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  static const int maxRetryAttempts = 3;

  /// Queue payload flag — user chose Keep Local / Merge; skip conflict checks.
  static const String forceOverwritePayloadKey = 'forceOverwrite';
}
